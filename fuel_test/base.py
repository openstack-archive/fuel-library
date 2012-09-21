import unittest
from devops.helpers import ssh, os
import re
from ci import get_environment, write_config
from root import root

class RecipeTestCase(unittest.TestCase):

    def setUp(self):
        self.environment = get_environment()
        master = self.environment.node['master']
        self.revert_snapshot()
        self.master_remote = ssh(master.ip_address, username='root', password='r00tme')
        self.master_remote.reconnect()
        self.upload_recipes()

    def upload_recipes(self):
        recipes_dir = root('fuel','deployment','puppet')
        for dir in os.listdir(recipes_dir):
            recipe_dir = os.path.join(recipes_dir, dir)
            remote_dir = "/etc/puppet/modules/"
            self.master_remote.mkdir(remote_dir)
            self.master_remote.upload(recipe_dir, remote_dir)

    def revert_snapshot(self):
        for node in self.environment.nodes:
            node.restore_snapshot('blank')

    def load(self, path):
        with open(path) as f:
            return f.read()

    def replace(self, template, **kwargs):
        for key in kwargs:
            value=kwargs.get(key)
            template, count = re.subn('(\$' + str(key) + ').*=.*', "\\1 = " + str(value), template)
            if count == 0:
                raise Exception("Variable ${0:>s} is not found".format(key))
        return template

    def write_site_pp_manifest(self, path, **kwargs):
        site_pp = self.load(path)
        self.replace(site_pp, **kwargs)
        write_config(self.master_remote, '/etc/puppet/manifests/site.pp', site_pp)

