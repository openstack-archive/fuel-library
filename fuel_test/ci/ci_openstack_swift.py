from devops.model import Environment, Network
import os
from fuel_test.ci.ci_base import CiBase
from fuel_test.node_roles import NodeRoles


class CiOpenStackSwift(CiBase):
    def node_roles(self):
        return NodeRoles(
            controller_names=['fuel-01', 'fuel-02'],
            compute_names=['fuel-03', 'fuel-04'],
            storage_names=['fuel-05', 'fuel-06', 'fuel-07'],
            proxy_names=['fuel-08'],
        )


    def env_name(self):
        return os.environ.get('ENV_NAME', 'recipes-swift')

    def describe_environment(self):
        environment = Environment(self.environment_name)
        internal = Network(name='internal', dhcp_server=True)
        environment.networks.append(internal)
        private = Network(name='private', dhcp_server=False)
        environment.networks.append(private)
        public = Network(name='public', dhcp_server=True)
        environment.networks.append(public)
        master = self.describe_node('master', [internal, private, public])
        environment.nodes.append(master)
        for node_name in self.node_roles().controller_names:
            client = self.describe_node(node_name, [internal, private, public])
            environment.nodes.append(client)
        for node_name in self.node_roles().compute_names:
            client = self.describe_node(
                node_name, [internal, private, public], memory=4096)
            environment.nodes.append(client)
        for node_name in self.node_roles().storage_names:
            client = self.describe_node(node_name, [internal, private, public])
            environment.nodes.append(client)
        for node_name in self.node_roles().proxy_names:
            client = self.describe_node(node_name, [internal, private, public])
            environment.nodes.append(client)
        return environment

