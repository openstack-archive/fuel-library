import unittest
from fuel_test.cobbler.vm_test_case import CobblerTestCase
from fuel_test.config import Config
from fuel_test.helpers import write_config
from fuel_test.manifest import Manifest, Template
from fuel_test.settings import CREATE_SNAPSHOTS, ASTUTE_USE


class MinimalTestCase(CobblerTestCase):
    def deploy(self):
        if ASTUTE_USE:
            self.prepare_astute()
            self.deploy_by_astute()
        else:
            self.prepare_only_site_pp()
            self.deploy_one_by_one()

    def deploy_one_by_one(self):
        self.validate(self.nodes().controllers[:1], 'puppet agent --test')
        self.validate(self.nodes().controllers[1:], 'puppet agent --test')
        self.validate(self.nodes().controllers[:1], 'puppet agent --test')
        self.validate(self.nodes().computes, 'puppet agent --test')

    def deploy_by_astute(self):
        self.remote().check_stderr("astute -f astute.yaml")

    def prepare_only_site_pp(self):
        manifest = Manifest().generate_openstack_manifest(
                template=Template.minimal(),
                ci=self.ci(),
                controllers=self.nodes().controllers,
                quantums=self.nodes().quantums,
                quantum=True
            )

        Manifest().write_manifest(remote=self.remote(), manifest=manifest)

    def prepare_astute(self):
        config = Config().generate(
                template=Template.minimal(),
                ci=self.ci(),
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
