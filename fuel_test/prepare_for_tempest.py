from time import sleep
from devops.helpers import ssh
import keystoneclient.v2_0
from ci_helpers import get_environment
from helpers import tempest_write_config, tempest_add_images, tempest_share_glance_images, tempest_mount_glance_images, get_auth_url, sync_time
from openstack_site_pp_base import OpenStackSitePPBaseTestCase
import unittest
from settings import controllers


class PrepareTempest(OpenStackSitePPBaseTestCase):
    def setUp(self):
        self.environment = get_environment()
        self.controller1 = self.environment.node[controllers[0]]

    def prepare_for_tempest(self):
        for node in self.environment.nodes:
            node.restore_snapshot('openstack')
            sleep(4)
            print 0
            sync_time(ssh(node.ip_address, username='root', password='r00tme').sudo.ssh)
        sleep(30) # mysql don't want to sync
        auth_host = self.get_public_virtual_ip()
        print 1
        remote = ssh(
            self.controller1.ip_address, username='root',
            password='r00tme').sudo.ssh
        tempest_share_glance_images(remote, self.get_internal_network())
        print 2
        for name in controllers[1:]:
            controller = self.environment.node[name]
            remote_controller = ssh(
                controller.ip_address, username='root',
                password='r00tme').sudo.ssh
            tempest_mount_glance_images(remote_controller)
        keystone = None
        for i in range(1,10):
            try:
                keystone = keystoneclient.v2_0.client.Client(
                    username='admin', password='nova', tenant_name='openstack', auth_url=get_auth_url(auth_host))
            except:
                sleep(1)
            break
        tenant1 = None
        for i in range(1,10):
            try:
                tenant1 = keystone.tenants.create('tenant1')
            except:
                sleep(1)
            break

        tenant2 = keystone.tenants.create('tenant2')
        keystone.users.create('tempest1','secret', 'tempest1@example.com', tenant_id=tenant1.id)
        keystone.users.create('tempest2','secret', 'tempest1@example.com', tenant_id=tenant2.id)
        image_ref, image_ref_any = tempest_add_images(remote, auth_host, 'openstack')
        tempest_write_config(auth_host, image_ref, image_ref_any)

if __name__ == '__main__':
    unittest.main()
