#!/usr/bin/env python3
"""Summarize a pacommander proxy log into a per-connection RPC timeline.

Reconstructs the byte stream pacommander hex-dumped for each direction of
each connection, then pulls out the handful of fields worth checking when
diagnosing a PAServer session: driver/auth info from `connect`, the
server's reported ScratchDir from `VerifyPlatform`, the package name
`FileExistsEx` checked for, whether `PutFile` happened, and any
version-looking strings anywhere in the negotiation.

Usage:
    pacommander_parse.py LOGFILE [--conn N] [--timeline]
"""

import argparse
import json
import re
from dataclasses import dataclass, field

TS = r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})'
CONNECT_RE = re.compile(TS + r' \[INFO\] \[conn-(\d+)\] client connected from (\(.*\))')
CLOSE_RE = re.compile(TS + r' \[INFO\] \[conn-(\d+)\] connection closed')
MSG_RE = re.compile(TS + r' \[INFO\] \[conn-(\d+)\] (client->paserver|paserver->client) (\d+) bytes:')
HEXLINE_RE = re.compile(r'^\s*[0-9a-f]{8}\s+((?:[0-9a-f]{2}\s?)+?)\s{2,}\|')

# How much of a connection's traffic (in wire order) to scan for the
# summary fields below. Every negotiation we've captured so far fits
# comfortably inside this; it exists mainly to keep the regex scan off
# multi-megabyte PutFile payloads.
SCAN_LIMIT = 200_000

VERSION_RE = re.compile(rb'\b\d{1,2}\.\d\.\d{4,6}\.\d{3,4}\b')
SCRATCHDIR_RE = re.compile(rb'(/[^\s"\x00-\x1f]+-scratch/[^\s"\x00-\x1f`]*)')
PASERVER_PKG_RE = re.compile(rb'LinuxPAServer[\d.]+\.tar\.gz')
METHOD_RE = re.compile(rb'"method":"(\w+)"')
SUBMETHOD_RE = re.compile(rb'TServerMethods\.(\w+)')


@dataclass
class Message:
    ts: str
    direction: str
    data: bytes


@dataclass
class Connection:
    conn_id: int
    peer: str = ""
    start_ts: str = ""
    end_ts: str = ""
    messages: list = field(default_factory=list)


def parse_log(path):
    conns = {}
    cur = None
    cur_dir = None
    cur_ts = None
    cur_bytes = bytearray()

    def flush_message():
        nonlocal cur_dir, cur_bytes
        if cur is not None and cur_dir is not None:
            cur.messages.append(Message(cur_ts, cur_dir, bytes(cur_bytes)))
        cur_dir = None
        cur_bytes = bytearray()

    with open(path, errors='replace') as f:
        for line in f:
            m = CONNECT_RE.match(line)
            if m:
                flush_message()
                cid = int(m.group(2))
                cur = conns.setdefault(cid, Connection(cid))
                cur.peer = m.group(3)
                cur.start_ts = m.group(1)
                continue
            m = CLOSE_RE.match(line)
            if m:
                flush_message()
                cid = int(m.group(2))
                c = conns.setdefault(cid, Connection(cid))
                c.end_ts = m.group(1)
                continue
            m = MSG_RE.match(line)
            if m:
                flush_message()
                cid = int(m.group(2))
                cur = conns.setdefault(cid, Connection(cid))
                cur_ts = m.group(1)
                cur_dir = m.group(3)
                continue
            m = HEXLINE_RE.match(line)
            if m and cur_dir is not None:
                cur_bytes.extend(bytes.fromhex(m.group(1).strip().replace(' ', '')))
    flush_message()
    return list(conns.values())


def classify(data: bytes):
    """Return (group_key, display_label) for one message.

    group_key is used to collapse runs of consecutive same-shaped
    messages (e.g. thousands of PutFile transfer chunks); display_label
    is what gets printed.
    """
    methods = METHOD_RE.findall(data)
    submethods = SUBMETHOD_RE.findall(data)
    if methods:
        labels = [m.decode() for m in methods]
        if submethods and len(submethods) == len(labels):
            labels = [
                f"{label}[{sub.decode()}]" if label == 'prepare' else label
                for label, sub in zip(labels, submethods)
            ]
        elif submethods:
            labels = labels + [f"[{s.decode()}]" for s in submethods]
        disp = '+'.join(labels)
        return disp, disp
    if data.startswith(b'{"result"'):
        return 'result', 'result'
    if data.startswith(b'{"callback"'):
        return 'callback', 'callback (auth challenge)'
    if data.startswith(b'{"more_blob"'):
        return 'more_blob', 'more_blob ack'
    return 'binary', 'binary'


def print_timeline(conn):
    run_key = run_dir = None
    run_count = run_bytes = run_printable = 0

    def flush_run():
        if run_count == 0:
            return
        if run_key == 'binary' and run_bytes:
            label = f"binary ({run_printable / run_bytes:.0%} printable)"
        else:
            label = run_key
        suffix = f"  (x{run_count})" if run_count > 1 else ""
        print(f"    {run_dir:<17} {run_bytes:>10}B  {label}{suffix}")

    for msg in conn.messages:
        key, _ = classify(msg.data)
        if key == run_key and msg.direction == run_dir:
            run_count += 1
            run_bytes += len(msg.data)
            if key == 'binary':
                run_printable += sum(32 <= b < 127 for b in msg.data)
        else:
            flush_run()
            run_key, run_dir = key, msg.direction
            run_count, run_bytes = 1, len(msg.data)
            run_printable = sum(32 <= b < 127 for b in msg.data) if key == 'binary' else 0
    flush_run()


def summarize_connection(conn):
    blob = bytearray()
    for msg in conn.messages:
        blob.extend(msg.data)
        if len(blob) >= SCAN_LIMIT:
            break
    blob = bytes(blob)

    info = {}

    for msg in conn.messages:
        if msg.direction == 'client->paserver' and b'"method":"connect"' in msg.data:
            try:
                obj = json.loads(msg.data.decode('utf-8'))
                info['connect'] = obj['params'][0]
            except (ValueError, KeyError, UnicodeDecodeError):
                pass
            break

    m = SCRATCHDIR_RE.search(blob)
    if m:
        info['scratch_dir'] = m.group(1).decode(errors='replace')

    m = PASERVER_PKG_RE.search(blob)
    if m:
        info['expected_package'] = m.group(0).decode()

    info['put_file'] = b'TServerMethods.PutFile' in blob

    versions = sorted(set(v.decode() for v in VERSION_RE.findall(blob)))
    if versions:
        info['version_strings_seen'] = versions

    return info


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('logfile')
    ap.add_argument('--conn', type=int, help='only show this connection id')
    ap.add_argument('--timeline', action='store_true', help='also print the collapsed message timeline')
    args = ap.parse_args()

    conns = parse_log(args.logfile)
    if args.conn is not None:
        conns = [c for c in conns if c.conn_id == args.conn]

    for c in conns:
        print(f"=== conn-{c.conn_id}  {c.peer}  {c.start_ts} - {c.end_ts} ===")
        info = summarize_connection(c)
        if 'connect' in info:
            cp = info['connect']
            print(f"  connect: Driver={cp.get('DriverName')} Host={cp.get('HostName')} "
                  f"Port={cp.get('Port')} User={cp.get('DSAuthenticationUser')!r}")
        if 'scratch_dir' in info:
            print(f"  server ScratchDir: {info['scratch_dir']}")
        if 'expected_package' in info:
            print(f"  client expects package: {info['expected_package']}")
        print(f"  PutFile upload occurred: {info['put_file']}")
        if info.get('version_strings_seen'):
            print(f"  version-looking strings seen on wire: {', '.join(info['version_strings_seen'])}")
        if args.timeline:
            print_timeline(c)
        print()


if __name__ == '__main__':
    main()
