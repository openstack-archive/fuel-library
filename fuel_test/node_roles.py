class NodeRoles():
    def __init__(self,
                 controller_names=None,
                 compute_names=None,
                 storage_names=None,
                 proxy_names=None,
                 keystone_names=None):
        self.controller_names = controller_names,
        self.compute_names = compute_names,
        self.storage_names = storage_names,
        self.proxy_names = proxy_names,
        self.keystone_names = keystone_names


class Nodes():
    def __init__(self, devops_nodes, node_roles):
        self.controllers = []
        self.computes = []
        self.storages = []
        self.proxies = []
        self.keystones = []
        for node_name in node_roles.controller_names:
            self.controllers += devops_nodes[node_name]
        for node_name in node_roles.compute_names:
            self.computes += devops_nodes[node_name]
        for node_name in node_roles.storage_names:
            self.storages += devops_nodes[node_name]
        for node_name in node_roles.proxy_names:
            self.proxies += devops_nodes[node_name]
        for node_name in node_roles.keystone_names:
            self.keystones += devops_nodes[node_name]



