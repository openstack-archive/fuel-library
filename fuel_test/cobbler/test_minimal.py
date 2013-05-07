import unittest
from fuel_test.cobbler.vm_test_case import CobblerTestCase
from fuel_test.config import Config
from fuel_test.helpers import write_config
from fuel_test.manifest import Template
from fuel_test.settings import CREATE_SNAPSHOTS, ASTUTE_USE


class MinimalTestCase(CobblerTestCase):
    def deploy(self):
        self.prepare_astute()
        if ASTUTE_USE:
            self.deploy_by_astute()
        else:
            self.deploy_one_by_one()

    def deploy_one_by_one(self):
        self.validate(self.nodes().controllers[:1], 'puppet agent --test')
        self.validate(self.nodes().controllers[1:], 'puppet agent --test')
        self.validate(self.nodes().controllers[:1], 'puppet agent --test')
        self.validate(self.nodes().computes, 'puppet agent --test')

    def deploy_by_astute(self):
        self.remote().check_stderr("astute -f astute.yaml")

    def prepare_astute(self):
        config = Config().generate(
                template=Template.minimal(),
                ci=self.ci(),
                nodes = self.ci().nodes().controllers + self.ci().nodes().computes,
                quantums=self.nodes().quantums,
                quantum=True,
                cinder_nodes=['controller']
            )
        config_path = "/root/config.yaml"
        write_config(self.remote(), config_path, str(config))
        self.remote().check_stderr("openstack_system -c config.yaml -o /etc/puppet/manifests/site.pp -a astute.yaml")

    def test_minimal(self):
        self.deploy()
        if CREATE_SNAPSHOTS:
            self.environment().snapshot('minimal', force=True)

if __name__ == '__main__':
    unittest.main()
