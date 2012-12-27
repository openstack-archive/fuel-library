import unittest
from fuel_test.base_test_case import BaseTestCase
from fuel_test.ci.ci_openstack_simple import CiOpenStackSimple
from fuel_test.root import root
from fuel_test.settings import PUBLIC_INTERFACE, INTERNAL_INTERFACE, PRIVATE_INTERFACE, OS_FAMILY

class OpenStackSimpleTestCase(BaseTestCase):
    def ci(self):
        if not hasattr(self, '_ci'):
            self._ci = CiOpenStackSimple()
        return self._ci

    def setUp(self):
        super(OpenStackSimpleTestCase, self).setUp()
        self.write_openstack_sitepp(self.nodes.controllers[0])

    def write_openstack_sitepp(self, controller):
        if OS_FAMILY == 'centos':
            mirror_type = "'internal-stage'"
        else:
            mirror_type = "'internal'"

        self.write_site_pp_manifest(
            root('deployment', 'puppet', 'openstack', 'examples',
                'site_simple.pp'),
            floating_range="'%s'" % self.ci().get_floating_network(),
            fixed_range="'%s'" % self.ci().get_fixed_network(),
            public_interface="'%s'" % PUBLIC_INTERFACE,
            internal_interface="'%s'" % INTERNAL_INTERFACE,
            private_interface="'%s'" % PRIVATE_INTERFACE,
            mirror_type=mirror_type,
            controller_node_address="'%s'" % controller.ip_address_by_network[
                                             'internal'],
            controller_node_public="'%s'" % controller.ip_address_by_network[
                                            'public'],
            nv_physical_volume=["/dev/vdb"]
        )

if __name__ == '__main__':
    unittest.main()




