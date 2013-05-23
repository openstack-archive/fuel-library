from fuel_test.base_test_case import BaseTestCase
from fuel_test.ci.ci_vm import CiVM
from fuel_test.manifest import Manifest, Template

__author__ = 'alan'

import unittest


class TestManifest(BaseTestCase):

    def ci(self):
        if not hasattr(self, '_ci'):
            self._ci = CiVM()
        return self._ci

    def test_generate_minimal(self):
        Manifest().generate_openstack_manifest(
            template=Template.minimal(), ci=self.ci(),
            controllers=self.nodes().controllers,
            quantums=self.nodes().quantums,
            swift=False, loopback=False, use_syslog=False,
            quantum=True)

    def test_generate_compact(self):
        Manifest().generate_openstack_manifest(
            template=Template.compact(), ci=self.ci(),
            controllers=self.nodes().controllers,
            quantums=self.nodes().quantums,
            swift=False, loopback=False, use_syslog=False,
            quantum=True)

    def test_generate_full(self):
        Manifest().generate_openstack_manifest(
            template=Template.full(), ci=self.ci(),
            controllers=self.nodes().controllers,
            quantums=self.nodes().quantums,
            swift=False, loopback=False, use_syslog=False,
            quantum=True)

    def test_generate_simple(self):
        Manifest().generate_openstack_manifest(
            ci=self.ci(), template=Template.simple(),
            controllers=self.nodes().controllers,
            ha=False,
            quantums=self.nodes().quantums)

    def test_generate_single(self):
        Manifest().generate_openstack_single_manifest(
            ci=self.ci())

    def test_generate_swift(self):
        Manifest().generate_swift_manifest(self.nodes().controllers,self.nodes().proxies)

    def test_generate_stomp(self):
        Manifest().generate_stomp_manifest()

    def test_generate_nagios(self):
        Manifest().generate_nagios_manifest()


if __name__ == '__main__':
    unittest.main()
