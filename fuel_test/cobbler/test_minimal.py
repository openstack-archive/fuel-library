import unittest
from fuel_test.cobbler.vm_test_case import CobblerTestCase
from fuel_test.config import Config
from fuel_test.helpers import write_config
from fuel_test.manifest import Template, Manifest
from fuel_test.settings import CREATE_SNAPSHOTS, ASTUTE_USE, PUPPET_AGENT_COMMAND


class MinimalTestCase(CobblerTestCase):
    def deploy(self):
        if ASTUTE_USE:
            self.prepare_astute()
            self.deploy_by_astute()
        else:
            self.deploy_one_by_one()

    def deploy_one_by_one(self):
        manifest = Manifest().generate_openstack_manifest(
            template=Template.minimal(),
            ci=self.ci(),
            controllers=self.nodes().controllers,
            quantums=self.nodes().quantums,
            quantum=True)
        
        Manifest().write_manifest(remote=self.remote(), manifest=manifest)
        
        self.validate(self.nodes().controllers[:1], PUPPET_AGENT_COMMAND)
        self.validate(self.nodes().controllers[1:], PUPPET_AGENT_COMMAND)
        self.validate(self.nodes().controllers[:1], PUPPET_AGENT_COMMAND)
        self.validate(self.nodes().computes, PUPPET_AGENT_COMMAND)

    def deploy_by_astute(self):
        self.remote().check_stderr("astute -f /root/astute.yaml -v")

    def prepare_astute(self):
        config = Config().generate(
                template=Template.minimal(),
                ci=self.ci(),
                nodes = self.nodes().controllers + self.nodes().computes,
                quantums=self.nodes().quantums,
                quantum=True,
                cinder_nodes=['controller']
            )
        print "Generated config.yaml:", config
        config_path = "/root/config.yaml"
        write_config(self.remote(), config_path, str(config))
        self.remote().check_call("cobbler_system -f %s" % config_path)
        self.remote().check_stderr("openstack_system -c %s -o /etc/puppet/manifests/site.pp -a /root/astute.yaml" % config_path)

    def test_minimal(self):
        self.deploy()

        if CREATE_SNAPSHOTS:
            self.environment().snapshot('minimal', force=True)

if __name__ == '__main__':
    unittest.main()
