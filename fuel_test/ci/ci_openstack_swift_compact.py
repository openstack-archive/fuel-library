from devops.model import Environment, Network
import os
from ci.ci_base import CiBase


class CiOpenStackSwiftCompact(CiBase):

    controllers = ['fuel-01', 'fuel-02','fuel-03']
    computes = ['fuel-04', 'fuel-05']

    def env_name(self):
        return os.environ.get('ENV_NAME', 'recipes-swift-compact')

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
        for node_name in self.controllers:
            client = self.describe_node(node_name, [internal, private, public])
            environment.nodes.append(client)
        for node_name in self.computes:
            client = self.describe_node(
                node_name, [internal, private, public], memory=4096)
            environment.nodes.append(client)
        return environment




