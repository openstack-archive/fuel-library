import logging
from base import RecipeTestCase

logger = logging.getLogger('test_recepts')

import unittest

class MyTestCase(RecipeTestCase):

    def parse_out(self, out):
        errors = []
        warnings = []
        for line in out:
            logger.info(line)
            if line.find('error:') !=-1:
                errors.append(line)
            if line.find('warning:') !=-1:
                warnings.append(line)
        return errors, warnings

    def test_apply_all_modules_with_noop(self):
        result = self.remote.execute("for i in `find /etc/puppet/modules/ | grep tests/.*pp`; do puppet apply  --modulepath=/etc/puppet/modules/puppet/ --noop $i ; done")
        self.assertEqual([], result['stderr'], result['stderr'])
        errors, warnings = self.parse_out(result['stdout'])
        self.assertEqual([], errors, errors)
        self.assertEqual([], warnings, warnings)

if __name__ == '__main__':
    unittest.main()
