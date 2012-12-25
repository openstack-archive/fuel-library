import logging
from time import sleep
from devops.helpers import wait, tcp_ping, ssh
from devops.model import Environment, Network
import os
from fuel_test.ci.ci_base import CiBase
from fuel_test.helpers import sign_all_node_certificates, write_static_ip, execute
from fuel_test.node_roles import NodeRoles
from fuel_test.settings import COBBLER_CONTROLLERS, COBBLER_COMPUTES, EMPTY_SNAPSHOT

class CiCobbler(CiBase):
    def node_roles(self):
        return NodeRoles(
            cobbler_names=['fuel-cobbler'],
            controller_names=['fuel-controller-%02d' % x for x in
                              range(1, 1 + COBBLER_CONTROLLERS)],
            compute_names=['fuel-compute-%02d' % x for x in range(
                COBBLER_CONTROLLERS + 1,
                COBBLER_CONTROLLERS + 1 + COBBLER_COMPUTES)],
            stomp_names=['fuel-mcollective']
        )

    def env_name(self):
        return os.environ.get('ENV_NAME', 'cobbler')

    def describe_environment(self):
        environment = Environment(self.environment_name)
        public = Network(name='public', dhcp_server=True)
        environment.networks.append(public)
        internal = Network(name='internal', dhcp_server=False)
        environment.networks.append(internal)
        private = Network(name='private', dhcp_server=False)
        environment.networks.append(private)
        master_node = self.describe_node('master', [public, internal, private])
        environment.nodes.append(master_node)
        for node_name in self.node_roles().cobbler_names:
            client = self.describe_node(node_name, [public, internal, private])
            environment.nodes.append(client)
        for node_name in self.node_roles().stomp_names:
            client = self.describe_node(node_name, [public, internal, private])
            environment.nodes.append(client)
        for node_name in self.node_roles().controller_names:
            client = self.describe_empty_node(node_name,
                [public, internal, private])
            environment.nodes.append(client)
        for node_name in self.node_roles().compute_names:
            client = self.describe_empty_node(
                node_name, [public, internal, private], memory=1024)
            environment.nodes.append(client)
        return environment

    def get_start_nodes(self):
        return [self.environment.node['master']] + self.nodes().cobblers + self.nodes().stomps


    def setup_environment(self):
        self.environment = self.make_vms()
        master_node = self.environment.node['master']
        logging.info("Starting test nodes ...")
        start_nodes = self.get_start_nodes()
        for node in start_nodes:
            node.start()
        for node in start_nodes:
            logging.info("Waiting ssh... %s" % node.ip_address_by_network['public'])
            wait(lambda: tcp_ping(node.ip_address_by_network['public'], 22),
                timeout=1800)
        gateway = self.environment.network['internal'].ip_addresses[1]
        net_mask = '255.255.255.0'
        for node in start_nodes:
            remote = ssh(node.ip_address_by_network['public'], username='root',
                password='r00tme')
            execute(remote, 'ifdown eth1')
            write_static_ip(remote, node.ip_address_by_network['internal'],
                net_mask, gateway)
            execute(remote, 'ifup eth1')
        master_remote = ssh(
            master_node.ip_address_by_network['public'], username='root',
            password='r00tme')
        self.rename_nodes(start_nodes)
        self.setup_master_node(master_remote, self.environment.nodes)
        self.setup_agent_nodes(start_nodes)
        sleep(5)
        sign_all_node_certificates(master_remote)
        sleep(5)
        for node in self.environment.nodes:
            logging.info("Creating snapshot %s" % EMPTY_SNAPSHOT)
            node.save_snapshot(EMPTY_SNAPSHOT)
            logging.info("Test node is ready at %s" % node.ip_address_by_network['internal'])
