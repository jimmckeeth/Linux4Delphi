#!/usr/bin/env python3
"""pacommander logging proxy.

Listens on a local port, transparently forwards every byte to a real
PAServer instance, and logs all traffic in both directions. This is the
first building block toward a smart PAServer router; today it only proxies
and logs so the PAServer wire protocol can be studied.
"""

import argparse
import asyncio
import itertools
import logging
import os
import sys

MAX_DUMP_BYTES = 512
DEFAULT_LOG_FILE = os.path.join(os.path.expanduser("~"), ".pacommander", "pacommander.log")

log = logging.getLogger("pacommander")
connection_ids = itertools.count(1)


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


async def pump(src_reader, dst_writer, conn_id, direction):
    try:
        while True:
            data = await src_reader.read(4096)
            if not data:
                break
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


async def handle_client(reader, writer, target_host, target_port):
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

    log.info("[conn-%d] connected to backend %s:%d", conn_id, target_host, target_port)

    await asyncio.gather(
        pump(reader, target_writer, conn_id, "client->paserver"),
        pump(target_reader, writer, conn_id, "paserver->client"),
        return_exceptions=True,
    )

    for w in (writer, target_writer):
        try:
            w.close()
            await w.wait_closed()
        except OSError:
            pass

    log.info("[conn-%d] connection closed", conn_id)


def setup_logging(log_file, log_level):
    os.makedirs(os.path.dirname(log_file), exist_ok=True)
    formatter = logging.Formatter("%(asctime)s [%(levelname)s] %(message)s", datefmt="%Y-%m-%d %H:%M:%S")

    stream_handler = logging.StreamHandler(sys.stdout)
    stream_handler.setFormatter(formatter)

    file_handler = logging.FileHandler(log_file)
    file_handler.setFormatter(formatter)

    log.setLevel(log_level)
    log.addHandler(stream_handler)
    log.addHandler(file_handler)


async def serve(args):
    server = await asyncio.start_server(
        lambda r, w: handle_client(r, w, args.target_host, args.target_port),
        args.listen_host,
        args.listen_port,
    )
    log.info(
        "pacommander listening on %s:%d, forwarding to %s:%d",
        args.listen_host,
        args.listen_port,
        args.target_host,
        args.target_port,
    )
    async with server:
        await server.serve_forever()


def parse_args():
    parser = argparse.ArgumentParser(description="pacommander logging proxy for PAServer traffic")
    parser.add_argument("--listen-host", default="0.0.0.0")
    parser.add_argument("--listen-port", type=int, default=64212)
    parser.add_argument("--target-host", default="127.0.0.1")
    parser.add_argument("--target-port", type=int, default=64211)
    parser.add_argument("--log-file", default=DEFAULT_LOG_FILE)
    parser.add_argument("--log-level", default="INFO")
    return parser.parse_args()


def main():
    args = parse_args()
    setup_logging(args.log_file, args.log_level.upper())
    try:
        asyncio.run(serve(args))
    except KeyboardInterrupt:
        log.info("pacommander shutting down")


if __name__ == "__main__":
    main()
