import unittest
from fuel_test.cobbler.cobbler_test_case import CobblerTestCase
from fuel_test.manifest import Manifest
from fuel_test.settings import OPENSTACK_SNAPSHOT, CREATE_SNAPSHOTS, DEBUG


class SimpleTestCase(CobblerTestCase):
    def test_simple(self):
        Manifest().write_openstack_simple_manifest(
            remote=self.remote(),
            ci=self.ci(),
            controllers=self.nodes().controllers)
        if DEBUG:
            extargs = ' -vd --evaltrace'
        else:
            extargs = ''
        self.validate(
            self.nodes().controllers[:1] + self.nodes().computes,
            'puppet agent --test'+extargs+' 2>&1')
        if CREATE_SNAPSHOTS:
            self.environment().snapshot(OPENSTACK_SNAPSHOT, force=True)

if __name__ == '__main__':
    unittest.main()
