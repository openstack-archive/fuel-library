from devops.model import Environment, Network
import os
from fuel_test.ci.ci_base import CiBase
from fuel_test.node_roles import NodeRoles


class CiOpenStackSwiftCompact(CiBase):
    def node_roles(self):
        return NodeRoles(
            controller_names=['fuel-01', 'fuel-02', 'fuel-03'],
            compute_names=['fuel-04', 'fuel-05']
        )

    def env_name(self):
        return os.environ.get('ENV_NAME', 'recipes-swift-compact')

    def describe_environment(self):
        environment = Environment(self.environment_name)
        public = Network(name='public', dhcp_server=True)
        environment.networks.append(public)
        internal = Network(name='internal', dhcp_server=True)
        environment.networks.append(internal)
        private = Network(name='private', dhcp_server=False)
        environment.networks.append(private)
        master = self.describe_node('master', [internal, private, public])
        environment.nodes.append(master)
        for node_name in self.node_roles().controller_names:
            client = self.describe_node(node_name, [internal, private, public])
            environment.nodes.append(client)
        for node_name in self.node_roles().compute_names:
            client = self.describe_node(
                node_name, [internal, private, public], memory=4096)
            environment.nodes.append(client)
        return environment




