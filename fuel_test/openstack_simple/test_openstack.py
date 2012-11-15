import unittest
from fuel_test.openstack_simple.openstack_simple_test_case import OpenStackSimpleTestCase

class OpenStackSimpleCase(OpenStackSimpleTestCase):
    def test_deploy_open_stack_simple(self):
        self.validate(
            [self.nodes.controllers[0],
             self.nodes.computes[0], self.nodes.computes[1], self.nodes.computes[2]],
            'puppet agent --test')
        for node in self.environment.nodes:
            node.save_snapshot('openstack', force=True)

if __name__ == '__main__':
    unittest.main()
