from devops.model import Environment, Network
import os
from ci.ci_base import CiBase


class CiOpenStackSwift(CiBase):

    controllers = ['fuel-01', 'fuel-02']
    computes = ['fuel-03', 'fuel-04']
    storages = ['fuel-05', 'fuel-06', 'fuel-07']
    proxies = ['fuel-08']

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
        for node_name in self.controllers:
            client = self.describe_node(node_name, [internal, private, public])
            environment.nodes.append(client)
        for node_name in self.computes:
            client = self.describe_node(
                node_name, [internal, private, public], memory=4096)
            environment.nodes.append(client)
        for node_name in self.storages:
            client = self.describe_node(node_name, [internal, private, public])
            environment.nodes.append(client)
        for node_name in self.proxies:
            client = self.describe_node(node_name, [internal, private, public])
            environment.nodes.append(client)
        return environment

