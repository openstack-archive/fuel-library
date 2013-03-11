class Environment(object):
    def __init__(self, nodes, networks):
        super(Environment, self).__init__()
        self.nodes = nodes
        self.networks = networks

    def get_node_by_name(self, name):
        return filter(lambda x : x.name == name, self.nodes)[0]

    def network_by_name(self, name):
        return filter(lambda x : x.name == name, self.networks)[0]

class Node(object):
    def __init__(self, name, internal_ip, public_ip, private_ip):
        super(Node, self).__init__()
        self.internal_ip = internal_ip
        self.name = name
        self.public_ip = public_ip
        self.private_ip = private_ip

class Network(object):
    def __init__(self, network_ip):
        super(Network, self).__init__()
        self.network_ip = network_ip

