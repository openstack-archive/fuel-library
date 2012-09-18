import logging
from devops.helpers import ssh
from django.utils.unittest.case import skip
from base import RecipeTestCase
from fuel_test.ci import write_config
from root import root

logger = logging.getLogger('test_recepts')

import unittest

#todo raise exception if remote command writes to stderr or returns non-zero exit code
#todo pretty output
#todo async command execution with logging


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

    @skip('debug')
    def test_apply_all_modules_with_noop(self):
        result = self.master_remote.execute("for i in `find /etc/puppet/modules/ | grep tests/.*pp`; do puppet apply  --modulepath=/etc/puppet/modules/ --noop $i ; done")
        self.assertEqual([], result['stderr'], result['stderr'])
        errors, warnings = self.parse_out(result['stdout'])
        self.assertEqual([], errors, errors)
        self.assertEqual([], warnings, warnings)

    def test_deploy_compute_node(self):
        node = self.environment.node['agent-01']
        remote = ssh(node.ip_address, username='root', password='r00tme')
        remote.reconnect()
        self.write_site_pp_manifest()
        result = remote.sudo.ssh.execute('puppet agent --test')
        self.assertEqual([], result['stderr'], result['stderr'])
        errors, warnings = self.parse_out(result['stdout'])
        self.assertEqual([], errors, errors)
        self.assertEqual([], warnings, warnings)

if __name__ == '__main__':
    unittest.main()
