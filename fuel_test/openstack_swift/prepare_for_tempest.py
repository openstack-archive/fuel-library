from devops.helpers import ssh
from fuel_test.helpers import safety_revert_nodes, tempest_write_config, make_tempest_objects, tempest_build_config_essex
from fuel_test.openstack_swift.openstack_swift_test_case import OpenStackSwiftTestCase
import unittest
from fuel_test.settings import ADMIN_USERNAME, ADMIN_PASSWORD, ADMIN_TENANT_ESSEX


class PrepareOpenStackSwiftForTempest(OpenStackSwiftTestCase):
    def setUp(self):
        self.environment = self.ci().get_environment()

    def prepare_for_tempest_if_swift(self):
        safety_revert_nodes(self.environment.nodes, 'openstack')
        auth_host = self.ci().get_public_virtual_ip()
        remote = ssh(
            self.ci().nodes().controllers[0].ip_address, username='root',
            password='r00tme').sudo.ssh
        image_ref, image_ref_alt = make_tempest_objects(
            auth_host, remote,
            username=ADMIN_USERNAME,
            password=ADMIN_PASSWORD,
            tenant_name=ADMIN_TENANT_ESSEX,
        )
        tempest_write_config(tempest_build_config_essex(auth_host, image_ref, image_ref_alt))

if __name__ == '__main__':
    unittest.main()
