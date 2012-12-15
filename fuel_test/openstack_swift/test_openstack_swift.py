import unittest
from fuel_test.helpers import is_not_essex
from fuel_test.openstack_swift.openstack_swift_test_case import OpenStackSwiftTestCase
from fuel_test.settings import OPENSTACK_SNAPSHOT

class OpenStackSwiftCase(OpenStackSwiftTestCase):
    def test_deploy_open_stack_swift(self):
        self.validate(self.nodes.controllers[:1], 'puppet agent --test')
        self.validate(self.nodes.controllers[1:], 'puppet agent --test')
        self.validate(self.nodes.controllers[:1], 'puppet agent --test')
        if is_not_essex():
            self.validate(self.nodes.quantums, 'puppet agent --test')
        self.validate(self.nodes.computes, 'puppet agent --test')
        self.do(self.nodes.storages, 'puppet agent --test')
        self.do(self.nodes.storages, 'puppet agent --test')
        self.do(self.nodes.proxies, 'puppet agent --test')
        self.validate(self.nodes.storages, 'puppet agent --test')
        self.validate(self.nodes.proxies, 'puppet agent --test')
        for node in self.environment.nodes:
            node.save_snapshot(OPENSTACK_SNAPSHOT, force=True)

if __name__ == '__main__':
    unittest.main()
