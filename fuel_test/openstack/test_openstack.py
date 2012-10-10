from openstack_site_pp_base import OpenStackSitePPBaseTestCase
import unittest

class OpenStackCase(OpenStackSitePPBaseTestCase):

    def test_deploy_open_stack(self):
        self.validate(
            [self.controller1,self.controller2,self.compute1,self.compute2],
            'puppet agent --test')
        for node in self.environment.nodes:
            node.save_snapshot('openstack', force=True)

if __name__ == '__main__':
    unittest.main()
