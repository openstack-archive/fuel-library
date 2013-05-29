class NodeRoles(object):
    def __init__(self,
                 controller_names=None,
                 compute_names=None,
                 storage_names=None,
                 proxy_names=None,
                 cobbler_names=None,
                 stomp_names=None,
                 quantum_names=None,
                 master_names=None):
        self.master_names = master_names or []
        self.controller_names = controller_names or []
        self.compute_names = compute_names or []
        self.storage_names = storage_names or []
        self.proxy_names = proxy_names or []
        self.cobbler_names = cobbler_names or []
        self.stomp_names = stomp_names or []
        self.quantum_names = quantum_names or []


class Nodes(object):
    def __init__(self, environment, node_roles):
        self.controllers = []
        self.computes = []
        self.storages = []
        self.proxies = []
        self.cobblers = []
        self.stomps = []
        self.quantums = []
        self.masters = []
        for node_name in node_roles.master_names:
            self.masters.append(environment.node_by_name(node_name))
        for node_name in node_roles.controller_names:
            self.controllers.append(environment.node_by_name(node_name))
        for node_name in node_roles.compute_names:
            self.computes.append(environment.node_by_name(node_name))
        for node_name in node_roles.storage_names:
            self.storages.append(environment.node_by_name(node_name))
        for node_name in node_roles.proxy_names:
            self.proxies.append(environment.node_by_name(node_name))
        for node_name in node_roles.cobbler_names:
            self.cobblers.append(environment.node_by_name(node_name))
        for node_name in node_roles.stomp_names:
            self.stomps.append(environment.node_by_name(node_name))
        for node_name in node_roles.quantum_names:
            self.quantums.append(environment.node_by_name(node_name))

        self.all = self.controllers + self.computes + self.storages +\
                   self.proxies + self.cobblers + self.stomps +\
                   self.quantums + self.masters

    def __iter__(self):
        return self.all.__iter__()


