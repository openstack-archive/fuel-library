import unittest
from fuel_test.openstack_simple.openstack_simple_test_case import OpenStackSimpleTestCase
from fuel_test.settings import OPENSTACK_SNAPSHOT

class OpenStackSimpleCase(OpenStackSimpleTestCase):
    def test_deploy_open_stack_simple(self):
        self.validate(
            self.nodes.controllers + self.nodes.computes,
            'puppet agent --test')
        for node in self.environment.nodes:
            node.save_snapshot(OPENSTACK_SNAPSHOT, force=True)

if __name__ == '__main__':
    unittest.main()
