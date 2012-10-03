from devops.helpers import ssh
from helpers import tempest_build_config, tempest_create_user, tempest_write_config, tempest_add_images
from openstack_site_pp_base import OpenStackSitePPBaseTestCase
import unittest

class OpenStackCase(OpenStackSitePPBaseTestCase):

    def test_deploy_open_stack(self):
        self.validate(
            [self.controller1,self.controller2,self.compute1,self.compute2],
            'puppet agent --test')

    def prepare_for_tempest(self):
        public_virtual_ip = self.environment.network['public'].ip_addresses[-3]
        remote = ssh(self.controller1.ip_address, username='root', password='r00tme')
        tempest_create_user(remote, public_virtual_ip, 'tempest1', 'secret', 'openstack')
        tempest_create_user(remote, public_virtual_ip, 'tempest2', 'secret', 'openstack')
        image_ref, image_ref_any = tempest_add_images(remote)
        tempest_write_config(public_virtual_ip, image_ref, image_ref_any)

if __name__ == '__main__':
    unittest.main()
