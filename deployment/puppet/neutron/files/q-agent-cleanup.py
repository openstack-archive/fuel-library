#!/usr/bin/env python
import re
import time
import os
import sys
import random
import string
import json
import argparse
import logging
import logging.handlers
import shlex
import subprocess
import StringIO
from neutronclient.neutron import client as q_client
from keystoneclient.v2_0 import client as ks_client
from keystoneclient.apiclient.exceptions import NotFound as ks_NotFound

LOG_NAME = 'q-agent-cleanup'

API_VER = '2.0'
PORT_ID_PART_LEN = 11
TMP_USER_NAME = 'tmp_neutron_admin'


def get_authconfig(cfg_file):
    # Read OS auth config file
    rv = {}
    stripchars=" \'\""
    with open(cfg_file) as f:
        for line in f:
            rg = re.match(r'\s*export\s+(\w+)\s*=\s*(.*)',line)
            if rg :
                #Use shlex to unescape bash shell escape characters
                value = "".join(x for x in
                                shlex.split(rg.group(2).strip(stripchars)))
                rv[rg.group(1).strip(stripchars)] = value
    return rv


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
    BRIDGES_FOR_PORTS_BY_AGENT ={
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

    RE__port_in_portlist = re.compile(r"^\s*\d+\:\s+([\w-]+)\:")  # 14: tap-xxxyyyzzz:

    def __init__(self, openrc, options, log=None):
        self.log = log
        self.auth_config = openrc
        self.options = options
        self.agents = {}
        self.debug = options.get('debug')
        self.RESCHEDULING_CALLS = {
            'dhcp': self._reschedule_agent_dhcp,
            'l3':   self._reschedule_agent_l3,
        }

        self._token = None
        self._keystone = None
        self._client = None
        self._need_cleanup_tmp_admin = False

    def __del__(self):
        if self._need_cleanup_tmp_admin and self._keystone and self._keystone.username:
            try:
                self._keystone.users.delete(self._keystone.users.find(username=self._keystone.username))
            except:
                # if we get exception while cleaning temporary account -- nothing harm
                pass

    def generate_random_passwd(self, length=13):
        chars = string.ascii_letters + string.digits + '!@#$%^&*()'
        random.seed = (os.urandom(1024))
        return ''.join(random.choice(chars) for i in range(length))

    @property
    def keystone(self):
        if self._keystone is None:
            ret_count = self.options.get('retries', 1)
            tmp_passwd = self.generate_random_passwd()
            while True:
                if ret_count <= 0:
                    self.log.error(">>> Keystone error: no more retries for connect to keystone server.")
                    sys.exit(1)
                try:
                    a_token = self.options.get('auth-token')
                    a_url = self.options.get('admin-auth-url')
                    if a_token and a_url:
                        self.log.debug("Authentication by predefined token.")
                        # create keystone instance, authorized by service token
                        ks = ks_client.Client(
                            token=a_token,
                            endpoint=a_url,
                        )
                        service_tenant = ks.tenants.find(name='services')
                        auth_url = ks.endpoints.find(
                                        service_id=ks.services.find(type='identity').id
                                   ).internalurl
                        # find and re-create temporary rescheduling-admin user with random password
                        try:
                            user = ks.users.find(username=TMP_USER_NAME)
                            ks.users.delete(user)
                        except ks_NotFound:
                            # user not found, it's OK
                            pass
                        user = ks.users.create(TMP_USER_NAME, tmp_passwd, tenant_id=service_tenant.id)
                        ks.roles.add_user_role(user, ks.roles.find(name='admin'), service_tenant)
                        # authenticate newly-created tmp neutron admin
                        self._keystone = ks_client.Client(
                            username=user.username,
                            password=tmp_passwd,
                            tenant_id=user.tenantId,
                            auth_url=auth_url,
                        )
                        self._need_cleanup_tmp_admin = True
                    else:
                        self.log.debug("Authentication by given credentionals.")
                        self._keystone = ks_client.Client(
                            username=self.auth_config['OS_USERNAME'],
                            password=self.auth_config['OS_PASSWORD'],
                            tenant_name=self.auth_config['OS_TENANT_NAME'],
                            auth_url=self.auth_config['OS_AUTH_URL'],
                        )
                    break
                except Exception as e:
                    errmsg = str(e.message).strip()  # str() need, because keystone may use int as message in exception
                    if re.search(r"Connection\s+refused$", errmsg, re.I) or \
                       re.search(r"Connection\s+timed\s+out$", errmsg, re.I) or\
                       re.search(r"Lost\s+connection\s+to\s+MySQL\s+server", errmsg, re.I) or\
                       re.search(r"Service\s+Unavailable$", errmsg, re.I) or\
                       re.search(r"'*NoneType'*\s+object\s+has\s+no\s+attribute\s+'*__getitem__'*$", errmsg, re.I) or \
                       re.search(r"No\s+route\s+to\s+host$", errmsg, re.I):
                        self.log.info(">>> Can't connect to {0}, wait for server ready...".format(self.auth_config['OS_AUTH_URL']))
                        time.sleep(self.options.sleep)
                    else:
                        self.log.error(">>> Keystone error:\n{0}".format(e.message))
                        raise e
                ret_count -= 1
        return self._keystone
    @property
    def token(self):
        if self._token is None:
            self._token = self._keystone.auth_token
            #self.log.debug("Auth_token: '{0}'".format(self._token))
        #todo: Validate existing token
        return self._token

    @property
    def client(self):
        if self._client is None:
            self._client = q_client.Client(
                API_VER,
                endpoint_url=self.keystone.endpoints.find(
                                service_id=self.keystone.services.find(type='network').id
                             ).adminurl,
                token=self.token,
            )
        return self._client

    def _neutron_API_call(self, method, *args):
        ret_count = self.options.get('retries')
        while True:
            if ret_count <= 0:
                self.log.error("Q-server error: no more retries for connect to server.")
                return []
            try:
                rv = method (*args)
                break
            except Exception as e:
                errmsg = str(e.message).strip()
                if re.search(r"Connection\s+refused", errmsg, re.I) or\
                   re.search(r"Connection\s+timed\s+out", errmsg, re.I) or\
                   re.search(r"Lost\s+connection\s+to\s+MySQL\s+server", errmsg, re.I) or\
                   re.search(r"503\s+Service\s+Unavailable", errmsg, re.I) or\
                   re.search(r"No\s+route\s+to\s+host", errmsg, re.I):
                    self.log.info("Can't connect to {0}, wait for server ready...".format(self.keystone.service_catalog.url_for(service_type='network')))
                    time.sleep(self.options.sleep)
                else:
                    self.log.error("Neutron error:\n{0}".format(e.message))
                    raise e
            ret_count -= 1
        return rv

    def _get_agents(self, use_cache=True):
        return self._neutron_API_call(self.client.list_agents)['agents']

    def _list_networks_on_dhcp_agent(self, agent_id):
        return self._neutron_API_call(self.client.list_networks_on_dhcp_agent, agent_id)['networks']

    def _list_routers_on_l3_agent(self, agent_id):
        return self._neutron_API_call(self.client.list_routers_on_l3_agent, agent_id)['routers']

    def _add_network_to_dhcp_agent(self, agent_id, net_id):
        return self._neutron_API_call(self.client.add_network_to_dhcp_agent, agent_id, {"network_id": net_id})

    def _add_router_to_l3_agent(self, agent_id, router_id):
        return self._neutron_API_call(self.client.add_router_to_l3_agent, agent_id, {"router_id": router_id})

    def _remove_router_from_l3_agent(self, agent_id, router_id):
        return self._neutron_API_call(self.client.remove_router_from_l3_agent, agent_id, router_id)

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
        self.log.debug("_get_agents_by_type: end, {0} rv: {1}".format(from_cache, json.dumps(rv, indent=4)))
        return rv

    def __collect_namespaces_for_agent(self, agent):
        cmd = self.CMD__ip_netns_list[:]
        self.log.debug("Execute command '{0}'".format(' '.join(cmd)))
        process = subprocess.Popen(
            cmd,
            shell=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        rc = process.wait()
        if rc != 0:
            self.log.error("ERROR (rc={0}) while execution {1}".format(rc, ' '.join(cmd)))
            return []
        # filter namespaces by given agent type
        netns = []
        stdout = process.communicate()[0]
        for ns in StringIO.StringIO(stdout):
            ns = ns.strip()
            self.log.debug("Found network namespace '{0}'".format(ns))
            if ns.startswith("{0}-".format(self.NS_NAME_PREFIXES[agent])):
                netns.append(ns)
        return netns

    def __collect_ports_for_namespace(self, ns):
        cmd = self.CMD__ip_netns_exec[:]
        cmd.extend([ns, 'ip', 'l', 'show'])
        self.log.debug("Execute command '{0}'".format(' '.join(cmd)))
        process = subprocess.Popen(
            cmd,
            shell=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        rc = process.wait()
        if rc != 0:
            self.log.error("ERROR (rc={0}) while execution {1}".format(rc, ' '.join(cmd)))
            return []
        ports = []
        stdout = process.communicate()[0]
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
                process = subprocess.Popen(
                    cmd,
                    shell=False,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE
                )
                rc = process.wait()
                if rc != 0:
                    self.log.error("ERROR (rc={0}) while execution {1}".format(rc, ' '.join(cmd)))
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
                self.log.info("found alive DHCP agent: {0}".format(agent['id']))
                agents['alive'].append(agent)
            else:
                # dead agent
                self.log.info("found dead DHCP agent: {0}".format(agent['id']))
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
                    self.log.info("attach network {net} to DHCP agent {agent}".format(
                        net=net['id'],
                        agent=agents['alive'][0]['id']
                    ))
                    if not self.options.get('noop'):
                        self._add_network_to_dhcp_agent(agents['alive'][0]['id'], net['id'])
                        #if error:
                        #    return
            # remove dead agents if need (and if found alive agent)
            if self.options.get('remove-dead'):
                for agent in agents['dead']:
                    self.log.info("remove dead DHCP agent: {0}".format(agent['id']))
                    if not self.options.get('noop'):
                        self._neutron_API_call(self.client.delete_agent, agent['id'])
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
        self.log.debug("L3 agents in cluster: {ags}".format(ags=json.dumps(agents, indent=4)))
        self.log.debug("Routers, attached to dead L3 agents: {rr}".format(rr=json.dumps(dead_routers, indent=4)))
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
                    self._neutron_API_call(self.client.delete_agent, agent['id'])
            # move routers from dead to alive agent
            for rou in filter(lambda rr: not(rr[0]['id'] in lucky_ids), dead_routers):
                # self.log.info("unschedule router {rou} from L3 agent {agent}".format(
                #     rou=rou[0]['id'],
                #     agent=rou[1]
                # ))
                # if not self.options.get('noop'):
                #     self._remove_router_from_l3_agent(rou[1], rou[0]['id'])
                #     #todo: if error:
                # #
                self.log.info("schedule router {rou} to L3 agent {agent}".format(
                    rou=rou[0]['id'],
                    agent=agents['alive'][0]['id']
                ))
                if not self.options.get('noop'):
                    self._add_router_to_l3_agent(agents['alive'][0]['id'], rou[0]['id'])
                    #todo: if error:
        self.log.debug("_reschedule_agent_l3: end.")

    def _reschedule_agent(self, agent):
        self.log.debug("_reschedule_agents: start.")
        task = self.RESCHEDULING_CALLS.get(agent, None)
        if task:
            task (agent)
        self.log.debug("_reschedule_agents: end.")

    def do(self, agent):
        if self.options.get('cleanup-ports'):
            self._cleanup_ports(agent)
        if self.options.get('reschedule'):
            self._reschedule_agent(agent)
        # if self.options.get('remove-agent'):
        #     self._cleanup_agents(agent)

    def _test_healthy(self, agent_list, hostname):
        rv = False
        for agent in agent_list:
            if agent['host'] == hostname and agent['alive']:
                return True
        return rv

    def test_healthy(self, agent_type):
        rc = 9 # OCF_FAILED_MASTER, http://www.linux-ha.org/doc/dev-guides/_literal_ocf_failed_master_literal_9.html
        agentlist = self._get_agents_by_type(agent_type)
        for hostname in self.options.get('test-hostnames'):
            if self._test_healthy(agentlist, hostname):
                return 0
        return rc




if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Neutron network node cleaning tool.')
    parser.add_argument("-c", "--auth-config", dest="authconf", default="/root/openrc",
                      help="Authenticating config FILE", metavar="FILE")
    parser.add_argument("-t", "--auth-token", dest="auth-token", default=None,
                      help="Authenticating token (instead username/passwd)", metavar="TOKEN")
    parser.add_argument("-u", "--admin-auth-url", dest="admin-auth-url", default=None,
                      help="Authenticating URL (admin)", metavar="URL")
    parser.add_argument("--retries", dest="retries", type=int, default=50,
                      help="try NN retries for API call", metavar="NN")
    parser.add_argument("--sleep", dest="sleep", type=int, default=2,
                      help="sleep seconds between retries", metavar="SEC")
    parser.add_argument("-a", "--agent", dest="agent", action="append",
                      help="specyfy agents for cleaning", required=True)
    parser.add_argument("--cleanup-ports", dest="cleanup-ports", action="store_true", default=False,
                      help="cleanup ports for given agents on this node")
    parser.add_argument("--activeonly", dest="activeonly", action="store_true", default=False,
                      help="cleanup only active ports")
    parser.add_argument("--reschedule", dest="reschedule", action="store_true", default=False,
                      help="reschedule given agents")
    parser.add_argument("--remove-dead", dest="remove-dead", action="store_true", default=False,
                      help="remove dead agents while rescheduling")
    parser.add_argument("--test-alive-for-hostname", dest="test-hostnames", action="append",
                      help="testing agent's healthy for given hostname")
    parser.add_argument("--external-bridge", dest="external-bridge", default="br-ex",
                      help="external bridge name", metavar="IFACE")
    parser.add_argument("--integration-bridge", dest="integration-bridge", default="br-int",
                      help="integration bridge name", metavar="IFACE")
    parser.add_argument("-l", "--log", dest="log", action="store",
                      help="log file or logging.conf location")
    parser.add_argument("--noop", dest="noop", action="store_true", default=False,
                      help="do not execute, print to log instead")
    parser.add_argument("--debug", dest="debug", action="store_true", default=False,
                      help="debug")
    args = parser.parse_args()
    # if len(args) != 1:
    #     parser.error("incorrect number of arguments")
    #     parser.print_help()    args = parser.parse_args()

    #setup logging
    if args.debug:
        _log_level = logging.DEBUG
    else:
        _log_level = logging.INFO
    if not args.log:
        # log config or file not given -- log to console
        LOG = logging.getLogger(LOG_NAME)   # do not move to UP of file
        _log_handler = logging.StreamHandler(sys.stdout)
        _log_handler.setFormatter(logging.Formatter("%(asctime)s - %(levelname)s - %(message)s"))
        LOG.addHandler(_log_handler)
        LOG.setLevel(_log_level)
    elif args.log.split(os.sep)[-1] == 'logging.conf':
        # setup logging by external file
        import logging.config
        logging.config.fileConfig(args.log)
        LOG = logging.getLogger(LOG_NAME)   # do not move to UP of file
    else:
        # log to given file
        LOG = logging.getLogger(LOG_NAME)   # do not move to UP of file
        LOG.addHandler(logging.handlers.WatchedFileHandler(args.log))
        LOG.setLevel(_log_level)

    LOG.info("Started: {0}".format(' '.join(sys.argv)))
    cleaner = NeutronCleaner(get_authconfig(args.authconf), options=vars(args), log=LOG)
    rc = 0
    if vars(args).get('test-hostnames'):
        rc = cleaner.test_healthy(args.agent[0])
    else:
        for i in args.agent:
            cleaner.do(i)
    LOG.debug("End.")
    sys.exit(rc)
#
###
