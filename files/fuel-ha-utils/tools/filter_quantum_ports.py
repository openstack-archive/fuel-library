#!/usr/bin/env python
import re
import time
import sys
import optparse
from neutronclient.neutron import client as q_client
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


class NeutronXxx(object):
    def __init__(self, openrc, retries=20, sleep=2):
        self.auth_config = openrc
        self.connect_retries = retries
        self.sleep = sleep
        ret_count = retries
        while True:
            if ret_count <= 0 :
                print(">>> Keystone error: no more retries for connect to keystone server.")
                sys.exit(1)
            try:
                self.keystone = ks_client.Client(
                    username=openrc['OS_USERNAME'],
                    password=openrc['OS_PASSWORD'],
                    tenant_name=openrc['OS_TENANT_NAME'],
                    auth_url=openrc['OS_AUTH_URL'],
                )
                break
            except Exception as e:
                errmsg = e.message.strip()
                if re.search(r"Connection\s+refused$", errmsg, re.I) or \
                   re.search(r"Connection\s+timed\s+out$", errmsg, re.I) or\
                   re.search(r"Service\s+Unavailable$", errmsg, re.I) or\
                   re.search(r"'*NoneType'*\s+object\s+has\s+no\s+attribute\s+'*__getitem__'*$", errmsg, re.I) or \
                   re.search(r"No\s+route\s+to\s+host$", errmsg, re.I):
                      print(">>> Can't connect to {0}, wait for server ready...".format(self.auth_config['OS_AUTH_URL']))
                      time.sleep(self.sleep)
                else:
                    print(">>> Keystone error:\n{0}".format(e.message))
                    raise e
            ret_count -= 1
        self.token = self.keystone.auth_token
        self.client = q_client.Client(
            API_VER,
            endpoint_url=self.keystone.service_catalog.url_for(service_type='network'),
            token=self.token,
        )

    def get_ports(self):
        ret_count = self.connect_retries
        while True:
            if ret_count <= 0 :
                print(">>> Neutron error: no more retries for connect to keystone server.")
                sys.exit(1)
            try:
                rv = self.client.list_ports()['ports']
                break
            except Exception as e:
                errmsg = e.message.strip()
                if re.search(r"Connection\s+refused", errmsg, re.I) or\
                   re.search(r"Connection\s+timed\s+out", errmsg, re.I) or\
                   re.search(r"503\s+Service\s+Unavailable", errmsg, re.I) or\
                   re.search(r"No\s+route\s+to\s+host", errmsg, re.I):
                      print(">>> Can't connect to {0}, wait for server ready...".format(self.keystone.service_catalog.url_for(service_type='network')))
                      time.sleep(self.sleep)
                else:
                    print(">>> Neutron error:\n{0}".format(e.message))
                    raise e
            ret_count -= 1
        return rv

    def get_ports_by_owner(self, owner, activeonly=False):
        rv = []
        ports = self.get_ports()
        if activeonly:
            tmp = []
            for i in ports:
                if i['status'] == 'ACTIVE':
                    tmp.append(i)
                ports = tmp
        for i in ports:
            if i['device_owner'] == owner:
                rv.append(i)
        return rv

    PORT_NAME_PREFIXES = {
        'network:dhcp':             'tap',
        'network:router_gateway':   'qg-',
        'network:router_interface': 'qr-',
    }

    def get_ifnames_for(self, port_owner, activeonly=False, port_id_part_len=11):
        port_name_prefix = self.PORT_NAME_PREFIXES.get(port_owner)
        if port_name_prefix is None:
            return []
        rv = []
        for i in self.get_ports_by_owner(port_owner, activeonly=activeonly):
            rv.append("{0}{1} {2}".format(port_name_prefix, i['id'][:port_id_part_len], i['fixed_ips'][0]['ip_address']))
        return rv


if __name__ == '__main__':
    parser = optparse.OptionParser()
    parser.add_option("-c", "--auth-config", dest="authconf", default="/root/openrc",
                      help="Authenticatin config FILE", metavar="FILE")
    parser.add_option("-r", "--retries", dest="retries", type="int", default=50,
                      help="try NN retries for get keystone token", metavar="NN")
    parser.add_option("-a", "--activeonly", dest="activeonly", action="store_true", default=False,
                      help="get only active ports")
    (options, args) = parser.parse_args()
    #
    if len(args) != 1:
        parser.error("incorrect number of arguments")
    #
    Qu = NeutronXxx(get_authconfig(options.authconf), retries=options.retries)
    for i in Qu.get_ifnames_for(args[0].strip(" \"\'"), activeonly=options.activeonly):
        print(i)
###
