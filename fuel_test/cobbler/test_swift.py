import unittest
from fuel_test.cobbler.cobbler_test_case import CobblerTestCase
from fuel_test.manifest import Manifest

class SwiftCase(CobblerTestCase):
    def test_swift(self):
        Manifest().write_swift_manifest(remote=self.remote(),
            controllers=self.nodes().controllers)
        self.validate(self.nodes().controllers[0], 'puppet agent --test')
        self.do(self.nodes().storages, 'puppet agent --test')
        self.do(self.nodes().storages, 'puppet agent --test')
        self.validate(self.nodes().proxies[0], 'puppet agent --test')
        self.validate(self.nodes().storages, 'puppet agent --test')

if __name__ == '__main__':
    unittest.main()
