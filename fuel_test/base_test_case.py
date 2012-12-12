import logging
import unittest
from abc import abstractproperty
from devops.helpers import ssh
import re
from fuel_test.ci.ci_base import CiBase
from fuel_test.settings import ERROR_PREFIX, WARNING_PREFIX, EMPTY_SNAPSHOT
from helpers import load, execute, write_config, sync_time, safety_revert_nodes, upload_recipes, upload_keys, update_pm

class BaseTestCase(unittest.TestCase):
    @abstractproperty
    def ci(self):
        """
        :rtype : CiBase
        """
        pass

    def setUp(self):
        self.environment = self.ci().get_environment_or_create()
        self.nodes = self.ci().nodes()
        master = self.environment.node['master']
        self.revert_snapshots()
        self.master_remote = ssh(master.ip_address_by_network['public'],
            username='root',
            password='r00tme')
        upload_recipes(self.master_remote)
        upload_keys(self.master_remote)

    def revert_snapshots(self):
        safety_revert_nodes(self.environment.nodes, EMPTY_SNAPSHOT)
        for node in self.environment.nodes:
            remote = ssh(node.ip_address_by_network['internal'], username='root', password='r00tme')
            sync_time(remote.sudo.ssh)
            update_pm(remote.sudo.ssh)

    def replace(self, template, **kwargs):
        for key in kwargs:
            value = kwargs.get(key)
            template, count = re.subn(
                '^(\$' + str(key) + ')\s*=.*', "\\1 = " + str(value),
                template,
                flags=re.MULTILINE)
            if count == 0:
                raise Exception("Variable ${0:>s} is not found".format(key))
        return template

    def write_site_pp_manifest(self, path, **kwargs):
        site_pp = load(path)
        site_pp = self.replace(site_pp, **kwargs)
        write_config(self.master_remote, '/etc/puppet/manifests/site.pp',
            site_pp)

    def assertResult(self, result):
        self.assertEqual([], result['stderr'], result['stderr'])
        errors, warnings = self.parse_out(result['stdout'])
        self.assertEqual([], errors, errors)
        self.assertEqual([], warnings, warnings)

    def parse_out(self, out):
        errors = []
        warnings = []
        for line in out:
            logging.info(line)
            if (line.find(ERROR_PREFIX) < 15) and (line.find(ERROR_PREFIX) !=-1):
                errors.append(line)
            if (line.find(WARNING_PREFIX) < 15) and (line.find(WARNING_PREFIX) !=-1):
                warnings.append(line)
        return errors, warnings

    def do(self, nodes, command):
        results = []
        for node in nodes:
            remote = ssh(node.ip_address_by_network['internal'], username='root', password='r00tme')
            results.append(execute(remote.sudo.ssh, command))
        return results

    def validate(self, nodes, command):
        results = self.do(nodes, command)
        for result in results:
            self.assertResult(result)


