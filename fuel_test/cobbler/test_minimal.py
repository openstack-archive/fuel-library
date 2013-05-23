import unittest
from fuel_test.cobbler.cobbler_test_case import CobblerTestCase
from fuel_test.helpers import is_not_essex
from fuel_test.manifest import Manifest, Template
from fuel_test.settings import CREATE_SNAPSHOTS, DEBUG


class MinimalTestCase(CobblerTestCase):
    def test_minimal(self):
        Manifest().write_openstack_ha_minimal_manifest(
            remote=self.remote(),
            template=Template.minimal(), ci=self.ci(),
            controllers=self.nodes().controllers,
            quantums=self.nodes().quantums,
            quantum=True)
        if DEBUG:
            extargs = ' -vd --evaltrace'
        else:
            extargs = ''
        self.validate(self.nodes().controllers[:1], 'puppet agent --test'+extargs+' 2>&1')
        self.validate(self.nodes().controllers[1:], 'puppet agent --test'+extargs+' 2>&1')
        self.validate(self.nodes().controllers[:1], 'puppet agent --test'+extargs+' 2>&1')
        #if is_not_essex():
        #    self.validate(self.nodes().quantums, 'puppet agent --test'+extargs)
        self.validate(self.nodes().computes, 'puppet agent --test'+extargs+' 2>&1')
        if CREATE_SNAPSHOTS:
            self.environment().snapshot('minimal', force=True)

if __name__ == '__main__':
    unittest.main()
