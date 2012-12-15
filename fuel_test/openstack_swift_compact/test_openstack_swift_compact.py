from fuel_test.helpers import is_not_essex
import unittest
from fuel_test.openstack_swift_compact.openstack_swift_compact_test_case import OpenStackSwiftCompactTestCase
from fuel_test.settings import OPENSTACK_SNAPSHOT

class OpenStackSwiftCompactCase(OpenStackSwiftCompactTestCase):
    def test_deploy_open_stack_swift_compact(self):
        self.do(self.nodes.controllers[:1], 'puppet agent --test')
        self.do(self.nodes.controllers[1:], 'puppet agent --test')
        self.do(self.nodes.controllers, 'puppet agent --test')
        self.do(self.nodes.controllers[:1], 'puppet agent --test')
        self.validate(self.nodes.controllers, 'puppet agent --test')
        if is_not_essex():
            self.validate(self.nodes.quantums, 'puppet agent --test')
        self.validate(self.nodes.computes, 'puppet agent --test')
        for node in self.environment.nodes:
            node.save_snapshot(OPENSTACK_SNAPSHOT, force=True)

if __name__ == '__main__':
    unittest.main()
