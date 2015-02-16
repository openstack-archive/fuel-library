import unittest
import os
import subprocess


class FirewallPreTest(unittest.TestCase):
    def test_iptables_installed(self):
        hiera = subprocess.Popen(['which', 'iptables'],
                                 stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE)
        hiera.communicate()
        self.assertEqual(hiera.returncode, 0, 'Iptables not installed!')

if __name__ == '__main__':
    unittest.main()
