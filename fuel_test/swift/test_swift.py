from devops.helpers import ssh
from base_test_case import BaseTestCase
from ci.ci_swift import CiSwift
from helpers import execute
from root import root

import unittest

class SwiftCase(BaseTestCase):

    def ci(self):
        if self.ci:
            return self.ci
        return CiSwift()

    def test_deploy_swift(self):
        keystone = self.environment.node[self.ci().keystones[0]]
        storage1 = self.environment.node[self.ci().storages[0]]
        storage2 = self.environment.node[self.ci().storages[1]]
        storage3 = self.environment.node[self.ci().storages[2]]
        proxy1 = self.environment.node[self.ci().proxies[0]]
        self.write_site_pp_manifest(
            root('fuel', 'deployment', 'puppet', 'swift', 'examples', 'site.pp'),
            swift_proxy_address="'%s'" % proxy1.ip_address_by_network['public'],
            controller_node_public="'%s'" % keystone.ip_address_by_network['public'],
        )
        results =[]
        node=None
        #install keystone
        remote = ssh(keystone.ip_address, username='root', password='r00tme')
        results.append(execute(remote.sudo.ssh, 'puppet agent --test'))
        for node in [storage1,storage2,storage3]:
            remote = ssh(node.ip_address, username='root', password='r00tme')
            results.append(execute(remote.sudo.ssh, 'puppet agent --test'))
            results.append(execute(remote.sudo.ssh, 'puppet agent --test'))
        remote = ssh(proxy1.ip_address, username='root', password='r00tme')
        results.append(execute(remote.sudo.ssh, 'puppet agent --test'))
        node=None
        for node in [storage1,storage2,storage3]:
            remote = ssh(node.ip_address, username='root', password='r00tme')
            results.append(execute(remote.sudo.ssh, 'puppet agent --test'))
#        for result in results:
#            self.assertResult(result)

if __name__ == '__main__':
    unittest.main()
