#!/usr/bin/env python3
"""Experimental version-spoofing PAServer proxy.

Proxies a real PAServer like pacommander.py does, but rewrites the
ServerMajorVersion/ServerMinorVersion fields inside VerifyPlatform's
response to make the backend claim to be a different PAServer version,
so an older/newer Delphi IDE's version-mismatch check passes.

The replacement bytes for each target are literal captures from a real
paserver binary of that version (see captures/paserver-version-probe-
results.txt) rather than the derived Major*10+Minor / Build*10+Patch
formula, because that formula is known to be wrong for two-digit Patch
values (see captures/NOTES.md).
"""

import argparse
import asyncio
import itertools
import logging
import re

log = logging.getLogger("pacommander-spoof")
connection_ids = itertools.count(1)

MAX_DUMP_BYTES = 512


def format_hexdump(data: bytes) -> str:
    shown = data[:MAX_DUMP_BYTES]
    lines = []
    for offset in range(0, len(shown), 16):
        row = shown[offset : offset + 16]
        hex_part = " ".join(f"{b:02x}" for b in row)
        ascii_part = "".join(chr(b) if 32 <= b < 127 else "." for b in row)
        lines.append(f"  {offset:08x}  {hex_part:<47}  |{ascii_part}|")
    if len(data) > MAX_DUMP_BYTES:
        lines.append(f"  ... ({len(data) - MAX_DUMP_BYTES} more bytes)")
    return "\n".join(lines)

# version label -> raw ServerMajorVersion+ServerMinorVersion bytes,
# captured directly from a real paserver binary via pacommander_probe.py
TARGET_VERSIONS = {
    "10.2": bytes.fromhex("61666171"),  # LinuxPAServer19.0 -> "10.2.1.13"
    "11.2": bytes.fromhex("6170618a"),  # LinuxPAServer20.0 -> "11.2.13.8"
    "12.2": bytes.fromhex("617a6167"),  # LinuxPAServer21.0 -> "12.2.10.3"
    "13.3": bytes.fromhex("6185617f"),  # LinuxPAServer22.0 -> "13.3.12.7"
    "14.3": bytes.fromhex("618f618e"),  # LinuxPAServer23.0 -> "14.3.14.2"
    "37.1": bytes.fromhex("620173616a"),  # LinuxPAServer37.0 -> "37.1.10.6"
    # UNVERIFIED - no real paserver binary matches "10.3.1.15" (the
    # version a real Delphi 10.2 Update 3 IDE, build 25.0.31059.3231,
    # reported expecting). Derived from the Major*10+Minor / Build*10+Patch
    # formula: major=10,minor=3 -> 103 (0x67); build=1,patch=15 -> 25
    # (0x19). That formula is known to be wrong for two-digit Patch values
    # in at least one real sample (19.0's real .1.13 encodes as 113, not
    # the predicted 23) so this is a real experiment, not a known-good value.
    "10.3": bytes.fromhex("61676119"),
}

DATA_LEN_RE = re.compile(rb'("data":\[)(\d+)(,)')

# The exact ServerMajorVersion+ServerMinorVersion byte sequence this
# specific backend (real PAServer 13.1 / 37.1.10.6) actually sends,
# captured directly rather than guessed at a boundary marker -- the
# byte(s) immediately following it are part of ScratchDir's own
# length-prefix and vary with path length, so they must NOT be touched.
BACKEND_SEGMENT = bytes.fromhex("620173616a")


def rewrite_verifyplatform(data: bytes, new_segment: bytes) -> bytes:
    if b'"rows":[0]' not in data or BACKEND_SEGMENT not in data:
        return data
    m = DATA_LEN_RE.search(data)
    if not m:
        return data
    old_len = int(m.group(2))
    new_len = old_len - len(BACKEND_SEGMENT) + len(new_segment)
    rewritten = (
        data[: m.start(2)]
        + str(new_len).encode()
        + data[m.end(2) :].replace(BACKEND_SEGMENT, new_segment, 1)
    )
    log.info(
        "rewrote VerifyPlatform response: %s -> %s (data len %d -> %d)",
        BACKEND_SEGMENT.hex(),
        new_segment.hex(),
        old_len,
        new_len,
    )
    return rewritten


async def pump(src_reader, dst_writer, conn_id, direction, rewrite):
    try:
        while True:
            data = await src_reader.read(4096)
            if not data:
                break
            if rewrite:
                data = rewrite_verifyplatform(data, rewrite)
            log.info("[conn-%d] %s %d bytes:\n%s", conn_id, direction, len(data), format_hexdump(data))
            dst_writer.write(data)
            await dst_writer.drain()
    except (ConnectionResetError, BrokenPipeError, OSError) as exc:
        log.debug("[conn-%d] %s stream ended: %s", conn_id, direction, exc)
    finally:
        try:
            dst_writer.write_eof()
        except (OSError, NotImplementedError):
            pass


async def handle_client(reader, writer, target_host, target_port, spoof_bytes):
    conn_id = next(connection_ids)
    peer = writer.get_extra_info("peername")
    log.info("[conn-%d] client connected from %s", conn_id, peer)
    try:
        target_reader, target_writer = await asyncio.open_connection(target_host, target_port)
    except OSError as exc:
        log.error("[conn-%d] failed to connect to backend %s:%d: %s", conn_id, target_host, target_port, exc)
        writer.close()
        await writer.wait_closed()
        return

    await asyncio.gather(
        pump(reader, target_writer, conn_id, "client->paserver", None),
        pump(target_reader, writer, conn_id, "paserver->client", spoof_bytes),
        return_exceptions=True,
    )
    for w in (writer, target_writer):
        try:
            w.close()
            await w.wait_closed()
        except OSError:
            pass
    log.info("connection closed")


async def serve(args, spoof_bytes):
    server = await asyncio.start_server(
        lambda r, w: handle_client(r, w, args.target_host, args.target_port, spoof_bytes),
        args.listen_host,
        args.listen_port,
    )
    log.info(
        "pacommander-spoof listening on %s:%d, forwarding to %s:%d, spoofing as %s",
        args.listen_host,
        args.listen_port,
        args.target_host,
        args.target_port,
        args.target_version,
    )
    async with server:
        await server.serve_forever()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--listen-host", default="0.0.0.0")
    parser.add_argument("--listen-port", type=int, default=64211)
    parser.add_argument("--target-host", default="127.0.0.1")
    parser.add_argument("--target-port", type=int, default=64212)
    parser.add_argument("--target-version", required=True, choices=sorted(TARGET_VERSIONS))
    parser.add_argument("--log-level", default="INFO")
    args = parser.parse_args()

    logging.basicConfig(level=args.log_level.upper(), format="%(asctime)s [%(levelname)s] %(message)s")

    spoof_bytes = TARGET_VERSIONS[args.target_version]
    try:
        asyncio.run(serve(args, spoof_bytes))
    except KeyboardInterrupt:
        log.info("shutting down")


if __name__ == "__main__":
    main()
