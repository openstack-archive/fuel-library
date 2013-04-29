from fuel_test.cobbler.cobbler_test_case import CobblerTestCase
from fuel_test.helpers import is_not_essex
import unittest
from fuel_test.manifest import Manifest, Template
from fuel_test.settings import CREATE_SNAPSHOTS


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
        Manifest().write_openstack_manifest(
            remote=self.remote(),
            template=Template.compact(), ci=self.ci(),
            controllers=self.nodes().controllers,
            quantums=self.nodes().quantums,
            quantum=True)
        self.deploy_compact(quantum_node=False)
        if CREATE_SNAPSHOTS:
            self.environment().snapshot('compact', force=True)

    def test_deploy_compact_quantum_standalone(self):
        Manifest().write_openstack_manifest(
            remote=self.remote(),
            template=Template.compact(), ci=self.ci(),
            controllers=self.nodes().controllers,
            quantums=self.nodes().quantums,
            quantum=True, quantum_netnode_on_cnt=False, ha_provider=False)
        self.deploy_compact(quantum_node=True)
        if CREATE_SNAPSHOTS:
            self.environment().snapshot('compact', force=True)

    def test_deploy_compact_wo_quantum(self):
        Manifest().write_openstack_manifest(
            remote=self.remote(),
            template=Template.compact(), ci=self.ci(),
            controllers=self.nodes().controllers,
            quantums=self.nodes().quantums,
            quantum=False)
        self.deploy_compact(quantum_node=False)
        if CREATE_SNAPSHOTS:
            self.environment().snapshot('compact_wo_quantum', force=True)

    def test_deploy_compact_wo_quantum_cinder_all_by_ipaddr(self): 
        Manifest().write_openstack_manifest( 
            remote=self.remote(), 
            template=Template.compact(), ci=self.ci(), 
            controllers=self.nodes().controllers, 
            cinder=True,
            cinder_nodes=lambda x: x.get_ip_address_by_network_name('internal'), ci.nodes().controllers + ci.nodes().computes+ ci.nodes().storages),
            quantums=self.nodes().quantums, 
            quantum=False) 
        self.deploy_compact(quantum_node=False) 
        if CREATE_SNAPSHOTS: 
            self.environment().snapshot('compact_wo_quantum_cinderip', force=True) 

    def test_deploy_compact_wo_quantum_cinder_all(self): 
        Manifest().write_openstack_manifest( 
            remote=self.remote(), 
            template=Template.compact(), ci=self.ci(), 
            controllers=self.nodes().controllers, 
            cinder=True,
            cinder_nodes=['all'],
            quantums=self.nodes().quantums, 
            quantum=False) 
        self.deploy_compact(quantum_node=False) 
        if CREATE_SNAPSHOTS: 
            self.environment().snapshot('compact_wo_quantum_cinderall', force=True) 
 
    def test_deploy_compact_wo_loopback(self):
        Manifest().write_openstack_manifest(
            remote=self.remote(),
            template=Template.compact(), ci=self.ci(),
            controllers=self.nodes().controllers,
            quantums=self.nodes().quantums,
            quantum=False, loopback=False, use_syslog=False)
        self.deploy_compact(quantum_node=False, loopback=False)
        if CREATE_SNAPSHOTS:
            self.environment().snapshot('compact_woloopback', force=True)

    def test_deploy_compact_wo_ha_provider(self):
        Manifest().write_openstack_manifest(
            remote=self.remote(),
            template=Template.compact(), ci=self.ci(),
            controllers=self.nodes().controllers,
            quantums=self.nodes().quantums,
            quantum=False, use_syslog=False, ha_provider=False)
        self.deploy_compact(quantum_node=False)
        if CREATE_SNAPSHOTS:
            self.environment().snapshot('compact_wo_ha_provider', force=True)


if __name__ == '__main__':
    unittest.main()
