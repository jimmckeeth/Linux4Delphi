#!/usr/bin/env python3
"""Minimal fake-Delphi-IDE client: connect to a PAServer and read VerifyPlatform's response.

Replays the exact byte sequence captured from real Delphi IDEs
(handshake -> connect -> GetDatabase -> prepare/execute VerifyPlatform),
skipping SetName/SetAddress/auth-callback to see whether PAServer answers
without them.
"""
import socket
import sys
import re

HANDSHAKE = bytes([5, 5, 5, 5, 5])

CONNECT = (
    b'{"method":"connect","params":[{"DriverName":"DataSnap","HostName":"127.0.0.1",'
    b'"Port":"0","DSAuthenticationUser":"","DSAuthenticationPassword":'
    b'"695602992E04E52893978599B689E4A5","BufferKBSize":"512",'
    b'"IPImplementationID":"Agent.IPPeerImpl","DriverUnit":"Data.DBXDataSnap",'
    b'"CommunicationProtocol":"tcp/ip","DatasnapContext":"datasnap/",'
    b'"DriverAssemblyLoader":"Borland.Data.TDBXClientDriverLoader,Borland.Data.'
    b'DbxClientDriver,Version=24.0.0.0,Culture=neutral,PublicKeyToken=91d62ebb5b0d1b1b"}]}'
)

GETDATABASE = (
    b'{"method":"execute","params":[{"fields":[-1,false,"Dbx.MetaData","GetDatabase"]}]}'
)

PREPARE_VERIFYPLATFORM = (
    b'{"method":"prepare","params":[-1,false,"DataSnap.ServerMethod",'
    b'"TServerMethods.VerifyPlatform"]}'
)


def execute_verifyplatform(handle: int) -> bytes:
    return (
        b'{"method":"execute","params":[{"handle":[%d]},{"data":[13,' % handle
        + b"\x27Linux64\xc0\xc0\xc0\xc0\xc0"
        + b"]}]}"
    )


def recv_msg(sock, size=65536, timeout=5.0):
    sock.settimeout(timeout)
    return sock.recv(size)


def main():
    host, port = sys.argv[1], int(sys.argv[2])
    sock = socket.create_connection((host, port), timeout=5.0)

    sock.sendall(HANDSHAKE)
    hs = recv_msg(sock, 16)
    print(f"handshake reply: {hs.hex()}")

    sock.sendall(CONNECT)
    r = recv_msg(sock)
    print(f"connect result: {r!r}")

    sock.sendall(GETDATABASE)
    r = recv_msg(sock)
    print(f"GetDatabase result: {len(r)} bytes")

    sock.sendall(PREPARE_VERIFYPLATFORM)
    r = recv_msg(sock)
    print(f"prepare(VerifyPlatform) result: {r!r}")
    m = re.search(rb'"handle":\[(\d+)\]', r)
    if not m:
        print("!! could not find handle in prepare response, aborting")
        sock.close()
        return
    handle = int(m.group(1))

    sock.sendall(execute_verifyplatform(handle))
    r = recv_msg(sock)
    print(f"execute(VerifyPlatform) result ({len(r)} bytes):")
    print(f"  hex: {r.hex()}")
    print(f"  raw: {r!r}")

    sock.close()


if __name__ == "__main__":
    main()
