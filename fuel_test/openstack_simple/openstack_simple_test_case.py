import unittest
from fuel_test.base_test_case import BaseTestCase
from fuel_test.ci.ci_openstack_simple import CiOpenStackSimple
from fuel_test.root import root

class OpenStackSimpleTestCase(BaseTestCase):
    def ci(self):
        if not hasattr(self, '_ci'):
            self._ci = CiOpenStackSimple()
        return self._ci

    def setUp(self):
        super(OpenStackSimpleTestCase, self).setUp()
        self.write_openstack_sitepp(self.nodes.controllers[0])

    def write_openstack_sitepp(self, controller):
            self.write_site_pp_manifest(
                root('fuel', 'deployment', 'puppet', 'openstack', 'examples',
                    'site_simple.pp'),
                floating_network_range="'%s'" % self.ci().get_floating_network(),
                fixed_network_range="'%s'" % self.ci().get_fixed_network(),
                public_interface="'eth2'",
                internal_interface="'eth0'",
                private_interface="'eth1'",
                mirror_type="internal",
                controller_node_address="'%s'" % controller.ip_address_by_network['internal'],
                controller_node_public="'%s'" % controller.ip_address_by_network['public'],
                nv_physical_volume= ["/dev/vdb"]
            )

if __name__ == '__main__':
    unittest.main()




