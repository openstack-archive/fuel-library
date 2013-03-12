import logging
from time import sleep
from ipaddr import IPNetwork
from devops.manager import Manager
import os
from fuel_test.ci.ci_base import CiBase
from fuel_test.node_roles import NodeRoles
from fuel_test.settings import CONTROLLERS, COMPUTES,\
    STORAGES, PROXIES,\
    EMPTY_SNAPSHOT, POOLS, INTERFACE_ORDER, ROUTED_INTERFACE, BASE_IMAGE, ISO


class CiVM(CiBase):

    def get_or_create(self):
        try:
            return self.manager.environment_get(self.env_name())
        except:
            return super(CiVM, self).get_or_create()

    def __init__(self):
        super(CiVM, self).__init__()
        self.manager = Manager()
        self.base_image = self.manager.volume_get_predefined(BASE_IMAGE)

    def node_roles(self):
        return NodeRoles(
            master_names=['master'],
            cobbler_names=['fuel-cobbler'],
            controller_names=['fuel-controller-%02d' % x for x in
                              range(1, 1 + CONTROLLERS)],
            compute_names=['fuel-compute-%02d' % x for x in range(
                1, 1 + COMPUTES)],
            storage_names=['fuel-swift-%02d' % x for x in range(
                1, 1 + STORAGES)],
            proxy_names=['fuel-swiftproxy-%02d' % x for x in range(
                1, 1 + PROXIES)],
            quantum_names=['fuel-quantum'],
            stomp_names=['fuel-mcollective']
        )

    def env_name(self):
        return os.environ.get('ENV_NAME', 'cobbler')

    def describe_environment(self):
        """
        :rtype : Environment
        """
        environment = self.manager.environment_create(self.env_name())
        networks = []
        for name in INTERFACE_ORDER:
            network = IPNetwork(POOLS.get(name)[0])
            new_prefix = int(POOLS.get(name)[1])
            pool = self.manager.create_network_pool(
                networks=[network], prefix=int(new_prefix))
            networks.append(self.manager.network_create(
                name=name, environment=environment, pool=pool,
                forward='route' if name==ROUTED_INTERFACE else 'nat'))
        for name in self.node_roles().master_names:
            self.describe_master_node(name, networks)
        for name in self.node_roles().cobbler_names + self.node_roles().stomp_names:
            self.describe_node(name, networks)
        for name in self.node_roles().compute_names:
            self.describe_empty_node(name, networks, memory=2048)
        for name in self.node_roles().controller_names + self.node_roles().storage_names + self.node_roles().quantum_names + self.node_roles().proxy_names:
            self.describe_empty_node(name, networks)
        return environment

    def get_startup_nodes(self):
        return self.nodes().masters + self.nodes().cobblers + self.nodes().stomps

    def client_nodes(self):
        return self.nodes().controllers + self.nodes().computes + self.nodes().storages + self.nodes().proxies + self.nodes().quantums


    def add_empty_volume(self, node, name):
        self.manager.node_attach_volume(
            node=node,
            volume=self.manager.volume_create(
                name=name, capacity=20 * 1024 * 1024 * 1024,
                environment=self.environment()))

    def add_node(self, memory, name):
        return self.manager.node_create(
            name=name,
            memory=memory,
            environment=self.environment())

    def describe_node(self, name, networks, memory=1024):
        node = self.add_node(memory, name)
        for network in networks:
            self.manager.interface_create(network, node=node)
        self.manager.node_attach_volume(
            node=node,
            volume=self.manager.volume_create_child(
                name=name + '-system', backing_store=self.base_image,
                environment=self.environment()))
        self.add_empty_volume(node, name + '-cinder')
        return node

    def describe_master_node(self, name, networks, memory=1024):
        node = self.add_node(memory, name)
        for network in networks:
            self.manager.interface_create(network, node=node)
        self.add_empty_volume(node, name + '-system')
        self.manager.node_attach_volume(node, self.manager.volume_get_predefined(
            ISO), device='cdrom', bus='sata')
        return node

    def describe_empty_node(self, name, networks, memory=1024):
        node = self.add_node(memory, name)
        for network in networks:
            self.manager.interface_create(network, node=node)
        self.add_empty_volume(node, name + '-system')
        self.add_empty_volume(node, name + '-cinder')
        return node

    def setup_environment(self):
        master_node = self.nodes().masters[0]
        logging.info("Starting test nodes ...")
        start_nodes = self.get_startup_nodes()
        self.environment().start(start_nodes)
        for node in start_nodes:
            node.await('public')
        master_remote = master_node.remote('public', login='root',
            password='r00tme')
        self.rename_nodes(start_nodes)
        self.setup_master_node(master_remote, self.environment().nodes)
        self.setup_agent_nodes(start_nodes)
        sleep(10)
        self.environment().snapshot(EMPTY_SNAPSHOT)
