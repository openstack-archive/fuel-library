from fuel_test.helpers import is_not_essex
import unittest
from fuel_test.openstack_swift_compact.openstack_swift_compact_test_case import OpenStackSwiftCompactTestCase
from fuel_test.settings import OPENSTACK_SNAPSHOT

class OpenStackSwiftCompactCase(OpenStackSwiftCompactTestCase):
    def deploy_compact(self, quantum=True):
        self.do(self.nodes.controllers[:1], 'puppet agent --test')
        self.do(self.nodes.controllers[1:], 'puppet agent --test')
        self.do(self.nodes.controllers, 'puppet agent --test')
        self.do(self.nodes.controllers[:1], 'puppet agent --test')
        self.validate(self.nodes.controllers, 'puppet agent --test')
        if quantum:
            if is_not_essex():
                self.validate(self.nodes.quantums, 'puppet agent --test')
        self.validate(self.nodes.computes, 'puppet agent --test')
        for node in self.environment.nodes:
            node.save_snapshot(OPENSTACK_SNAPSHOT, force=True)

    def test_deploy_compact(self):
        self.write_openstack_sitepp(self.nodes.controllers, quantum=True)
        self.deploy_compact()

    def test_deploy_compact_wo_quantum(self):
        self.write_openstack_sitepp(self.nodes.controllers, quantum=False)
        self.deploy_compact(quantum=False)

if __name__ == '__main__':
    unittest.main()
