from devops.model import Environment, Network
import os
from ci.ci_base import CiBase

class CiSwift(CiBase):

    storages = ['fuel-05', 'fuel-06', 'fuel-07']
    proxies = ['fuel-08']
    keystones = ['keystone']

    def env_name(self):
        return os.environ.get('ENV_NAME', 'swift')

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
        for node_name in self.keystones:
            client = self.describe_node(node_name, [internal, private, public])
            environment.nodes.append(client)
        for node_name in self.storages:
            client = self.describe_node(node_name, [internal, private, public])
            environment.nodes.append(client)
        for node_name in self.proxies:
            client = self.describe_node(node_name, [internal, private, public])
            environment.nodes.append(client)
        return environment

