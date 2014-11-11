#!/usr/bin/python
# based on https://github.com/nl5887/python-haproxy
import sys
import os
import re
import argparse
import select
import socket
import string

from time import time
from traceback import format_exc


class TimeoutException(Exception):
    pass

class HAProxyStats(object):
    """ Used for communicating with HAProxy through its local UNIX socket interface.
    """
    def __init__(self, socket_name=None):
        self.socket_name = socket_name

    def execute(self, command, timeout=1):
        """ Executes a HAProxy command by sending a message to a HAProxy's local
        UNIX socket and waiting up to 'timeout' seconds for the response.
        """

        buffer = ""

        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        client.connect(self.socket_name)

        client.send(command + "\n")

        running = True
        while(running):
            r, w, e = select.select([client,],[],[], timeout)

            if not (r or w or e):
                raise TimeoutException()

            for s in r:
                if (s is client):
                    buffer = buffer + client.recv(16384)
                    running = (len(buffer)==0)

        client.close()
        return (buffer.decode('utf-8').split('\n'))

def main():
    parser = argparse.ArgumentParser(description='Check if backend is UP')
    parser.add_argument('socket', type=str, help='Haproxy admin socket')
    parser.add_argument('backend', type=str, help='Haproxy backend to check')
    parser.add_argument('-v', '--verbose', help='Print backed info', action="store_true")
    args = parser.parse_args()

    stats = HAProxyStats(args.socket)
    ha_stats = stats.execute('show stat')

    pattern_backend = "^" + re.escape(args.backend) + ","
    pattern_backend_up = "^" + re.escape(args.backend) + ",BACKEND,.*,UP,"
    pattern_backend_ini = "^" + re.escape(args.backend) + ",.*,INI,"

    found_ini = 0
    found_up = 1

    for line in ha_stats:
        if args.verbose and re.match(pattern_backend, line):
            print line
        if re.match(pattern_backend_ini, line):
            found_ini = 1
        elif re.match(pattern_backend_up, line):
            found_up = 0

    sys.exit(found_ini + found_up)

if __name__ == '__main__':
    main()

