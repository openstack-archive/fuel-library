import logging
from time import sleep
from ipaddr import IPNetwork

import os
from fuel_test.ci.ci_base import CiBase
from fuel_test.node_roles import NodeRoles
from fuel_test.settings import CONTROLLERS, COMPUTES,\
    STORAGES, PROXIES,\
    EMPTY_SNAPSHOT, POOLS, INTERFACE_ORDER, ROUTED_INTERFACE


class CiCobbler(CiBase):
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
            ip_networks = [ IPNetwork(x) for x in POOLS.get(name)[0].split(',')]
            new_prefix = int(POOLS.get(name)[1])
            pool = self.manager.create_network_pool(
                networks=ip_networks, prefix=int(new_prefix))
            networks.append(self.manager.network_create(
                name=name, environment=environment, pool=pool,
                forward='route' if name==ROUTED_INTERFACE else 'nat'))
        for name in self.node_roles().master_names + self.node_roles().cobbler_names + self.node_roles().stomp_names:
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
