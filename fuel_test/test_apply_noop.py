import logging
from devops.helpers import ssh
from django.utils.unittest.case import skip
from base import RecipeTestCase
from settings import NODES
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
        agent01 = self.environment.node[NODES[0]]
        agent02 = self.environment.node[NODES[1]]
        remote = ssh(agent01.ip_address, username='root', password='r00tme')
        virtual_ip = self.environment.network['public'].ip_addresses[-3]
        remote.reconnect()
        self.write_site_pp_manifest(
            root('fuel', 'deployment', 'puppet', 'openstack', 'examples', 'site.pp'),
            virtual_ip="'%s'" % virtual_ip,
            master_hostname="'%s'" % agent01.name,
            controller_public_addresses = [
                "%s" % agent01.ip_address_by_network['public'],
                "%s" % agent02.ip_address_by_network['public']
                ],
            controller_internal_addresses = [
                "%s" % agent01.ip_address_by_network['internal'],
                "%s" % agent02.ip_address_by_network['internal']
            ],
            controller_hostnames = [
                "%s" % agent01.name,
                "%s" % agent02.name],
            public_interface = "'eth2'",
            internal_interface = "'eth0'",
            internal_address = "$ipaddress_eth0",
            private_interface = "'eth1'"
        )
        result = remote.sudo.ssh.execute('puppet agent --test')
        self.assertEqual([], result['stderr'], result['stderr'])
        errors, warnings = self.parse_out(result['stdout'])
        self.assertEqual([], errors, errors)
        self.assertEqual([], warnings, warnings)

if __name__ == '__main__':
    unittest.main()
