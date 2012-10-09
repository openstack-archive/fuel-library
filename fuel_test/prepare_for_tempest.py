from time import sleep
from devops.helpers import ssh
import keystoneclient.v2_0
from ci_helpers import get_environment
from helpers import tempest_write_config, tempest_add_images, tempest_share_glance_images, tempest_mount_glance_images, get_auth_url, sync_time, execute, retry
from openstack_site_pp_base import OpenStackSitePPBaseTestCase
import unittest
from settings import controllers


class PrepareTempest(OpenStackSitePPBaseTestCase):
    def setUp(self):
        self.environment = get_environment()
        self.controller1 = self.environment.node[controllers[0]]

    def prepare_for_tempest(self):
        for node in self.environment.nodes:
            try:
                node.stop()
            except:
                pass
        for node in self.environment.nodes:
            node.restore_snapshot('openstack')
            sleep(4)
#            sync_time(ssh(node.ip_address, username='root', password='r00tme').sudo.ssh)
        auth_host = self.get_public_virtual_ip()
        remote = ssh(
            self.controller1.ip_address, username='root',
            password='r00tme').sudo.ssh
        tempest_share_glance_images(remote, self.get_internal_network())
        execute(remote, '/etc/init.d/iptables stop')
        sleep(5)
        for name in controllers[1:]:
            controller = self.environment.node[name]
            remote_controller = ssh(
                controller.ip_address, username='root',
                password='r00tme').sudo.ssh
            tempest_mount_glance_images(remote_controller)
        keystone = retry(10,keystoneclient.v2_0.client.Client,
                    username='admin', password='nova', tenant_name='openstack', auth_url=get_auth_url(auth_host))
        tenant1 = retry(10, keystone.tenants.create, tenant_name = 'tenant1')
        tenant2 = retry(10, keystone.tenants.create, tenant_name = 'tenant2')
        retry(10, keystone.users.create,name='tempest1',password='secret', email='tempest1@example.com', tenant_id=tenant1.id)
        retry(10, keystone.users.create,name='tempest2',password='secret', email='tempest1@example.com', tenant_id=tenant2.id)
        image_ref, image_ref_any = tempest_add_images(remote, auth_host, 'openstack')
        tempest_write_config(auth_host, image_ref, image_ref_any)

if __name__ == '__main__':
    unittest.main()
