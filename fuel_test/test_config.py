import yaml
from fuel_test.base_test_case import BaseTestCase
from fuel_test.ci.ci_vm import CiVM
from fuel_test.config import Config
from fuel_test.manifest import Template

import unittest

class TestConfig(BaseTestCase):
    def ci(self):
        if not hasattr(self, '_ci'):
            self._ci = CiVM()
        return self._ci

    def test_generate_minimal(self):
        print Config().generate(
            ci=self.ci(),
            template=Template.minimal(),
            quantums=self.nodes().quantums,
            swift=False,
            loopback=False,
            use_syslog=False,
            quantum=True)

    def test_generate_compact(self):
        print Config().generate(
            ci=self.ci(),
            template=Template.compact(),
            quantums=self.nodes().quantums,
            swift=False,
            loopback=False,
            use_syslog=False,
            quantum=True)

    def test_generate_full(self):
        print Config().generate(
            ci=self.ci(),
            template=Template.full(),
            quantums=self.nodes().quantums,
            swift=False,
            loopback=False,
            use_syslog=False,
            quantum=True)

    def test_generate_simple(self):
        print Config().generate(
            ci=self.ci(),
            template=Template.simple())


    def test_generate_single(self):
        print Config().generate(
            ci=self.ci(),
            template=Template.single())


    def test_generate_stomp(self):
        print yaml.safe_dump(Config().generate(
            ci=self.ci(),
            template=Template.stomp()),
            default_flow_style=False)

if __name__ == '__main__':
    unittest.main()

