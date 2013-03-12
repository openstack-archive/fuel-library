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
    def __init__(self, name, internal_ip, internal_mac, public_ip, public_mac, private_ip, private_mac):
        super(Node, self).__init__()
        self.internal_ip = internal_ip
        self.name = name
        self.public_ip = public_ip
        self.private_ip = private_ip
        self.private_mac = private_mac
        self.internal_mac = internal_mac
        self.public_mac = public_mac

    def get_ip_address_by_network_name(self, name):
        if name == 'internal': return self.internal_ip
        if name == 'public': return self.public_ip
        if name == 'private': return self.private_ip

    @property
    def interfaces(self):
        return [Network('internal_mac')]

class Network(object):
    def __init__(self, network_ip):
        super(Network, self).__init__()
        self.network_ip = network_ip

class Interface(object):
    def __init__(self, mac_address):
        super(Interface, self).__init__()
        self.mac_address = mac_address

