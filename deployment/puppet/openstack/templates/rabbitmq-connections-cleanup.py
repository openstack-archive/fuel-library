# Copyright (c) 2014 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.


import ConfigParser
import pyrabbit
import pyrabbit.api
import sys
import time
import traceback


def collect_suspected_connections(host, port, login, password, vhost):
    client = pyrabbit.api.Client('{0}:{1}'.format(host, port), login, password)
    connections = client.get_connections()
    suspected_connections = set()
    for connection in connections or []:
        if connection['vhost'] == vhost and connection.get(
                'channels', 1) == 0 and connection.get('timeout', 0) == 0:
            print 'Connection {0} has no channels'.format(connection['name'])
            suspected_connections.add(connection['name'])
    if len(suspected_connections) > 0:
        yield (client, suspected_connections)


def kill_connections(collected, vhost):
    if len(collected) == 0:
        print 'No problem found'
        return

    print 'Sleeping for 10s'
    time.sleep(10)

    for client, suspected_connections in collected:
        connections = client.get_connections()
        for connection in connections:
            name = connection['name']
            if connection['vhost'] == vhost and connection.get(
                    'channels', 1) == 0 and name in suspected_connections:
                print 'Terminating connection', name
                client.delete_connection(name)


class FakeSecHead(object):
    def __init__(self, fp):
        self.fp = fp
        self.header = '[DEFAULT]\n'

    def readline(self):
        if self.header:
            try:
                return self.header
            finally:
                self.header = None
        else:
            return self.fp.readline()


def main():
    cfg = ConfigParser.ConfigParser(
        defaults={
            'rabbit_hosts': '127.0.0.1',
            'rabbit_virtual_host': '/',
            'rabbit_userid': 'guest',
            'rabbit_password': 'guest'
        })
    cfg.readfp(FakeSecHead(open(sys.argv[1])))
    hosts = cfg.get('DEFAULT', 'rabbit_hosts').split(',')
    vhost = cfg.get('DEFAULT', 'rabbit_virtual_host')
    login = cfg.get('DEFAULT', 'rabbit_userid')
    password = cfg.get('DEFAULT', 'rabbit_password')

    suspected_connections = []
    for record in hosts:
        hostname = record.split(':')[0]
        port = int(sys.argv[2]) if len(sys.argv) == 3 else 15672
        try:
            print 'Accessing RabbitMQ management plugin on ' \
                  '{0}:{1}'.format(hostname, port)
            suspected_connections.extend(collect_suspected_connections(
                hostname, port, login, password, vhost))
            break
        except Exception as e:
            traceback.print_exc(e, file=sys.stdout)
            print
    kill_connections(suspected_connections, vhost)


if __name__ == "__main__":
    if 2 < len(sys.argv) > 3:
        print 'Usage: python oslomessaging-recover config-file.conf [port]'
    else:
        main()
