import unittest
from fuel_test.cobbler.vm_test_case import CobblerTestCase
from fuel_test.config import Config
from fuel_test.manifest import Manifest, Template
from fuel_test.settings import CREATE_SNAPSHOTS


class MinimalTestCase(CobblerTestCase):

    def deploy_one_by_one(self):
        self.validate(self.nodes().controllers[:1], 'puppet agent --test')
        self.validate(self.nodes().controllers[1:], 'puppet agent --test')
        self.validate(self.nodes().controllers[:1], 'puppet agent --test')
        self.validate(self.nodes().computes, 'puppet agent --test')

    def _deploy(self):
        #
        #astute.run
        pass

    def deploy(self):
        #if DEBUG
            self.deploy_minimal_one_by_one()
        #else
            self._deploy()

    def prepare_only_site_pp(self):
        Manifest.write_manifest(
            self.remote(),
            Manifest().generate_openstack_manifest(
                template=Template.minimal(), ci=self.ci(),
                controllers=self.nodes().controllers,
                quantums=self.nodes().quantums,
                quantum=True
            )
        )

    def prepare_astute(self):
        Config().write_config(
            self.remote(),
            Config().generate(
                template=Template.minimal(),
                ci=self.ci(),
                quantums=self.nodes().quantums,
                quantum=True
            )
        )

    def test_minimal(self):
        self.deploy()
        if CREATE_SNAPSHOTS:
            self.environment().snapshot('minimal', force=True)

if __name__ == '__main__':
    unittest.main()
