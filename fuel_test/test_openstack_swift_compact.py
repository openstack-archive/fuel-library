from openstack_swift_compact_site_pp_base import OpenStackSwiftCompactSitePPBaseTestCase
from helpers import execute
from devops.helpers import ssh
import unittest

class OpenStackSwiftCompactCase(OpenStackSwiftCompactSitePPBaseTestCase):
    def test_deploy_open_stack_swift_compact(self):
        self.validate(
            [self.controller1,self.controller2,self.controller3],
            'puppet agent --test')
        self.validate(
            [self.compute1,self.compute2],
            'puppet agent --test')
#        for node in self.environment.nodes:
#            node.save_snapshot('openstack')
        results=[]
        for node in [self.controller1,self.controller2,self.controller3]:
            remote = ssh(node.ip_address, username='root', password='r00tme')
            results.append(execute(remote.sudo.ssh, 'puppet agent --test'))
        for node in [self.controller1,self.controller2,self.controller3]:
            remote = ssh(node.ip_address, username='root', password='r00tme')
            results.append(execute(remote.sudo.ssh, 'puppet agent --test'))
        for node in [self.controller1,self.controller2,self.controller3]:
            remote = ssh(node.ip_address, username='root', password='r00tme')
            results.append(execute(remote.sudo.ssh, 'puppet agent --test'))

if __name__ == '__main__':
    unittest.main()
