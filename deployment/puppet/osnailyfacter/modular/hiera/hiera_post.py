import unittest
import os
import subprocess


class HieraPostTest(unittest.TestCase):
    def test_has_hiera_config(self):
        self.assertTrue(os.path.isfile('/etc/hiera.yaml'), 'Hiera config not found!')

    def test_has_hiera_puppet_config(self):
        self.assertTrue(os.path.isfile('/etc/puppet/hiera.yaml'), 'Puppet Hiera config not found!')

    def test_can_get_uid(self):
        hiera = subprocess.Popen(['hiera', 'uid'], stdout=subprocess.PIPE)
        out = hiera.communicate()[0].rstrip()
        self.assertNotEqual(out, 'nil', 'Could not get "uid" string from Hiera!')

if __name__ == '__main__':
    unittest.main()