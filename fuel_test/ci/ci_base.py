import logging
from time import sleep
import traceback
from abc import abstractproperty, abstractmethod
import devops
from devops.model import Node, Disk, Interface, Environment
from devops.helpers import tcp_ping, wait, ssh
from fuel_test.helpers import  write_config, sign_all_node_certificates, change_host_name, request_cerificate, setup_puppet_client_yum, setup_puppet_master_yum, add_nmap_yum, switch_off_ip_tables, start_puppet_master, add_to_hosts
from fuel_test.node_roles import NodeRoles, Nodes
from fuel_test.settings import BASE_IMAGE
from fuel_test.root import root
from fuel_test.helpers import load


class CiBase(object):
    @abstractproperty
    def env_name(self):
        """
        :rtype : string
        """
        pass

    @abstractmethod
    def describe_environment(self):
        """
        :rtype : Environment
        """
        pass

    @abstractproperty
    def node_roles(self):
        """
        :rtype : NodeRoles
        """
        pass

    def nodes(self, environment=None):
        return Nodes(environment or self.environment, self.node_roles())

    def __init__(self):
        self.base_image = BASE_IMAGE
        self.environment = None
        self.environment_name = self.env_name()
        try:
            self.environment = devops.load(self.environment_name)
            logging.info("Successfully loaded existing environment")
        except Exception, e:
            logging.info(
                "Failed to load existing %s environment: " % self.environment_name + str(
                    e) + "\n" + traceback.format_exc())
            pass

    def get_environment(self):
        return self.environment

    def get_environment_or_create(self):
        if self.get_environment():
            return self.get_environment()
        self.setup_environment()
        return self.environment

    def describe_node(self, name, networks, memory=1024):
        node = Node(name)
        node.memory = memory
        node.vnc = True
        for network in networks:
            node.interfaces.append(Interface(network))
            #        node.bridged_interfaces.append(BridgedInterface('br0'))
        node.disks.append(Disk(base_image=self.base_image, format='qcow2'))
        node.boot = ['disk']
        return node

    def describe_empty_node(self, name, networks, memory=1024):
        node = Node(name)
        node.memory = memory
        node.vnc = True
        for network in networks:
            node.interfaces.append(Interface(network))
            #        node.bridged_interfaces.append(BridgedInterface('br0'))
        node.disks.append(Disk(size=8589934592, format='qcow2'))
        node.boot = ['disk']
        return node

    def add_nodes_to_hosts(self, remote, nodes):
        for node in nodes:
            add_to_hosts(remote, node.ip_address, node.name,
                node.name + '.mirantis.com')

    def setup_master_node(self, master_remote, nodes):
        setup_puppet_master_yum(master_remote)
        add_nmap_yum(master_remote)
        switch_off_ip_tables(master_remote)
        master_config = load(
            root('fuel', 'fuel_test', 'config', 'puppet.master.config'))
        write_config(master_remote, '/etc/puppet/puppet.conf', master_config)
        start_puppet_master(master_remote)
        self.add_nodes_to_hosts(master_remote, nodes)

    def setup_agent_nodes(self, nodes):
        agent_config = load(
            root('fuel', 'fuel_test', 'config', 'puppet.agent.config'))
        for node in nodes:
            if node.name != 'master':
                remote = ssh(
                    node.ip_address, username='root',
                    password='r00tme')
                self.add_nodes_to_hosts(remote, nodes)
                setup_puppet_client_yum(remote)
                write_config(remote, '/etc/puppet/puppet.conf', agent_config)
                request_cerificate(remote)

    def reserve_static_addresses(self, environment):
        #    todo make devops to reserve ips for nodes in static networks
        pass

    def make_vms(self):
        if not self.base_image:
            raise Exception(
                "Base image path is missing while trying to build %s environment" % self.environment_name)
        logging.info("Building %s environment" % self.environment_name)
        environment = self.describe_environment()
        #       todo environment should be saved before build
        devops.build(environment)
        self.reserve_static_addresses(environment)
        devops.save(environment)
        logging.info("Environment has been saved")
        return environment

    def rename_nodes(self, nodes):
        for node in nodes:
            remote = ssh(node.ip_address, username='root', password='r00tme')
            change_host_name(remote, node.name, node.name + '.mirantis.com')
            logging.info("Renamed %s" % node.name)

    def setup_environment(self):
        environment = self.make_vms()
        self.environment = environment

        logging.info("Starting test nodes ...")
        for node in environment.nodes:
            node.start()
        for node in environment.nodes:
            logging.info("Waiting ssh... %s" % node.ip_address)
            wait(lambda: tcp_ping(node.ip_address, 22), timeout=1800)
        self.rename_nodes(environment.nodes)
        master_node = environment.node['master']
        master_remote = ssh(master_node.ip_address, username='root',
            password='r00tme')
        self.setup_master_node(master_remote, environment.nodes)
        self.setup_agent_nodes(environment.nodes)
        sleep(5)
        sign_all_node_certificates(master_remote)
        sleep(5)
        for node in environment.nodes:
            logging.info("Creating snapshot 'empty'")
            node.save_snapshot('empty')
            logging.info("Test node is ready at %s" % node.ip_address)

    def destroy_environment(self):
        if self.environment:
            devops.destroy(self.environment)

    def get_internal_virtual_ip(self):
        return self.environment.network['internal'].ip_addresses[-3]

    def get_public_virtual_ip(self):
        return self.environment.network['public'].ip_addresses[-3]

    def get_floating_network(self):
        return '.'.join(
            str(self.environment.network['public'].ip_addresses[-1]).split(
                '.')[:-1]) + '.128/27'

    def get_fixed_network(self):
        return '.'.join(
            str(self.environment.network['private'].ip_addresses[-1]).split(
                '.')[:-1]) + '.128/27'

    def get_internal_network(self):
        network = self.environment.network['internal']
        return str(network.ip_addresses[1]) + '/' + str(
            network.ip_addresses.prefixlen)


