from devops.helpers import ssh
from fuel_test.base_test_case import BaseTestCase
from fuel_test.ci.ci_swift import CiSwift
from fuel_test.helpers import execute
from fuel_test.root import root

import unittest

class SwiftCase(BaseTestCase):
    def ci(self):
        if not hasattr(self, '_ci'):
            self._ci = CiSwift()
        return self._ci

    def test_deploy_swift(self):
        self.write_site_pp_manifest(
            root('deployment', 'puppet', 'swift', 'examples',
                'site.pp'),
            swift_proxy_address="'%s'" %
                                self.nodes.proxies[0].ip_address_by_network[
                                'public'],
            controller_node_public="'%s'" % self.nodes.keystones[
                                            0].ip_address_by_network['public'],
        )
        results = []
        #install keystone
        remote = ssh(self.nodes.keystones[0].ip_address, username='root',
            password='r00tme')
        results.append(execute(remote.sudo.ssh, 'puppet agent --test'))
        for node in self.nodes.storages:
            remote = ssh(node.ip_address, username='root', password='r00tme')
            results.append(execute(remote.sudo.ssh, 'puppet agent --test'))
            results.append(execute(remote.sudo.ssh, 'puppet agent --test'))
        remote = ssh(self.nodes.proxies[0].ip_address, username='root',
            password='r00tme')
        results.append(execute(remote.sudo.ssh, 'puppet agent --test'))
        for node in self.nodes.storages:
            remote = ssh(node.ip_address, username='root', password='r00tme')
            results.append(execute(remote.sudo.ssh, 'puppet agent --test'))

#        for result in results:
#            self.assertResult(result)

if __name__ == '__main__':
    unittest.main()
