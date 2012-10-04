from devops.helpers import ssh
from base import RecipeTestCase
from helpers import execute
from settings import keystones,storages,proxies
from root import root

import unittest

class SwiftCase(RecipeTestCase):

    def test_deploy_swift(self):
        keystone = self.environment.node[keystones[0]]
        storage1 = self.environment.node[storages[0]]
        storage2 = self.environment.node[storages[1]]
        storage3 = self.environment.node[storages[2]]
        proxy1 = self.environment.node[proxies[0]]
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
