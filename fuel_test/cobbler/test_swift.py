import unittest
from fuel_test.cobbler.vm_test_case import CobblerTestCase
from fuel_test.manifest import Manifest
from fuel_test.settings import DEBUG

class SwiftCase(CobblerTestCase):


    def test_swift(self):
        Manifest.write_manifest(
            self.remote(),
            Manifest().generate_swift_manifest(
            controllers=self.nodes().controllers)
        )
        if DEBUG:
            extargs = ' -vd --evaltrace'
        else:
            extargs = ''
        self.validate(self.nodes().controllers[0], 'puppet agent --test'+extargs+' 2>&1')
        self.do(self.nodes().storages, 'puppet agent --test'+extargs+' 2>&1')
        self.do(self.nodes().storages, 'puppet agent --test'+extargs+' 2>&1')
        self.validate(self.nodes().proxies[0], 'puppet agent --test'+extargs+' 2>&1')
        self.validate(self.nodes().storages, 'puppet agent --test'+extargs+' 2>&1')

if __name__ == '__main__':
    unittest.main()
