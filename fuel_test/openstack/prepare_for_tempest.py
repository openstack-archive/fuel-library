from devops.helpers import ssh
import unittest
from fuel_test.helpers import safety_revert_nodes, make_shared_storage, make_tempest_objects, tempest_write_config, tempest_build_config_essex, tempest_build_config_folsom
from fuel_test.openstack.openstack_test_case import OpenStackTestCase
from fuel_test.root import root
from fuel_test.settings import ADMIN_USERNAME, ADMIN_PASSWORD, ADMIN_TENANT_ESSEX, ADMIN_TENANT_FOLSOM


class PrepareOpenStackForTempest(OpenStackTestCase):
    def setUp(self):
        self.environment = self.ci().get_environment()

    def revert(self):
        safety_revert_nodes(self.environment.nodes, 'openstack')

    def prepare_for_tempest(self):
        auth_host = self.ci().get_public_virtual_ip()
        remote = ssh(
            self.ci().nodes().controllers[0].ip_address, username='root',
            password='r00tme').sudo.ssh
        make_shared_storage(
            remote,
            self.ci().nodes().controllers[0].name,
            self.ci().nodes().controllers[1:],
            self.ci().get_internal_network()
        )
        image_ref, image_ref_alt = make_tempest_objects(
            auth_host,
            username=ADMIN_USERNAME,
            password=ADMIN_PASSWORD,
            tenant_name=ADMIN_TENANT_ESSEX,
        )
        tempest_write_config(tempest_build_config_essex(auth_host, image_ref, image_ref_alt))

    def prepare_for_tempest_folsom(self):
        auth_host = self.ci().get_public_virtual_ip()
        remote = ssh(
            self.ci().nodes().controllers[0].ip_address, username='root',
            password='r00tme').sudo.ssh
        make_shared_storage(
            remote,
            self.ci().nodes().controllers[0].name,
            self.ci().nodes().controllers[1:],
            self.ci().get_internal_network()
        )
        compute_db_uri = 'mysql://nova:nova@%s/nova' % self.ci().get_internal_virtual_ip()

        image_ref, image_ref_alt = make_tempest_objects(
            auth_host,
            username=ADMIN_USERNAME,
            password=ADMIN_PASSWORD,
            tenant_name=ADMIN_TENANT_FOLSOM,
        )
        tempest_write_config(
            tempest_build_config_folsom(
                host=auth_host,
                image_ref=image_ref,
                image_ref_alt=image_ref_alt,
                path_to_private_key=root('fuel_test', 'config', 'ssh_keys', 'openstack'),
                compute_db_uri=compute_db_uri
            ))


if __name__ == '__main__':
    unittest.main()
