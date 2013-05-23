import unittest
from fuel_test.cobbler.vm_test_case import CobblerTestCase
from fuel_test.manifest import Manifest
from fuel_test.settings import OPENSTACK_SNAPSHOT, CREATE_SNAPSHOTS


class SingleTestCase(CobblerTestCase):
    def test_single(self):
        Manifest.write_manifest(
            self.remote(),
            Manifest().generate_openstack_single_manifest(
                ci=self.ci(),
                quantum=False,
            )
        )
        self.validate(
            self.nodes().controllers[:1],
            'puppet agent --test 2>&1')
        if CREATE_SNAPSHOTS:
            self.environment().snapshot(OPENSTACK_SNAPSHOT, force=True)

if __name__ == '__main__':
    unittest.main()
