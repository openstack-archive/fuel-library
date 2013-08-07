from fuel_test.cobbler.vm_test_case import CobblerTestCase
import unittest
from fuel_test.config import Config
from fuel_test.helpers import write_config
from fuel_test.manifest import Manifest, Template
from fuel_test.settings import ASTUTE_USE, PUPPET_AGENT_COMMAND


class CompactTestCase(CobblerTestCase):
    def deploy_compact(self, manifest, quantum_node=True, loopback=True):
        Manifest().write_manifest(remote=self.remote(), manifest=manifest)
        self.validate(self.nodes().controllers[:1], PUPPET_AGENT_COMMAND)
        self.validate(self.nodes().controllers[1:], PUPPET_AGENT_COMMAND)
        self.validate(self.nodes().controllers[:1], PUPPET_AGENT_COMMAND)
        if quantum_node:
            self.validate(self.nodes().quantums, PUPPET_AGENT_COMMAND)
        self.validate(self.nodes().computes, PUPPET_AGENT_COMMAND)

    def test_deploy_compact_quantum(self):
        if ASTUTE_USE:
            config = Config().generate(
                template=Template.compact(),
                ci=self.ci(),
                nodes = self.nodes().controllers,
                quantums=self.nodes().quantums,
                quantum=True,
                cinder_nodes=['controller'])
            self.deploy_by_astute(config)
        else:
            manifest = Manifest().generate_openstack_manifest(
                template=Template.compact(), ci=self.ci(),
                controllers=self.nodes().controllers,
                quantums=self.nodes().quantums,
                quantum=True,
                cinder_nodes=['controller']
            )

            self.deploy_compact(manifest=manifest, quantum_node=False)

    def test_deploy_compact_quantum_standalone(self):
        if ASTUTE_USE:
            config = Config().generate(
                template=Template.compact(),
                ci=self.ci(),
                nodes = self.nodes().controllers,
                quantums=self.nodes().quantums,
                quantum=True, quantum_netnode_on_cnt=False,
                cinder_nodes=['controller'])
            self.deploy_by_astute(config)
        else:
            manifest = Manifest().generate_openstack_manifest(
                template=Template.compact(), ci=self.ci(),
                controllers=self.nodes().controllers,
                quantums=self.nodes().quantums,
                quantum=True, quantum_netnode_on_cnt=False, ha_provider=False,
                cinder_nodes=['controller'])
            self.deploy_compact(manifest=manifest, quantum_node=True)

    def test_deploy_compact_wo_quantum(self):
        if ASTUTE_USE:
            config = Config().generate(
                template=Template.compact(),
                ci=self.ci(),
                nodes = self.nodes().controllers,
                quantums=self.nodes().quantums,
                quantum=False,
                cinder_nodes=['controller'])
            self.deploy_by_astute(config)
        else:
            manifest = Manifest().generate_openstack_manifest(
                template=Template.compact(), ci=self.ci(),
                controllers=self.nodes().controllers,
                quantums=self.nodes().quantums,
                quantum=False,
                cinder_nodes=['controller'])
            self.deploy_compact(manifest=manifest, quantum_node=False)

    def test_deploy_compact_wo_quantum_cinder_all_by_ipaddr(self):
        if ASTUTE_USE:
            config = Config().generate(
                template=Template.compact(),
                ci=self.ci(),
                nodes = self.nodes().controllers + self.nodes().computes,
                quantums=self.nodes().quantums,
                quantum=False,
                cinder=True,
                cinder_nodes=map(
                    lambda x: x.get_ip_address_by_network_name('internal'),
                    self.nodes().controllers
                    + self.nodes().computes
                    + self.nodes().storages),)
            self.deploy_by_astute(config)
        else:
            manifest = Manifest().generate_openstack_manifest(
                template=Template.compact(), ci=self.ci(),
                controllers=self.nodes().controllers,
                cinder=True,
                cinder_nodes=map(
                    lambda x: x.get_ip_address_by_network_name('internal'),
                    self.nodes().controllers
                    + self.nodes().computes
                    + self.nodes().storages),
                quantums=self.nodes().quantums,
                quantum=False,)
            self.deploy_compact(manifest=manifest,  quantum_node=False)

    def test_deploy_compact_wo_quantum_cinder_all(self):
        if ASTUTE_USE:
            config = Config().generate(
                template=Template.compact(),
                ci=self.ci(),
                nodes = self.nodes().controllers + self.nodes().computes,
                quantums=self.nodes().quantums,
                quantum=True,
                cinder=True,
                cinder_nodes=['all'])
            self.deploy_by_astute(config)
        else:
            manifest = Manifest().generate_openstack_manifest(
                template=Template.compact(), ci=self.ci(),
                controllers=self.nodes().controllers,
                cinder=True,
                cinder_nodes=['all'],
                quantums=self.nodes().quantums,
                quantum=False)
            self.deploy_compact(manifest=manifest, quantum_node=False)

    def test_deploy_compact_wo_loopback(self):
        if ASTUTE_USE:
            config = Config().generate(
                template=Template.compact(),
                ci=self.ci(),
                nodes = self.nodes().controllers,
                quantums=self.nodes().quantums,
                quantum=False, loopback=False, use_syslog=False,
                cinder_nodes=['controller'])
            self.deploy_by_astute(config)
        else:
            manifest = Manifest().generate_openstack_manifest(
                template=Template.compact(), ci=self.ci(),
                controllers=self.nodes().controllers,
                quantums=self.nodes().quantums,
                quantum=False, loopback=False, use_syslog=False,
                cinder_nodes=['controller'])
            self.deploy_compact(manifest=manifest, quantum_node=False, loopback=False)

    def test_deploy_compact_wo_ha_provider(self):
        if ASTUTE_USE:
            config = Config().generate(
                template=Template.compact(),
                ci=self.ci(),
                nodes = self.nodes().controllers,
                quantums=self.nodes().quantums,
                quantum=False, use_syslog=False,
                cinder_nodes=['controller'])
            self.deploy_by_astute(config)
        else:
            manifest = Manifest().generate_openstack_manifest(
                template=Template.compact(), ci=self.ci(),
                controllers=self.nodes().controllers,
                quantums=self.nodes().quantums,
                quantum=False, use_syslog=False, ha_provider=False,
                cinder_nodes=['controller'])
            self.deploy_compact(manifest=manifest, quantum_node=False)

    def deploy_by_astute(self, config):
        print "config.yaml:", config
        config_path = "/root/config.yaml"
        write_config(self.remote(), config_path, str(config))
        self.remote().check_call("cobbler_system -f %s" % config_path)
        self.remote().check_stderr("openstack_system -c %s -o /etc/puppet/manifests/site.pp -a /root/astute.yaml" % config_path, True)
        self.remote().check_stderr("astute -f /root/astute.yaml -v", True)

if __name__ == '__main__':
    unittest.main()
