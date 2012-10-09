from openstack_swift_site_pp_base import OpenStackSwiftSitePPBaseTestCase
from helpers import execute
from settings import storages,proxies
from devops.helpers import ssh
import unittest

class OpenStackSwiftCase(OpenStackSwiftSitePPBaseTestCase):

    def test_deploy_open_stack_swift(self):
        storage1 = self.environment.node[storages[0]]
        storage2 = self.environment.node[storages[1]]
        storage3 = self.environment.node[storages[2]]
        proxy1 = self.environment.node[proxies[0]]
        self.validate(
            [self.controller1,self.controller2,self.compute1,self.compute2],
            'puppet agent --test')
        for node in self.environment.nodes:
            node.save_snapshot('openstack', force=True)
        results=[]
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

if __name__ == '__main__':
    unittest.main()
