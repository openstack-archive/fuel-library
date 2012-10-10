from base_test_case import BaseTestCase
from ci.ci_openstack_swift import CiOpenStackSwift
from root import root

class OpenStackSwiftTestCase(BaseTestCase):

    def ci(self):
        if self.ci:
            return self.ci
        return CiOpenStackSwift()

    def setUp(self):
        super(OpenStackSwiftTestCase, self).setUp()
        self.controller1 = self.environment.node[self.ci().controllers[0]]
        self.controller2 = self.environment.node[self.ci().controllers[1]]
        self.compute1 = self.environment.node[self.ci().computes[0]]
        self.compute2 = self.environment.node[self.ci().computes[1]]
        self.storage1 = self.environment.node[self.ci().storages[0]]
        self.storage2 = self.environment.node[self.ci().storages[1]]
        self.storage3 = self.environment.node[self.ci().storages[2]]
        self.proxy1 = self.environment.node[self.ci().proxies[0]]
        self.write_openstack_sitepp(self.controller1, self.controller2, self.proxy1)

    def write_openstack_sitepp(self, node01, node02, node03):
        self.write_site_pp_manifest(
            root('fuel', 'deployment', 'puppet', 'openstack', 'examples',
                'site_openstack_swift_standalone.pp'),
            internal_virtual_ip="'%s'" % self.ci().get_internal_virtual_ip(),
            public_virtual_ip="'%s'" % self.ci().get_public_virtual_ip(),
            floating_range = "'%s'" % self.ci().get_floating_network(),
            fixed_range = "'%s'" % self.ci().get_fixed_network(),
            master_hostname="'%s'" % node01.name,
            swift_proxy_address = "'%s'" % node03.ip_address_by_network['internal'],
            controller_public_addresses="{ '%s' => '%s', '%s' => '%s' }" 
            % (node01.name,node01.ip_address_by_network['public'],node02.name,node02.ip_address_by_network['public']),
            controller_internal_addresses="{ '%s' => '%s', '%s' => '%s' }" 
            % (node01.name,node01.ip_address_by_network['internal'],node02.name,node02.ip_address_by_network['internal']),
            controller_hostnames=[
                "%s" % node01.name,
                "%s" % node02.name],
            public_interface="'eth2'",
            internal_interface="'eth0'",
            internal_address="$ipaddress_eth0",
            private_interface="'eth1'"
        )
