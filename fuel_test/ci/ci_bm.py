import os
from fuel_test.ci.ci_base import CiBase
from fuel_test.node_roles import NodeRoles
from fuel_test.settings import CONTROLLERS, COMPUTES,\
    STORAGES, PROXIES


class CiBM(CiBase):
    def define(self):
        pass

    def node_roles(self):
        return NodeRoles(
            master_names=['master'],
            cobbler_names=['fuel-cobbler'],
            controller_names=['fuel-controller-%02d' % x for x in range(1, 1 + CONTROLLERS)],
            compute_names=['fuel-compute-%02d' % x for x in range(1, 1 + COMPUTES)],
            storage_names=['fuel-swift-%02d' % x for x in range(1, 1 + STORAGES)],
            proxy_names=['fuel-swiftproxy-%02d' % x for x in range(1, 1 + PROXIES)],
            quantum_names=['fuel-quantum'],
            stomp_names=['fuel-mcollective']
        )

    def env_name(self):
        return os.environ.get('ENV_NAME', 'cobbler')

    def describe_environment(self):
        """
        :rtype : Environment
        """

    def client_nodes(self):
        return self.nodes().controllers + self.nodes().computes + self.nodes().storages + self.nodes().proxies + self.nodes().quantums

    def setup_environment(self):
        pass