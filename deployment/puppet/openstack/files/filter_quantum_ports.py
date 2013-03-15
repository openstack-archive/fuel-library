#!/usr/bin/env python
import re
import time
import optparse
from quantumclient.quantum import client as q_client
from keystoneclient.v2_0 import client as ks_client

API_VER = '2.0'


def get_authconfig(cfg_file):
    # Read OS auth config file
    rv = {}
    stripchars=" \'\""
    with open(cfg_file) as f:
        for line in f:
            rg = re.match(r'\s*export\s+(\w+)\s*=\s*(.*)',line)
            if rg :
                #print("[{}]-[{}]".format(rg.group(1),rg.group(2).strip()))
                rv[rg.group(1).strip(stripchars)]=rg.group(2).strip(stripchars)
    return rv


class QuantumXxx(object):

    rc = {}
    token = u''
    ks = None

    def __init__(self, rc, wait_server=True, tries_timeout=2):
        self.rc = rc
        while True:
            try:
                self.ks = ks_client.Client(
                    username=rc['OS_USERNAME'],
                    password=rc['OS_PASSWORD'],
                    tenant_name=rc['OS_TENANT_NAME'],
                    auth_url=rc['OS_AUTH_URL'],
                )
                break
            except Exception as e:
                if wait_server and re.search(r"Connection\s+refused$", e.message, re.I):
                    print(">>> Can't connect to {0}, wait for server ready...".format(rc['OS_AUTH_URL']))
                    time.sleep(tries_timeout)
                else:
                    print(">>> Keystone error:\n")
                    raise e
        self.token = self.ks.auth_token
        self.client = q_client.Client(
            API_VER,
            endpoint_url=self.ks.service_catalog.url_for(service_type='network'),
            token=self.token,
        )

    def get_ports(self):
        return self.client.list_ports()['ports']

    def get_active_ports(self):
        rv = []
        for i in self.get_ports():
            if i['status'] == 'ACTIVE':
                rv.append(i)
        return rv

    def get_active_ports_by_owner(self, owner):
        rv = []
        for i in self.get_active_ports():
            if i['device_owner'] == owner:
                rv.append(i)
        return rv

    def get_ifnames_for(self, port_owner, port_id_part_len=11):
        if port_owner == 'network:dhcp':
            port_name_prefix='tap'
        elif port_owner == 'network:router_gateway':
            port_name_prefix='qg-'
        elif port_owner == 'network:router_interface':
            port_name_prefix='qr-'
        else:
            return []
        rv = []
        for i in self.get_active_ports_by_owner(port_owner):
            rv.append("{0}{1}".format(port_name_prefix, i['id'][:port_id_part_len]))
        return rv


if __name__ == '__main__':
    parser = optparse.OptionParser()
    parser.add_option("-c", "--auth-config", dest="authconf", default="/root/openrc",
                      help="Authenticatin config FILE", metavar="FILE")
    (options, args) = parser.parse_args()
    #
    if len(args) != 1:
        parser.error("incorrect number of arguments")
    #
    Qu = QuantumXxx(get_authconfig(options.authconf))
    for i in Qu.get_ifnames_for(args[0].strip(" \"\'")):
        print(i)

    # print Qu.get_ifnames_for('network:dhcp')
    # print Qu.get_ifnames_for('network:router_gateway')
    # print Qu.get_ifnames_for('network:router_interface')
