class NodeRoles(object):
    def __init__(self,
                 controller_names=None,
                 compute_names=None,
                 storage_names=None,
                 proxy_names=None,
                 cobbler_names=None,
                 keystone_names=None,
                 stomp_names=None):
        self.controller_names = controller_names or []
        self.compute_names = compute_names or []
        self.storage_names = storage_names or []
        self.proxy_names = proxy_names or []
        self.cobbler_names = cobbler_names or []
        self.keystone_names = keystone_names or []
        self.stomp_names = stomp_names or []


class Nodes(object):
    def __init__(self, devops_environment, node_roles):
        self.controllers = []
        self.computes = []
        self.storages = []
        self.proxies = []
        self.keystones = []
        self.cobblers = []
        self.stomps = []
        for node_name in node_roles.controller_names:
            self.controllers.append(devops_environment.node[node_name])
        for node_name in node_roles.compute_names:
            self.computes.append(devops_environment.node[node_name])
        for node_name in node_roles.storage_names:
            self.storages.append(devops_environment.node[node_name])
        for node_name in node_roles.proxy_names:
            self.proxies.append(devops_environment.node[node_name])
        for node_name in node_roles.cobbler_names:
            self.cobblers.append(devops_environment.node[node_name])
        for node_name in node_roles.keystone_names:
            self.keystones.append(devops_environment.node[node_name])
        for node_name in node_roles.stomp_names:
            self.stomps.append(devops_environment.node[node_name])



