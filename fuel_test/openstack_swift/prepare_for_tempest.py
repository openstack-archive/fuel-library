from devops.helpers import ssh
from fuel_test.helpers import safety_revert_nodes, tempest_write_config, make_tempest_objects
from fuel_test.openstack_swift.openstack_swift_test_case import OpenStackSwiftTestCase
import unittest


class PrepareOpenStackSwiftForTempest(OpenStackSwiftTestCase):
    def setUp(self):
        self.environment = self.ci().get_environment()

    def prepare_for_tempest_if_swift(self):
        safety_revert_nodes(self.environment.nodes, 'openstack')
        auth_host = self.ci().get_public_virtual_ip()
        remote = ssh(
            self.ci().nodes().controllers[0].ip_address, username='root',
            password='r00tme').sudo.ssh
        image_ref, image_ref_any = make_tempest_objects(auth_host, remote)
        tempest_write_config(auth_host, image_ref, image_ref_any)

if __name__ == '__main__':
    unittest.main()
