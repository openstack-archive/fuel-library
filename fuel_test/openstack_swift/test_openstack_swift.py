from devops.helpers import ssh
import unittest
from fuel_test.helpers import execute
from fuel_test.openstack_swift.openstack_swift_test_case import OpenStackSwiftTestCase
from fuel_test.settings import OPENSTACK_SNAPSHOT

class OpenStackSwiftCase(OpenStackSwiftTestCase):
    def test_deploy_open_stack_swift(self):
        self.validate(
            [self.nodes.controllers[0], self.nodes.controllers[1], self.nodes.controllers[0],
             self.nodes.computes[0], self.nodes.computes[1]],
            'puppet agent --test')
        results = []
        for node in self.nodes.storages:
            remote = ssh(node.ip_address_by_network['internal'], username='root', password='r00tme')
            results.append(execute(remote.sudo.ssh, 'puppet agent --test'))
            results.append(execute(remote.sudo.ssh, 'puppet agent --test'))
        remote = ssh(self.nodes.proxies[0].ip_address_by_network['internal'], username='root',
            password='r00tme')
        results.append(execute(remote.sudo.ssh, 'puppet agent --test'))
        self.validate(self.nodes.storages,
                                'puppet agent --test')
        self.validate(self.nodes.proxies,
                                'puppet agent --test')
        for node in self.environment.nodes:
            node.save_snapshot(OPENSTACK_SNAPSHOT, force=True)

if __name__ == '__main__':
    unittest.main()
