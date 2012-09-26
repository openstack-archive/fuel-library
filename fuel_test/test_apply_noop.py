import logging
from devops.helpers import ssh, tcp_ping
from django.utils.unittest.case import skip
from base import RecipeTestCase
from helpers import execute
from settings import NODES
from root import root

import unittest

#todo raise exception if remote command writes to stderr or returns non-zero exit code
#todo pretty output
#todo async command execution with logging


class MyTestCase(RecipeTestCase):

    def test_apply_all_modules_with_noop(self):
        result = self.master_remote.execute("for i in `find /etc/puppet/modules/ | grep tests/.*pp`; do puppet apply  --modulepath=/etc/puppet/modules/ --noop $i ; done")
        self.assertResult(result)

    def test_deploy_controller_nodes(self):
        node01 = self.environment.node[NODES[0]]
        node02 = self.environment.node[NODES[1]]
        internal_virtual_ip = self.environment.network['internal'].ip_addresses[-3]
        public_virtual_ip = self.environment.network['public'].ip_addresses[-3]
        self.write_site_pp_manifest(
            root('fuel', 'deployment', 'puppet', 'openstack', 'examples', 'site.pp'),
            internal_virtual_ip="'%s'" % internal_virtual_ip,
            public_virtual_ip="'%s'" % public_virtual_ip,
            master_hostname="'%s'" % node01.name,
            controller_public_addresses = [
                "%s" % node01.ip_address_by_network['public'],
                "%s" % node02.ip_address_by_network['public']
                ],
            controller_internal_addresses = [
                "%s" % node01.ip_address_by_network['internal'],
                "%s" % node02.ip_address_by_network['internal']
            ],
            controller_hostnames = [
                "%s" % node01.name,
                "%s" % node02.name],
            public_interface = "'eth2'",
            internal_interface = "'eth0'",
            internal_address = "$ipaddress_eth0",
            private_interface = "'eth1'"
        )
        remote = ssh(node01.ip_address, username='root', password='r00tme')
        result = execute(remote.sudo.ssh, 'puppet agent --test')
        self.assertResult(result)

    def test_deploy_mysql_with_galera(self):
        node01 = self.environment.node[NODES[0]]
        node02 = self.environment.node[NODES[1]]
        self.write_site_pp_manifest(
            root('fuel', 'deployment', 'puppet', 'mysql', 'examples', 'site.pp'),
            master_hostname="'%s'" % node01.name,
            galera_master_ip = "'%s'" % node01.ip_address_by_network['internal'],
            galera_node_addresses = [
                "%s" % node01.ip_address_by_network['internal'],
                "%s" % node02.ip_address_by_network['internal']
            ],
        )
        remote = ssh(node01.ip_address, username='root', password='r00tme')
        result = remote.sudo.ssh.execute('puppet agent --test')
        self.assertResult(result)
        remote = ssh(node02.ip_address, username='root', password='r00tme')
        result = execute(remote.sudo.ssh, 'puppet agent --test')
        self.assertResult(result)
#        self.assertTrue(tcp_ping(node01.ip_address_by_network['internal'], 3306))

    def test_deploy_nova_rabbitmq(self):
        node01 = self.environment.node[NODES[0]]
        node02 = self.environment.node[NODES[1]]
        self.write_site_pp_manifest(
            root('fuel', 'deployment', 'puppet', 'nova', 'examples', 'nova_rabbitmq_site.pp'),
            cluster = 'true',
            cluster_nodes = [
                "%s" % node01.ip_address_by_network['internal'],
                "%s" % node02.ip_address_by_network['internal']
            ],
        )
        remote = ssh(node01.ip_address, username='root', password='r00tme')
        result1 = execute(remote.sudo.ssh, 'puppet agent --test')
        remote2 = ssh(node02.ip_address, username='root', password='r00tme')
        result2 = execute(remote2.sudo.ssh, 'puppet agent --test')
        self.assertResult(result1)
        self.assertResult(result2)

if __name__ == '__main__':
    unittest.main()
