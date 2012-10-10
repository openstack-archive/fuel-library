from helpers import execute
from devops.helpers import ssh
import unittest
from openstack_swift.openstack_swift_test_case import OpenStackSwiftTestCase

class OpenStackSwiftCase(OpenStackSwiftTestCase):
    def test_deploy_open_stack_swift(self):
        self.validate(
            [self.nodes.controllers[0], self.nodes.controllers[1],
             self.nodes.computes[0], self.nodes.computes[1]],
            'puppet agent --test')
        results = []
        for node in self.nodes.storages:
            remote = ssh(node.ip_address, username='root', password='r00tme')
            results.append(execute(remote.sudo.ssh, 'puppet agent --test'))
            results.append(execute(remote.sudo.ssh, 'puppet agent --test'))
        remote = ssh(self.nodes.proxies[0].ip_address, username='root',
            password='r00tme')
        results.append(execute(remote.sudo.ssh, 'puppet agent --test'))
        node = None
        for node in self.nodes.storages:
            remote = ssh(node.ip_address, username='root', password='r00tme')
            results.append(execute(remote.sudo.ssh, 'puppet agent --test'))
        for node in self.environment.node_roles:
            node.save_snapshot('openstack', force=True)

if __name__ == '__main__':
    unittest.main()
