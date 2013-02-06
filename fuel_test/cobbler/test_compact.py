from fuel_test.cobbler.cobbler_test_case import CobblerTestCase
from fuel_test.helpers import is_not_essex
import unittest
from fuel_test.manifest import Manifest, Template

class CompactTestCase(CobblerTestCase):
    def deploy_compact(self, quantum=True, loopback=True):
        self.do(self.nodes().controllers[:1], 'puppet agent --test')
        self.do(self.nodes().controllers[1:], 'puppet agent --test')
        if loopback:
            self.do(self.nodes().controllers, 'puppet agent --test')
        self.do(self.nodes().controllers[1:], 'puppet agent --test')
        self.do(self.nodes().controllers[:1], 'puppet agent --test')
        self.validate(self.nodes().controllers, 'puppet agent --test')
        if quantum:
            self.validate(self.nodes().quantums, 'puppet agent --test')
        self.validate(self.nodes().computes, 'puppet agent --test')

    @unittest.skipUnless(is_not_essex(), 'Quantum in essex is not supported')
    def test_deploy_compact_quantum(self):
        Manifest().write_openstack_manifest(
            remote=self.remote(),
            template=Template.compact(), ci=self.ci(),
            controllers=self.nodes().controllers,
            quantums=self.nodes().quantums,
            quantum=True)
        self.deploy_compact()
        self.environment().snapshot('compact', force=True)

    def test_deploy_compact_wo_quantum(self):
        Manifest().write_openstack_manifest(
            remote=self.remote(),
            template=Template.compact(), ci=self.ci(),
            controllers=self.nodes().controllers,
            quantums=self.nodes().quantums,
            quantum=False)
        self.deploy_compact(quantum=False)
        self.environment().snapshot('compact_wo_quantum', force=True)

    def test_deploy_compact_wo_loopback(self):
        Manifest().write_openstack_manifest(
            remote=self.remote(),
            template=Template.compact(), ci=self.ci(),
            controllers=self.nodes().controllers,
            quantums=self.nodes().quantums,
            quantum=False, loopback=False, use_syslog=False)
        self.deploy_compact(quantum=False, loopback=False)
        self.environment().snapshot('compact_woloopback', force=True)

if __name__ == '__main__':
    unittest.main()
