import unittest
from fuel_test.cobbler.cobbler_test_case import CobblerTestCase
from fuel_test.helpers import is_not_essex
from fuel_test.manifest import Manifest, Template
from fuel_test.settings import CREATE_SNAPSHOTS


class FullTestCase(CobblerTestCase):
    def test_full(self):
        Manifest().write_openstack_manifest(
            remote=self.remote(),
            template=Template.full(), ci=self.ci(),
            controllers=self.nodes().controllers,
            proxies=self.nodes().proxies,
            quantums=self.nodes().quantums,
            quantum=True)
        self.validate(self.nodes().proxies[:1], 'puppet agent --test 2>&1')
        self.validate(self.nodes().proxies[1:], 'puppet agent --test 2>&1')
        self.validate(self.nodes().storages, 'puppet agent --test 2>&1')
        self.validate(self.nodes().controllers[:1], 'puppet agent --test 2>&1')
        self.validate(self.nodes().controllers[1:], 'puppet agent --test 2>&1')
        self.validate(self.nodes().controllers[:1], 'puppet agent --test 2>&1')
        self.validate(self.nodes().computes, 'puppet agent --test 2>&1')
        if CREATE_SNAPSHOTS:
            self.environment().snapshot('full', force=True)

if __name__ == '__main__':
    unittest.main()
