#!/usr/bin/env python
#    Copyright 2013 - 2015 Mirantis, Inc.
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

import argparse
from ConfigParser import SafeConfigParser
import functools
import json
import logging
import logging.config
import logging.handlers
import re
import socket
import StringIO
import subprocess
import sys
from time import sleep

from neutronclient.neutron import client as n_client

LOG_NAME = 'q-agent-cleanup'

API_VER = '2.0'
PORT_ID_PART_LEN = 11


def make_logger(handler=logging.StreamHandler(sys.stdout), level=logging.INFO):
    format = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
    handler.setFormatter(format)
    logger = logging.getLogger(LOG_NAME)
    logger.addHandler(handler)
    logger.setLevel(level)
    return logger

LOG = make_logger()

AUTH_KEYS = {
    'tenant_name': 'admin_tenant_name',
    'username': 'admin_user',
    'password': 'admin_password',
    'auth_url': 'auth_uri',
}


def get_auth_data(cfg_file, section='keystone_authtoken', keys=AUTH_KEYS):
    cfg = SafeConfigParser()
    with open(cfg_file) as f:
        cfg.readfp(f)
    auth_data = {}
    for key, value in keys.iteritems():
        auth_data[key] = cfg.get(section, value)
    return auth_data

# Note(xarses): be careful not to inject \n's into the regex pattern
# or it will case the maching to fail
RECOVERABLE = re.compile((
    '(HTTP\s+400\))|'
    '(400-\{\'message\'\:\s+\'\'\})|'
    '(\[Errno 111\]\s+Connection\s+refused)|'
    '(503\s+Service\s+Unavailable)|'
    '(504\s+Gateway\s+Time-out)|'
    '(\:\s+Maximum\s+attempts\s+reached)|'
    '(Unauthorized\:\s+bad\s+credentials)|'
    '(Max\s+retries\s+exceeded)|'
    """('*NoneType'*\s+object\s+ha'\s+no\s+attribute\s+'*__getitem__'*$)|"""
    '(No\s+route\s+to\s+host$)|'
    '(Lost\s+connection\s+to\s+MySQL\s+server)'), flags=re.M)

RETRY_COUNT = 50
RETRY_DELAY = 2


def retry(func, pattern=RECOVERABLE):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        i = 0
        while True:
            try:
                return func(*args, **kwargs)
            except Exception as e:
                if pattern and not pattern.match(e.message):
                    raise e
                i += 1
                if i >= RETRY_COUNT:
                    raise e
                print("retry request {0}: {1}".format(i, e))
                sleep(RETRY_DELAY)
    return wrapper


class NeutronCleaner(object):
    PORT_NAME_PREFIXES_BY_DEV_OWNER = {
        'network:dhcp':             'tap',
        'network:router_gateway':   'qg-',
        'network:router_interface': 'qr-',
    }
    PORT_NAME_PREFIXES = {
        # contains tuples of prefixes
        'dhcp': (PORT_NAME_PREFIXES_BY_DEV_OWNER['network:dhcp'],),
        'l3': (
            PORT_NAME_PREFIXES_BY_DEV_OWNER['network:router_gateway'],
            PORT_NAME_PREFIXES_BY_DEV_OWNER['network:router_interface']
        )
    }
    BRIDGES_FOR_PORTS_BY_AGENT = {
        'dhcp': ('br-int',),
        'l3':   ('br-int', 'br-ex'),
    }
    PORT_OWNER_PREFIXES = {
        'dhcp': ('network:dhcp',),
        'l3':   ('network:router_gateway', 'network:router_interface')
    }
    NS_NAME_PREFIXES = {
        'dhcp': 'qdhcp',
        'l3':   'qrouter',
    }
    AGENT_BINARY_NAME = {
        'dhcp': 'neutron-dhcp-agent',
        'l3':   'neutron-l3-agent',
        'ovs':  'neutron-openvswitch-agent'
    }

    CMD__list_ovs_port = ['ovs-vsctl', 'list-ports']
    CMD__remove_ovs_port = ['ovs-vsctl', '--', '--if-exists', 'del-port']
    CMD__remove_ip_addr = ['ip', 'address', 'delete']
    CMD__ip_netns_list = ['ip', 'netns', 'list']
    CMD__ip_netns_exec = ['ip', 'netns', 'exec']

    # 14: tap-xxxyyyzzz:
    RE__port_in_portlist = re.compile(r"^\s*\d+\:\s+([\w-]+)\:")

    def __init__(self, options, log=None):
        self.log = log
        self.auth_data = get_auth_data(cfg_file=options.get('authconf'))
        self.options = options
        self.agents = {}
        self.debug = options.get('debug')
        self.RESCHEDULING_CALLS = {
            'dhcp': self._reschedule_agent_dhcp,
            'l3':   self._reschedule_agent_l3,
        }

        self._client = None

    @property
    @retry
    def client(self):
        if self._client is None:
            self._client = n_client.Client(API_VER, **self.auth_data)
        return self._client

    @retry
    def _get_agents(self, use_cache=True):
        return self.client.list_agents()['agents']

    @retry
    def _get_routers(self, use_cache=True):
        return self.client.list_routers()['routers']

    @retry
    def _get_networks(self, use_cache=True):
        return self.client.list_networks()['networks']

    @retry
    def _list_networks_on_dhcp_agent(self, agent_id):
        return self.client.list_networks_on_dhcp_agent(
            agent_id)['networks']

    @retry
    def _list_routers_on_l3_agent(self, agent_id):
        return self.client.list_routers_on_l3_agent(
            agent_id)['routers']

    @retry
    def _list_l3_agents_on_router(self, router_id):
        return self.client.list_l3_agent_hosting_routers(
            router_id)['agents']

    @retry
    def _list_dhcp_agents_on_network(self, network_id):
        return self.client.list_dhcp_agent_hosting_networks(
            network_id)['agents']

    def _list_orphaned_networks(self):
        networks = self._get_networks()
        self.log.debug(
            "_list_orphaned_networks:, got list of networks {0}".format(
                json.dumps(networks, indent=4)))
        orphaned_networks = []
        for network in networks:
            if len(self._list_dhcp_agents_on_network(network['id'])) == 0:
                orphaned_networks.append(network['id'])
        self.log.debug(
            "_list_orphaned_networks:, got list of orphaned networks {0}".
            format(orphaned_networks))
        return orphaned_networks

    def _list_orphaned_routers(self):
        routers = self._get_routers()
        self.log.debug(
            "_list_orphaned_routers:, got list of routers {0}".format(
                json.dumps(routers, indent=4)))
        orphaned_routers = []
        for router in routers:
            if len(self._list_l3_agents_on_router(router['id'])) == 0:
                orphaned_routers.append(router['id'])
        self.log.debug(
            "_list_orphaned_routers:, got list of orphaned routers {0}".format(
                orphaned_routers))
        return orphaned_routers

    @retry
    def _add_network_to_dhcp_agent(self, agent_id, net_id):
        return self.client.add_network_to_dhcp_agent(
            agent_id, {"network_id": net_id})

    @retry
    def _add_router_to_l3_agent(self, agent_id, router_id):
        return self.client.add_router_to_l3_agent(
            agent_id, {"router_id": router_id})

    @retry
    def _remove_router_from_l3_agent(self, agent_id, router_id):
        return self.client.remove_router_from_l3_agent(
            agent_id, router_id)

    @retry
    def _delete_agent(self, agent_id):
        return self.client.delete_agent(agent_id)

    def _get_agents_by_type(self, agent, use_cache=True):
        self.log.debug("_get_agents_by_type: start.")
        rv = self.agents.get(agent, []) if use_cache else []
        if not rv:
            agents = self._get_agents(use_cache=use_cache)
            for i in agents:
                if i['binary'] == self.AGENT_BINARY_NAME.get(agent):
                    rv.append(i)
            from_cache = ''
        else:
            from_cache = ' from local cache'
        self.log.debug(
            "_get_agents_by_type: end, {0} rv: {1}".format(
                from_cache, json.dumps(rv, indent=4)))
        return rv

    def _execute(self, cmd):
        process = subprocess.Popen(
            cmd,
            shell=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        (stdout, stderr) = process.communicate()
        ret_code = process.returncode
        if ret_code != 0:
            self.log.error(
                "ERROR (rc={0}) while execution {1}, stderr: {2}".format(
                    ret_code, ' '.join(cmd), stderr))
            return None
        return ret_code, stdout

    def __collect_namespaces_for_agent(self, agent):
        cmd = self.CMD__ip_netns_list[:]
        self.log.debug("Execute command '{0}'".format(' '.join(cmd)))
        ret_code, stdout = self._execute(cmd)
        if ret_code != 0:
            return []
        # filter namespaces by given agent type
        netns = []
        for ns in StringIO.StringIO(stdout):
            ns = ns.strip()
            self.log.debug("Found network namespace '{0}'".format(ns))
            if ns.startswith(self.NS_NAME_PREFIXES[agent]):
                netns.append(ns)
        return netns

    def __collect_ports_for_namespace(self, ns):
        cmd = self.CMD__ip_netns_exec[:]
        cmd.extend([ns, 'ip', 'l', 'show'])
        self.log.debug("Execute command '{0}'".format(' '.join(cmd)))
        ret_code, stdout = self._execute(cmd)
        if ret_code != 0:
            return []
        ports = []
        for line in StringIO.StringIO(stdout):
            pp = self.RE__port_in_portlist.match(line)
            if not pp:
                continue
            port = pp.group(1)
            if port != 'lo':
                self.log.debug("Found port '{0}'".format(port))
                ports.append(port)
        return ports

    def _cleanup_ports(self, agent):
        self.log.debug("_cleanup_ports: start.")

        # get namespaces list
        netns = self.__collect_namespaces_for_agent(agent)

        # collect ports from namespace
        ports = []
        for ns in netns:
            ports.extend(self.__collect_ports_for_namespace(ns))

        # iterate by port_list and remove port from OVS
        for port in ports:
            cmd = self.CMD__remove_ovs_port[:]
            cmd.append(port)
            if self.options.get('noop'):
                self.log.info("NOOP-execution: '{0}'".format(' '.join(cmd)))
            else:
                self.log.debug("Execute command '{0}'".format(' '.join(cmd)))
                self._execute(cmd)
        self.log.debug("_cleanup_ports: end.")

        return True

    def _reschedule_agent_dhcp(self, agent_type):
        self.log.debug("_reschedule_agent_dhcp: start.")
        agents = {
            'alive': [],
            'dead':  []
        }
        # collect networklist from dead DHCP-agents
        dead_networks = []
        for agent in self._get_agents_by_type(agent_type):
            if agent['alive']:
                self.log.info(
                    "found alive DHCP agent: {0}".format(agent['id']))
                agents['alive'].append(agent)
            else:
                # dead agent
                self.log.info(
                    "found dead DHCP agent: {0}".format(agent['id']))
                agents['dead'].append(agent)
                for net in self._list_networks_on_dhcp_agent(agent['id']):
                    dead_networks.append(net)

        if dead_networks and agents['alive']:
            # get network-ID list of already attached to alive agent networks
            lucky_ids = set()
            map(
                lambda net: lucky_ids.add(net['id']),
                self._list_networks_on_dhcp_agent(agents['alive'][0]['id'])
            )
            # add dead networks to alive agent
            for net in dead_networks:
                if net['id'] not in lucky_ids:
                    # attach network to agent
                    self.log.info(
                        "attach network {net} to DHCP agent {agent}".format(
                            net=net['id'],
                            agent=agents['alive'][0]['id']))
                    if not self.options.get('noop'):
                        self._add_network_to_dhcp_agent(
                            agents['alive'][0]['id'], net['id'])

            # remove dead agents if need (and if found alive agent)
            if self.options.get('remove-dead'):
                for agent in agents['dead']:
                    self.log.info(
                        "remove dead DHCP agent: {0}".format(agent['id']))
                    if not self.options.get('noop'):
                        self._delete_agent(agent['id'])
        orphaned_networks = self._list_orphaned_networks()
        self.log.info("_reschedule_agent_dhcp: rescheduling orphaned networks")
        if orphaned_networks and agents['alive']:
            for network in orphaned_networks:
                self.log.info(
                    "_reschedule_agent_dhcp: rescheduling {0} to {1}".format(
                        network, agents['alive'][0]['id']))
                if not self.options.get('noop'):
                    self._add_network_to_dhcp_agent(
                        agents['alive'][0]['id'], network)
        self.log.info(
            "_reschedule_agent_dhcp: ended rescheduling of orphaned networks")
        self.log.debug("_reschedule_agent_dhcp: end.")

    def _reschedule_agent_l3(self, agent_type):
        self.log.debug("_reschedule_agent_l3: start.")
        agents = {
            'alive': [],
            'dead':  []
        }
        # collect router-list from dead DHCP-agents
        dead_routers = []  # array of tuples (router, agentID)
        for agent in self._get_agents_by_type(agent_type):
            if agent['alive']:
                self.log.info("found alive L3 agent: {0}".format(agent['id']))
                agents['alive'].append(agent)
            else:
                # dead agent
                self.log.info("found dead L3 agent: {0}".format(agent['id']))
                agents['dead'].append(agent)
                map(
                    lambda rou: dead_routers.append((rou, agent['id'])),
                    self._list_routers_on_l3_agent(agent['id'])
                )
        self.log.debug(
            "L3 agents in cluster: {0}".format(
                json.dumps(agents, indent=4)))
        self.log.debug("Routers, attached to dead L3 agents: {0}".format(
            json.dumps(dead_routers, indent=4)))

        if dead_routers and agents['alive']:
            # get router-ID list of already attached to alive agent routerss
            lucky_ids = set()
            map(
                lambda rou: lucky_ids.add(rou['id']),
                self._list_routers_on_l3_agent(agents['alive'][0]['id'])
            )
            # remove dead agents after rescheduling
            for agent in agents['dead']:
                self.log.info("remove dead L3 agent: {0}".format(agent['id']))
                if not self.options.get('noop'):
                    self._delete_agent(agent['id'])
            # move routers from dead to alive agent
            for rou in filter(
                    lambda rr: not(rr[0]['id'] in lucky_ids), dead_routers):
                self.log.info(
                    "schedule router {0} to L3 agent {1}".format(
                        rou[0]['id'],
                        agents['alive'][0]['id']))
                if not self.options.get('noop'):
                    self._add_router_to_l3_agent(
                        agents['alive'][0]['id'], rou[0]['id'])

        orphaned_routers = self._list_orphaned_routers()
        self.log.info("_reschedule_agent_l3: rescheduling orphaned routers")
        if orphaned_routers and agents['alive']:
            for router in orphaned_routers:
                self.log.info(
                    "_reschedule_agent_l3: rescheduling {0} to {1}".format(
                        router, agents['alive'][0]['id']))
                if not self.options.get('noop'):
                    self._add_router_to_l3_agent(
                        agents['alive'][0]['id'], router)
        self.log.info(
            "_reschedule_agent_l3: ended rescheduling of orphaned routers")
        self.log.debug("_reschedule_agent_l3: end.")

    def _remove_self(self, agent_type):
        self.log.debug("_remove_self: start.")
        for agent in self._get_agents_by_type(agent_type):
            if agent['host'] == socket.gethostname():
                self.log.info(
                    "_remove_self: deleting our own agent {0} of type {1}".
                    format(agent['id'], agent_type))
                if not self.options.get('noop'):
                    self._delete_agent(agent['id'])
        self.log.debug("_remove_self: end.")

    def _reschedule_agent(self, agent):
        self.log.debug("_reschedule_agents: start.")
        task = self.RESCHEDULING_CALLS.get(agent, None)
        if task:
            task(agent)
        self.log.debug("_reschedule_agents: end.")

    def do(self, agent):
        if self.options.get('cleanup-ports'):
            self._cleanup_ports(agent)
        if self.options.get('reschedule'):
            self._reschedule_agent(agent)
        if self.options.get('remove-self'):
            self._remove_self(agent)

    def _test_healthy(self, agent_list, hostname):
        rv = False
        for agent in agent_list:
            if agent['host'] == hostname and agent['alive']:
                return True
        return rv

    def test_healthy(self, agent_type):
        # OCF_FAILED_MASTER,
        # http://www.linux-ha.org/doc/dev-guides/_literal_ocf_failed_master_literal_9.html

        rc = 9
        agentlist = self._get_agents_by_type(agent_type)
        for hostname in self.options.get('test-hostnames'):
            if self._test_healthy(agentlist, hostname):
                return 0
        return rc


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Neutron network node cleaning tool.')
    parser.add_argument(
        "-c",
        "--auth-config",
        dest="authconf",
        default="/etc/neutron/neutron.conf",
        help="Read authconfig from service file",
        metavar="FILE")
    parser.add_argument(
        "-t",
        "--auth-token",
        dest="auth-token",
        default=None,
        help="Authenticating token (instead username/passwd)",
        metavar="TOKEN")
    parser.add_argument(
        "-u",
        "--admin-auth-url",
        dest="admin-auth-url",
        default=None,
        help="Authenticating URL (admin)",
        metavar="URL")
    parser.add_argument(
        "--retries",
        dest="retries",
        type=int,
        default=50,
        help="try NN retries for API call",
        metavar="NN")
    parser.add_argument(
        "--sleep",
        dest="sleep",
        type=int,
        default=2,
        help="sleep seconds between retries",
        metavar="SEC")
    parser.add_argument(
        "-a",
        "--agent",
        dest="agent",
        action="append",
        help="specyfy agents for cleaning",
        required=True)
    parser.add_argument(
        "--cleanup-ports",
        dest="cleanup-ports",
        action="store_true",
        default=False,
        help="cleanup ports for given agents on this node")
    parser.add_argument(
        "--remove-self",
        dest="remove-self",
        action="store_true",
        default=False,
        help="remove ourselves from agent list")
    parser.add_argument(
        "--activeonly",
        dest="activeonly",
        action="store_true",
        default=False,
        help="cleanup only active ports")
    parser.add_argument(
        "--reschedule",
        dest="reschedule",
        action="store_true",
        default=False,
        help="reschedule given agents")
    parser.add_argument(
        "--remove-dead",
        dest="remove-dead",
        action="store_true",
        default=False,
        help="remove dead agents while rescheduling")
    parser.add_argument(
        "--test-alive-for-hostname",
        dest="test-hostnames",
        action="append",
        help="testing agent's healthy for given hostname")
    parser.add_argument(
        "--external-bridge",
        dest="external-bridge",
        default="br-ex",
        help="external bridge name",
        metavar="IFACE")
    parser.add_argument(
        "--integration-bridge",
        dest="integration-bridge",
        default="br-int",
        help="integration bridge name",
        metavar="IFACE")
    parser.add_argument(
        "-l",
        "--log",
        dest="log",
        action="store",
        help="log to file instead of STDOUT")
    parser.add_argument(
        "--noop",
        dest="noop",
        action="store_true",
        default=False,
        help="do not execute, print to log instead")
    parser.add_argument(
        "--debug",
        dest="debug",
        action="store_true",
        default=False,
        help="debug")
    args = parser.parse_args()
    RETRY_COUNT = args.retries
    RETRY_DELAY = args.sleep

    # setup logging
    if args.log:
        LOG = make_logger(
            handler=logging.handlers.WatchedFileHandler(args.log))

    if args.debug:
        LOG.setLevel(logging.DEBUG)

    LOG.info("Started: {0}".format(' '.join(sys.argv)))
    cleaner = NeutronCleaner(options=vars(args), log=LOG)
    rc = 0
    if vars(args).get('test-hostnames'):
        rc = cleaner.test_healthy(args.agent[0])
    else:
        for i in args.agent:
            cleaner.do(i)
    LOG.debug("End.")
    sys.exit(rc)
