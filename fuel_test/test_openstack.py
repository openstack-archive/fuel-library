from devops.helpers import ssh
from base import RecipeTestCase
from helpers import execute
from settings import NODES
from root import root

import unittest

class OpenStackCase(RecipeTestCase):

    def test_deploy_open_stack(self):
        node01 = self.environment.node[NODES[0]]
        node02 = self.environment.node[NODES[1]]
        node03 = self.environment.node[NODES[2]]
        node04 = self.environment.node[NODES[3]]
        internal_virtual_ip = self.environment.network['internal'].ip_addresses[-3]
        public_virtual_ip = self.environment.network['public'].ip_addresses[-3]
#        address=str(network.ip_addresses[1]),
#        prefix=str(network.ip_addresses.prefixlen)
        floating_range = '.'.join(
            str(self.environment.network['public'].ip_addresses[-1]).split(
                '.')[:-1])+'.128/27'
        fixed_range = '.'.join(
            str(self.environment.network['private'].ip_addresses[-1]).split(
                '.')[:-1])+'.128/27'
        self.write_site_pp_manifest(
            root('fuel', 'deployment', 'puppet', 'openstack', 'examples', 'site.pp'),
            internal_virtual_ip="'%s'" % internal_virtual_ip,
            public_virtual_ip="'%s'" % public_virtual_ip,
            floating_range = "'%s'" % floating_range,
            fixed_range = "'%s'" % fixed_range,
            master_hostname="'%s'" % node01.name,
            controller_public_addresses = [
                "%s" % node01.ip_address_by_network['public'],
                "%s" % node02.ip_address_by_network['public']
            ],
            controller_internal_addresses = [
                "%s" % node01.ip_address_by_network['internal'],
                "%s" % node02.ip_address_by_network['internal']
            ],
            controller_hostnames = [
                "%s" % node01.name,
                "%s" % node02.name],
            public_interface = "'eth2'",
            internal_interface = "'eth0'",
            internal_address = "$ipaddress_eth0",
            private_interface = "'eth1'"
        )
        results =[]
        for node in [node01, node02, node03, node04]:
            remote = ssh(node.ip_address, username='root', password='r00tme')
            results.append(execute(remote.sudo.ssh, 'puppet agent --test'))
        for result in results:
            self.assertResult(result)

if __name__ == '__main__':
    unittest.main()
