from fuel_test.cobbler.vm_test_case import CobblerTestCase
from fuel_test.helpers import is_not_essex
import unittest
from fuel_test.manifest import Manifest, Template


class CompactTestCase(CobblerTestCase):
    def deploy_compact(self, quantum_node=True, loopback=True):
        self.validate(self.nodes().controllers[:1], 'puppet agent --test 2>&1')
        self.validate(self.nodes().controllers[1:], 'puppet agent --test 2>&1')
        self.validate(self.nodes().controllers[:1], 'puppet agent --test 2>&1')
        if quantum_node:
            self.validate(self.nodes().quantums, 'puppet agent --test 2>&1')
        self.validate(self.nodes().computes, 'puppet agent --test 2>&1')

    @unittest.skipUnless(is_not_essex(), 'Quantum in essex is not supported')
    def test_deploy_compact_quantum(self):
        manifest = Manifest().generate_openstack_manifest(
            template=Template.compact(), ci=self.ci(),
            controllers=self.nodes().controllers,
            quantums=self.nodes().quantums,
            quantum=True)
        Manifest().write_manifest(remote=self.remote(), manifest=manifest)
        self.deploy_compact(quantum_node=False)

    def test_deploy_compact_quantum_standalone(self):
        Manifest().generate_openstack_manifest(
            template=Template.compact(), ci=self.ci(),
            controllers=self.nodes().controllers,
            quantums=self.nodes().quantums,
            quantum=True, quantum_netnode_on_cnt=False, ha_provider=False)
        self.deploy_compact(quantum_node=True)

    def test_deploy_compact_wo_quantum(self):
        Manifest().generate_openstack_manifest(
            template=Template.compact(), ci=self.ci(),
            controllers=self.nodes().controllers,
            quantums=self.nodes().quantums,
            quantum=False)
        self.deploy_compact(quantum_node=False)

    def test_deploy_compact_wo_quantum_cinder_all_by_ipaddr(self): 
        Manifest().generate_openstack_manifest(
            template=Template.compact(), ci=self.ci(),
            controllers=self.nodes().controllers, 
            cinder=True,
            cinder_nodes=map(
                lambda x: x.get_ip_address_by_network_name('internal'),
                self.nodes().controllers
                + self.nodes().computes
                + self.nodes().storages),
            quantums=self.nodes().quantums, 
            quantum=False) 
        self.deploy_compact(quantum_node=False) 

    def test_deploy_compact_wo_quantum_cinder_all(self): 
        Manifest().generate_openstack_manifest(
            template=Template.compact(), ci=self.ci(),
            controllers=self.nodes().controllers, 
            cinder=True,
            cinder_nodes=['all'],
            quantums=self.nodes().quantums, 
            quantum=False) 
        self.deploy_compact(quantum_node=False) 

    def test_deploy_compact_wo_loopback(self):
        Manifest().generate_openstack_manifest(
            template=Template.compact(), ci=self.ci(),
            controllers=self.nodes().controllers,
            quantums=self.nodes().quantums,
            quantum=False, loopback=False, use_syslog=False)
        self.deploy_compact(quantum_node=False, loopback=False)

    def test_deploy_compact_wo_ha_provider(self):
        Manifest().generate_openstack_manifest(
            template=Template.compact(), ci=self.ci(),
            controllers=self.nodes().controllers,
            quantums=self.nodes().quantums,
            quantum=False, use_syslog=False, ha_provider=False)
        self.deploy_compact(quantum_node=False)


if __name__ == '__main__':
    unittest.main()
