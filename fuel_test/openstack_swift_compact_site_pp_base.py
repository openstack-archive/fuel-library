from devops.helpers import ssh
from base import RecipeTestCase
from helpers import execute
from settings_compact import controllers,computes
from root import root

import unittest

class OpenStackSwiftCompactSitePPBaseTestCase(RecipeTestCase):

    def setUp(self):
        super(OpenStackSwiftCompactSitePPBaseTestCase, self).setUp()
        self.controller1 = self.environment.node[controllers[0]]
        self.controller2 = self.environment.node[controllers[1]]
        self.controller3 = self.environment.node[controllers[2]]
        self.compute1 = self.environment.node[computes[0]]
        self.compute2 = self.environment.node[computes[1]]

    def get_internal_virtual_ip(self):
        return self.environment.network['internal'].ip_addresses[-3]

    def get_public_virtual_ip(self):
        return self.environment.network['public'].ip_addresses[-3]

    def get_floating_network(self):
        return '.'.join(
            str(self.environment.network['public'].ip_addresses[-1]).split(
                '.')[:-1])+'.128/27'

    def get_fixed_network(self):
        return '.'.join(
            str(self.environment.network['private'].ip_addresses[-1]).split(
                '.')[:-1])+'.128/27'

    def get_internal_network(self):
        network = self.environment.network['internal']
        return str(network.ip_addresses[1]) +'/' + str(network.ip_addresses.prefixlen)

    def write_openstack_sitepp(self, node01, node02, node03):
        self.write_site_pp_manifest(
            root('fuel', 'deployment', 'puppet', 'openstack', 'examples',
                'site_openstack_swift_compact.pp'),
            internal_virtual_ip="'%s'" % self.get_internal_virtual_ip(),
            public_virtual_ip="'%s'" % self.get_public_virtual_ip(),
            floating_range = "'%s'" % self.get_floating_network(),
            fixed_range = "'%s'" % self.get_fixed_network(),
            master_hostname="'%s'" % node01.name,
            swift_proxy_address = "'%s'" % self.get_internal_virtual_ip(),
            controller_public_addresses="{ '%s' => '%s', '%s' => '%s', '%s' => '%s' }" 
            % (node01.name,node01.ip_address_by_network['public'],node02.name,node02.ip_address_by_network['public'],node03.name,node03.ip_address_by_network['public']),
            controller_internal_addresses="{ '%s' => '%s', '%s' => '%s', '%s' => '%s' }" 
            % (node01.name,node01.ip_address_by_network['internal'],node02.name,node02.ip_address_by_network['internal'],node03.name,node03.ip_address_by_network['internal']),
            controller_hostnames=[
                "%s" % node01.name,
                "%s" % node02.name,
                "%s" % node03.name],
            public_interface="'eth2'",
            internal_interface="'eth0'",
            internal_address="$ipaddress_eth0",
            private_interface="'eth1'"
        )

    def do(self, nodes, command):
        self.write_openstack_sitepp(self.controller1, self.controller2, self.controller3)
        results = []
        for node in nodes:
            remote = ssh(node.ip_address, username='root', password='r00tme')
            results.append(execute(remote.sudo.ssh, command))
        return results

    def validate(self, nodes, command):
        results = self.do(nodes, command)
        for result in results:
            self.assertResult(result)

if __name__ == '__main__':
    unittest.main()

