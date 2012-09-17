import logging
from devops.helpers import ssh
from django.utils.unittest.case import skip
from base import RecipeTestCase
from fuel_test.ci import write_config
from root import root

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

    @skip('debug')
    def test_apply_all_modules_with_noop(self):
        result = self.remote.execute("for i in `find /etc/puppet/modules/ | grep tests/.*pp`; do puppet apply  --modulepath=/etc/puppet/modules/ --noop $i ; done")
        self.assertEqual([], result['stderr'], result['stderr'])
        errors, warnings = self.parse_out(result['stdout'])
        self.assertEqual([], errors, errors)
        self.assertEqual([], warnings, warnings)


    def test_deploy_compute_node(self):
        node = self.environment.node['client']
        remote = ssh(node.ip_address, username='root', password='r00tme')
        self.remote.reconnect()
        with open(root('fuel', 'fuel_test', 'nova.site.pp.template')) as f:
            site_pp = f.read()
        write_config(remote, '/etc/puppet/manifests/site.pp', site_pp)



if __name__ == '__main__':
    unittest.main()
