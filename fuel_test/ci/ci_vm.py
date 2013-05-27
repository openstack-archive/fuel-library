from ipaddr import IPNetwork

import os
from fuel_test.ci.ci_base import CiBase
from fuel_test.helpers import add_nmap, dhcp_checksum

from fuel_test.node_roles import NodeRoles
from fuel_test.settings import CONTROLLERS, COMPUTES, \
    STORAGES, PROXIES, \
    EMPTY_SNAPSHOT, POOLS, INTERFACE_ORDER, FORWARDING, DHCP, ISO_IMAGE


class CiVM(CiBase):
    def define(self):
        self._environment.define()

    def __init__(self):
        super(CiVM, self).__init__()

    def node_roles(self):
        return NodeRoles(
            master_names=['master'],
            controller_names=['fuel-controller-%02d' % x for x in range(1, 1 + CONTROLLERS)],
            compute_names=['fuel-compute-%02d' % x for x in range(1, 1 + COMPUTES)],
            storage_names=['fuel-swift-%02d' % x for x in range(1, 1 + STORAGES)],
            proxy_names=['fuel-swiftproxy-%02d' % x for x in range(1, 1 + PROXIES)],
            quantum_names=['fuel-quantum'],
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
            ip_networks = [IPNetwork(x) for x in POOLS.get(name)[0].split(',')]
            new_prefix = int(POOLS.get(name)[1])
            pool = self.manager.create_network_pool(networks=ip_networks, prefix=int(new_prefix))
            networks.append(self.manager.network_create(name=name, environment=environment, pool=pool,
                forward=FORWARDING.get(name), has_dhcp_server=DHCP.get(name)))

        for name in self.node_roles().master_names:
            self.describe_master_node(name, networks)

        for name in self.node_roles().compute_names:
            self.describe_empty_node(name, networks, memory=2048)

        for name in self.node_roles().controller_names + self.node_roles().storage_names + self.node_roles().quantum_names + self.node_roles().proxy_names:
            self.describe_empty_node(name, networks)

        return environment

    def get_startup_nodes(self):
        return self.nodes().masters

    def client_nodes(self):
        return self.nodes().controllers + self.nodes().computes + self.nodes().storages + self.nodes().proxies + self.nodes().quantums

    def setup_environment(self):
        master_node = self.nodes().masters[0]
        master_node.disk_devices.get(device='cdrom').volume.upload(ISO_IMAGE)
        start_nodes = self.get_startup_nodes()
        self.environment().start(start_nodes)
        for node in start_nodes:
            node.await('public', timeout=600)
        master_remote = master_node.remote('public', login='root', password='r00tme')
        add_nmap(master_remote)
        dhcp_checksum(master_remote)
        self.environment().snapshot(EMPTY_SNAPSHOT)
