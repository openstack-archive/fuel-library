import unittest
from fuel_test.base_test_case import BaseTestCase
from fuel_test.ci.ci_cobbler import CiCobbler
from fuel_test.root import root

class CobblerTestCase(BaseTestCase):
    def ci(self):
        if not hasattr(self, '_ci'):
            self._ci = CiCobbler()
        return self._ci

    def setUp(self):
        super(CobblerTestCase, self).setUp()

    def write_cobbler_manifest(self):
        cobbler = self.nodes.cobblers[0]
        self.write_site_pp_manifest(
            root('fuel', 'deployment', 'puppet', 'cobbler', 'examples',
                'server_site.pp'),
            server="'%s'" % cobbler.ip_address,
            name_server="'%s'" % cobbler.ip_address,
            next_server="'%s'" % cobbler.ip_address,
            dhcp_start_address="'%s'" % self.environment.network[
                                        'internal'].ip_addresses[-5],
            dhcp_end_address="'%s'" %
                             self.environment.network['internal'].ip_addresses[
                             -5],
            dhcp_netmask="'%s'" % '255.255.255.0',
            dhcp_gateway="'%s'" % cobbler.ip_address
        )


if __name__ == '__main__':
    unittest.main()




