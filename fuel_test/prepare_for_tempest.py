from devops.helpers import ssh
from helpers import tempest_create_user, tempest_write_config, tempest_add_images, tempest_create_tenant, tempest_share_glance_images, tempest_mount_glance_images
from openstack_site_pp_base import OpenStackSitePPBaseTestCase
import unittest

class PrepareTempest(OpenStackSitePPBaseTestCase):
    def setUp(self):
        pass

    def prepare_for_tempest(self):
        host = self.get_public_virtual_ip()
        remote = ssh(
            self.controller1.ip_address, username='root',
            password='r00tme').sudo.ssh
        remote_controller2 = ssh(
            self.controller2.ip_address, username='root',
            password='r00tme').sudo.ssh
        tempest_share_glance_images(remote, self.get_internal_network())
        tempest_mount_glance_images(remote_controller2, )
        tenant1 = tempest_create_tenant(remote, host, 'tenant1')
        tenant2 = tempest_create_tenant(remote, host, 'tenant2')
        tempest_create_user(remote, host, 'tempest1', 'secret', tenant1)
        tempest_create_user(remote, host, 'tempest2', 'secret', tenant2)
        image_ref, image_ref_any = tempest_add_images(remote, host)
        tempest_write_config(host, image_ref, image_ref_any)

if __name__ == '__main__':
    unittest.main()
