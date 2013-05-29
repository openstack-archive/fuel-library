import unittest
from fuel_test.cobbler.vm_test_case import CobblerTestCase

class NoopTestCase(CobblerTestCase):
    def test_apply_all_modules_with_noop(self):
        result = self.remote().execute(
            "for i in `find /etc/puppet/modules/ | grep tests/.*pp`; do puppet apply  --modulepath=/etc/puppet/modules/ --noop $i ; done")
        self.assertResult(result)

if __name__ == '__main__':
    unittest.main()
