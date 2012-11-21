import unittest
from fuel_test.base_test_case import BaseTestCase
from fuel_test.ci.ci_openstack import CiOpenStack
from fuel_test.root import root

class OpenStackTestCase(BaseTestCase):
    def ci(self):
        if not hasattr(self, '_ci'):
            self._ci = CiOpenStack()
        return self._ci

    def setUp(self):
        super(OpenStackTestCase, self).setUp()
        self.write_openstack_sitepp(self.nodes.controllers[0],
            self.nodes.controllers[1])

    def write_openstack_sitepp(self, controller1, controller2):
        self.write_site_pp_manifest(
            root('fuel', 'deployment', 'puppet', 'openstack', 'examples',
                 'site.pp'),
            internal_virtual_ip="'%s'" % self.ci().get_internal_virtual_ip(),
            public_virtual_ip="'%s'" % self.ci().get_public_virtual_ip(),
            floating_range="'%s'" % self.ci().get_floating_network(),
            fixed_range="'%s'" % self.ci().get_fixed_network(),
            master_hostname="'%s'" % controller1.name,
            mirror_type='internal',
            controller_public_addresses="{ '%s' => '%s', '%s' => '%s' }"
            % (
                controller1.name, controller1.ip_address_by_network['public'],
                controller2.name, controller2.ip_address_by_network['public']),
            controller_internal_addresses="{ '%s' => '%s', '%s' => '%s' }"
            % (
                controller1.name, controller1.ip_address_by_network['internal'],
                controller2.name,
                controller2.ip_address_by_network['internal']),
            controller_hostnames=[
                "%s" % controller1.name,
                "%s" % controller2.name],
            public_interface="'eth2'",
            internal_interface="'eth0'",
            internal_address="$ipaddress_eth0",
            private_interface="'eth1'",
            nv_physical_volume= ["/dev/vdb"]
        )
        
if __name__ == '__main__':
    unittest.main()




