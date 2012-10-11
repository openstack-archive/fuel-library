from devops.helpers import ssh
import unittest
from fuel_test.helpers import safety_revert_nodes, make_shared_storage, make_tempest_objects, tempest_write_config
from fuel_test.openstack.openstack_test_case import OpenStackTestCase


class PrepareOpenStackForTempest(OpenStackTestCase):
    def setUp(self):
        self.environment = self.ci().get_environment()

    def prepare_for_tempest(self):
        safety_revert_nodes(self.environment.nodes, 'openstack')
        auth_host = self.ci().get_public_virtual_ip()
        remote = ssh(
            self.nodes.controllers[0].ip_address, username='root',
            password='r00tme').sudo.ssh
        make_shared_storage(
            remote,
            self.nodes.controllers[1:],
            self.ci().get_internal_network()
        )
        image_ref, image_ref_any = make_tempest_objects(auth_host, remote)
        tempest_write_config(auth_host, image_ref, image_ref_any)

    def prepare_for_tempest_if_swift(self):
        safety_revert_nodes(self.environment.nodes, 'openstack')
        auth_host = self.ci().get_public_virtual_ip()
        remote = ssh(
            self.nodes.controllers[0].ip_address, username='root',
            password='r00tme').sudo.ssh
        image_ref, image_ref_any = make_tempest_objects(auth_host, remote)
        tempest_write_config(auth_host, image_ref, image_ref_any)

if __name__ == '__main__':
    unittest.main()
