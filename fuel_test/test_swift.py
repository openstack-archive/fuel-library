from devops.helpers import ssh
from base import RecipeTestCase
from helpers import execute
from settings import NODES
from root import root

import unittest

class SwiftCase(RecipeTestCase):

    def test_deploy_swift(self):
        node01 = self.environment.node[NODES[0]]
        node02 = self.environment.node[NODES[1]]
        node03 = self.environment.node[NODES[2]]
        node04 = self.environment.node[NODES[3]]
        node05 = self.environment.node[NODES[4]]
        self.write_site_pp_manifest(
            root('fuel', 'deployment', 'puppet', 'swift', 'examples', 'site.pp'),
            swift_proxy_address="'%s'" % node01.ip_address_by_network['public'],
            controller_node_public="'%s'" % node05.ip_address_by_network['public'],
        )
        results =[]
        node=None
        #install keystone
        remote = ssh(node05.ip_address, username='root', password='r00tme')
        results.append(execute(remote.sudo.ssh, 'puppet agent --test'))
        for node in [node02, node03, node04]:
            remote = ssh(node.ip_address, username='root', password='r00tme')
            results.append(execute(remote.sudo.ssh, 'puppet agent --test'))
            results.append(execute(remote.sudo.ssh, 'puppet agent --test'))
        remote = ssh(node01.ip_address, username='root', password='r00tme')
        results.append(execute(remote.sudo.ssh, 'puppet agent --test'))
        node=None
        for node in [node02, node03, node04]:
            remote = ssh(node.ip_address, username='root', password='r00tme')
            results.append(execute(remote.sudo.ssh, 'puppet agent --test'))
#        for result in results:
#            self.assertResult(result)

if __name__ == '__main__':
    unittest.main()
