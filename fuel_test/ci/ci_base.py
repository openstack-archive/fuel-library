import logging
from abc import abstractproperty, abstractmethod
from devops.helpers.helpers import _get_file_size
from ipaddr import IPNetwork
from fuel_test.helpers import  write_config, change_host_name, request_cerificate, setup_puppet_client, setup_puppet_master, add_nmap, switch_off_ip_tables, add_to_hosts
from fuel_test.node_roles import NodeRoles, Nodes
from fuel_test.settings import EMPTY_SNAPSHOT, ISO_IMAGE, DEFAULT_RAM_SIZE
from fuel_test.root import root
from fuel_test.helpers import load
from devops.manager import Manager

class CiBase(object):
    def __init__(self):
        self._environment = None
        self.manager = Manager()
        # self.base_image = self.manager.volume_get_predefined(BASE_IMAGE)

    def get_or_create(self):
        try:
            return self.manager.environment_get(self.env_name())
        except:
            self._environment = self.describe_environment()
            self._environment.define()
            return self._environment

    def get_empty_state(self):
        if self.environment().has_snapshot(EMPTY_SNAPSHOT):
            self.environment().revert(EMPTY_SNAPSHOT)
        else:
            self.setup_environment()

    def environment(self):
        """
        :rtype : devops.models.Environment
        """
        self._environment = self._environment or self.get_or_create()
        return self._environment

    @abstractproperty
    def env_name(self):
        """
        :rtype : string
        """
        pass

    @abstractmethod
    def define(self):
        """
        :rtype : devops.models.Environment
        """
        pass

    @abstractmethod
    def describe_environment(self):
        """
        :rtype : devops.models.Environment
        """
        pass

    @abstractproperty
    def node_roles(self):
        """
        :rtype : NodeRoles
        """
        pass

    def add_empty_volume(self, node, name, capacity=20 * 1024 * 1024 * 1024, format="qcow2", device="disk", bus='virtio'):
        self.manager.node_attach_volume(
            node=node,
            device=device,
            bus=bus,
            volume=self.manager.volume_create(
                name=name, capacity=capacity, format=format,
                environment=self.environment()))

    def add_node(self, memory, name, boot=None):
        return self.manager.node_create(
            name=name,
            memory=memory,
            environment=self.environment())

    def describe_master_node(self, name, networks, memory=DEFAULT_RAM_SIZE):
        node = self.add_node(memory, name, boot=['cdrom', 'hd'])
        for network in networks:
            self.manager.interface_create(network, node=node)
        self.add_empty_volume(node, name + '-system')
        self.add_empty_volume(node, name + '-iso', capacity=_get_file_size(ISO_IMAGE), format='raw', device='cdrom', bus='ide')
        return node

    def describe_empty_node(self, name, networks, memory=DEFAULT_RAM_SIZE):
        node = self.add_node(memory, name)
        for network in networks:
            self.manager.interface_create(network, node=node)
        self.add_empty_volume(node, name + '-system')
        self.add_empty_volume(node, name + '-cinder')
        return node

    def nodes(self):
        return Nodes(self.environment(), self.node_roles())

    def add_nodes_to_hosts(self, remote, nodes):
        for node in nodes:
            add_to_hosts(remote,
                node.get_ip_address_by_network_name('internal'), node.name,
                node.name + '.localdomain')

    def setup_master_node(self, master_remote, nodes):
        setup_puppet_master(master_remote)
        add_nmap(master_remote)
        switch_off_ip_tables(master_remote)
        self.add_nodes_to_hosts(master_remote, nodes)

    def setup_agent_nodes(self, nodes):
        agent_config = load(
            root('fuel_test', 'config', 'puppet.agent.config'))
        for node in nodes:
            if node.name != 'master':
                remote = node.remote('public', login='root',
                    password='r00tme')
                self.add_nodes_to_hosts(remote, self.environment().nodes)
                setup_puppet_client(remote)
                write_config(remote, '/etc/puppet/puppet.conf', agent_config)
                request_cerificate(remote)

    def rename_nodes(self, nodes):
        for node in nodes:
            remote = node.remote('public', login='root', password='r00tme')
            change_host_name(remote, node.name,
                node.name + '.localdomain')
            logging.info("Renamed %s" % node.name)

    @abstractmethod
    def setup_environment(self):
        """
        :rtype : None
        """
        pass

    def internal_virtual_ip(self):
        return str(IPNetwork(
            self.environment().network_by_name('internal').ip_network)[-2])

    def floating_network(self):
        prefix = IPNetwork(self.environment().network_by_name('public').ip_network).prefixlen
        return str(
            IPNetwork(self.environment().network_by_name('public').ip_network).subnet(new_prefix=prefix + 2)[-1])

    def public_virtual_ip(self):
        prefix = IPNetwork(self.environment().network_by_name('public').ip_network).prefixlen
        return str(        
            IPNetwork(self.environment().network_by_name('public').ip_network).subnet(new_prefix=prefix + 2)[-2][
            -1])

    def public_router(self):
        return str(
            IPNetwork(
                self.environment().network_by_name('public').ip_network)[1])

    def internal_router(self):
        return str(
            IPNetwork(
                self.environment().network_by_name('internal').ip_network)[1])

    def fixed_network(self):
        return str(
            IPNetwork(self.environment().network_by_name('private').ip_network).subnet(
                new_prefix=27)[0])

    def internal_network(self):
        return str(IPNetwork(self.environment().network_by_name('internal').ip_network))

    def internal_net_mask(self):
        return str(IPNetwork(self.environment().network_by_name('internal').ip_network).netmask)

    def public_net_mask(self):
        return str(IPNetwork(self.environment().network_by_name('public').ip_network).netmask)

    def public_network(self):
        return str(IPNetwork(self.environment().network_by_name('public').ip_network))
