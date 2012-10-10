from fuel_test.helpers import execute
from devops.helpers import ssh
import unittest
from fuel_test.openstack_swift_compact.openstack_swift_compact_test_case import OpenStackSwiftCompactTestCase

class OpenStackSwiftCompactCase(OpenStackSwiftCompactTestCase):
    def test_deploy_open_stack_swift_compact(self):
        self.validate(
            [self.nodes.controllers[0], self.nodes.controllers[1],
             self.nodes.controllers[2]],
            'puppet agent --test')
        self.validate(
            [self.nodes.computes],
            'puppet agent --test')
        results = []
        for node in self.nodes.controllers:
            remote = ssh(node.ip_address, username='root', password='r00tme')
            results.append(execute(remote.sudo.ssh, 'puppet agent --test'))
            results.append(execute(remote.sudo.ssh, 'puppet agent --test'))
        for node in self.nodes.controllers:
            remote = ssh(node.ip_address, username='root', password='r00tme')
            results.append(execute(remote.sudo.ssh, 'puppet agent --test'))
        for node in self.nodes.controllers:
            remote = ssh(node.ip_address, username='root', password='r00tme')
            results.append(execute(remote.sudo.ssh, 'puppet agent --test'))
        for node in self.environment.nodes:
            node.save_snapshot('openstack')

if __name__ == '__main__':
    unittest.main()
