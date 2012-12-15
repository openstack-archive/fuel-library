import unittest
from fuel_test.helpers import is_not_essex
from fuel_test.openstack.openstack_test_case import OpenStackTestCase
from fuel_test.settings import OPENSTACK_SNAPSHOT

class OpenStackCase(OpenStackTestCase):
    def test_deploy_open_stack(self):
        self.validate(self.nodes.controllers[:1], 'puppet agent --test')
        self.validate(self.nodes.controllers[1:], 'puppet agent --test')
        self.validate(self.nodes.controllers[:1], 'puppet agent --test')
        if is_not_essex():
            self.validate(self.nodes.quantums, 'puppet agent --test')
        self.validate(self.nodes.computes, 'puppet agent --test')
        for node in self.environment.nodes:
            node.save_snapshot(OPENSTACK_SNAPSHOT, force=True)

if __name__ == '__main__':
    unittest.main()
