import unittest
from fuel_test.cobbler.cobbler_test_case import CobblerTestCase
from fuel_test.helpers import is_not_essex
from fuel_test.manifest import Manifest, Template

class MinimalTestCase(CobblerTestCase):
    def test_minimal(self):
        Manifest().write_openstack_manifest(
            remote=self.remote(),
            template=Template.minimal(), ci=self.ci(),
            controllers=self.nodes().controllers,
            quantums=self.nodes().quantums,
            swift=False,
            quantum=True)
        self.validate(self.nodes().controllers[:1], 'puppet agent --test')
        self.validate(self.nodes().controllers[1:], 'puppet agent --test')
        self.validate(self.nodes().controllers[:1], 'puppet agent --test')
        if is_not_essex():
            self.validate(self.nodes().quantums, 'puppet agent --test')
        self.validate(self.nodes().computes, 'puppet agent --test')
        self.environment().snapshot('minimal', force=True)

if __name__ == '__main__':
    unittest.main()
