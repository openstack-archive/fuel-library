from time import sleep
from devops.helpers import ssh
import keystoneclient.v2_0
from helpers import tempest_write_config, tempest_add_images, tempest_share_glance_images, tempest_mount_glance_images, get_auth_url, execute, retry, safety_revert_nodes
import unittest
from openstack.openstack_test_case import OpenStackTestCase


class PrepareOpenStackForTempest(OpenStackTestCase):
    def setUp(self):
        self.environment = self.ci().get_environment()
        self.nodes.controllers[0] = self.environment.node[
                                    self.ci().controllers[0]]

    def make_shared_storage(self, remote):
        tempest_share_glance_images(remote, self.ci().get_internal_network())
        execute(remote, '/etc/init.d/iptables stop')
        sleep(5)
        for controller in self.nodes.controllers[1:]:
            remote_controller = ssh(
                controller.ip_address, username='root',
                password='r00tme').sudo.ssh
            tempest_mount_glance_images(remote_controller, controller[0].name)

    def make_tempest_objects(self, auth_host, remote):
        keystone = retry(10, keystoneclient.v2_0.client.Client,
            username='admin', password='nova', tenant_name='openstack',
            auth_url=get_auth_url(auth_host))
        tenant1 = retry(10, keystone.tenants.create, tenant_name='tenant1')
        tenant2 = retry(10, keystone.tenants.create, tenant_name='tenant2')
        retry(10, keystone.users.create, name='tempest1', password='secret',
            email='tempest1@example.com', tenant_id=tenant1.id)
        retry(10, keystone.users.create, name='tempest2', password='secret',
            email='tempest1@example.com', tenant_id=tenant2.id)
        image_ref, image_ref_any = tempest_add_images(remote, auth_host,
            'openstack')
        return image_ref, image_ref_any

    def prepare_for_tempest(self):
        safety_revert_nodes(self.environment.nodes, 'openstack')
        auth_host = self.ci().get_public_virtual_ip()
        remote = ssh(
            self.nodes.controllers[0].ip_address, username='root',
            password='r00tme').sudo.ssh
        self.make_shared_storage(remote)
        image_ref, image_ref_any = self.make_tempest_objects(auth_host, remote)
        tempest_write_config(auth_host, image_ref, image_ref_any)

    def prepare_for_tempest_if_swift(self):
        safety_revert_nodes(self.environment.nodes, 'openstack')
        auth_host = self.ci().get_public_virtual_ip()
        remote = ssh(
            self.nodes.controllers[0].ip_address, username='root',
            password='r00tme').sudo.ssh
        image_ref, image_ref_any = self.make_tempest_objects(auth_host, remote)
        tempest_write_config(auth_host, image_ref, image_ref_any)

if __name__ == '__main__':
    unittest.main()
