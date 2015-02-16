import os
import unittest


class GlobalsPostTest(unittest.TestCase):
    FILE = '/etc/hiera/globals.yaml'

    def test_has_globals_yaml(self):
        self.assertTrue(os.path.isfile(self.FILE),
                        'Globals yaml not found!')

    def test_has_use_neutron_key(self):
        globals_file = open(self.FILE, 'r')
        globals_data = globals_file.read()
        globals_file.close()
        self.assertTrue('use_neutron' in globals_data,
                        'use_neutron was not found in globals!')


if __name__ == '__main__':
    unittest.main()
