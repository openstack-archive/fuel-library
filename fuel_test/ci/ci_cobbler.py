import logging
from time import sleep
from devops.helpers import wait, tcp_ping, ssh
from devops.model import Environment, Network
import os
from fuel_test.ci.ci_base import CiBase
from fuel_test.helpers import sign_all_node_certificates, write_static_ip, execute
from fuel_test.node_roles import NodeRoles

class CiCobbler(CiBase):
    def node_roles(self):
        return NodeRoles(
            cobbler_names=['fuel-cobbler'],
            controller_names=['fuel-01', 'fuel-02'],
            compute_names=['fuel-03', 'fuel-04']
        )

    def env_name(self):
        return os.environ.get('ENV_NAME', 'cobbler')

    def describe_environment(self):
        environment = Environment(self.environment_name)
        internal = Network(name='internal', dhcp_server=False)
        environment.networks.append(internal)
        private = Network(name='private', dhcp_server=False)
        environment.networks.append(private)
        public = Network(name='public', dhcp_server=True)
        environment.networks.append(public)
        master = self.describe_node('master', [internal, private, public])
        environment.nodes.append(master)
        for node_name in self.node_roles().cobbler_names:
            client = self.describe_node(node_name, [internal, private, public])
            environment.nodes.append(client)
        for node_name in self.node_roles().controller_names:
            client = self.describe_node(node_name, [internal, private, public])
            environment.nodes.append(client)
        for node_name in self.node_roles().compute_names:
            client = self.describe_node(
                node_name, [internal, private, public], memory=4096)
            environment.nodes.append(client)
        return environment

    def setup_environment(self):
        environment = self.make_vms()
        self.environment = environment

        logging.info("Starting test nodes ...")
        master_node = environment.node['master']
        start_nodes = [master_node] + self.nodes().cobblers
        for node in start_nodes:
            node.start()
        for node in start_nodes:
            logging.info("Waiting ssh... %s" % node.ip_address)
            wait(lambda: tcp_ping(node.ip_address_by_network['public'], 22),
                timeout=1800)

        addresses_iter = iter(self.environment.network['internal'].ip_addresses)
        addresses_iter.next()
        gateway = addresses_iter.next()
        net_mask = '255.255.255.0'
        for node in start_nodes:
            remote = ssh(node.ip_address_by_network['public'], username='root',
                password='r00tme')
            address = addresses_iter.next()
            execute(remote, 'ifdown eth0')
            write_static_ip(remote, address, net_mask, gateway)
            node.interfaces[0].ip_addresses = address
            execute(remote, 'ifup eth0')

        master_remote = ssh(master_node.ip_address, username='root',
            password='r00tme')
        self.rename_nodes(start_nodes)
        self.setup_master_node(master_remote, environment.nodes)
        self.setup_agent_nodes(self.nodes().cobblers)
        sleep(5)
        sign_all_node_certificates(master_remote)
        sleep(5)
        for node in environment.nodes:
            logging.info("Creating snapshot 'empty'")
            node.save_snapshot('empty')
            logging.info("Test node is ready at %s" % node.ip_address)
