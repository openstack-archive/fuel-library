import unittest
from fuel_test.cobbler.vm_test_case import CobblerTestCase
from fuel_test.manifest import Manifest
from fuel_test.settings import OPENSTACK_SNAPSHOT, CREATE_SNAPSHOTS, PUPPET_AGENT_COMMAND


class SingleTestCase(CobblerTestCase):
    def test_single(self):
        Manifest.write_manifest(
            self.remote(),
            Manifest().generate_openstack_manifest(
                template=Template.single(),
                ci=self.ci(),
                controllers=self.nodes().controllers,
                use_syslog=True,
                quantum=False,
                ha=False, ha_provider='generic',
                cinder=True, cinder_nodes=['all'], swift=False
            )
        )
        self.validate(
            self.nodes().controllers[:1],
            PUPPET_AGENT_COMMAND)
        if CREATE_SNAPSHOTS:
            self.environment().snapshot(OPENSTACK_SNAPSHOT, force=True)

if __name__ == '__main__':
    unittest.main()
