import unittest
import os
import subprocess


class HieraPreTest(unittest.TestCase):
    def test_can_get_uid_with_puppet(self):
        hiera = subprocess.Popen(['which', 'hiera'],
                                 stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE)
        hiera.communicate()
        self.assertEqual(hiera.returncode, 0, 'Hiera is not installed!')

if __name__ == '__main__':
    unittest.main()