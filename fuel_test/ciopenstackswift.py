from devops.model import Environment, Network
from ci import Ci
from settings import storages,proxies,controllers,computes

class CiOpenStackSwift(Ci):
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
        for node_name in controllers:
            client = self.describe_node(node_name, [internal, private, public])
            environment.nodes.append(client)
        for node_name in computes:
            client = self.describe_node(node_name, [internal, private, public])
            environment.nodes.append(client)
        for node_name in storages:
            client = self.describe_node(node_name, [internal, private, public])
            environment.nodes.append(client)
        for node_name in proxies:
            client = self.describe_node(node_name, [internal, private, public])
            environment.nodes.append(client)
        return environment

