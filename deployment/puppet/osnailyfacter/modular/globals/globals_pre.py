import subprocess
import unittest


class GlobalsPreTest(unittest.TestCase):
    def test_can_get_uid(self):
        hiera = subprocess.Popen(['hiera', 'uid'], stdout=subprocess.PIPE)
        out = hiera.communicate()[0].rstrip()
        self.assertNotEqual(out, 'nil',
                            'Could not get "uid" string from Hiera!')

if __name__ == '__main__':
    unittest.main()
