import unittest
from devops.helpers import ssh, os
from ci import get_environment, write_config
from root import root

class RecipeTestCase(unittest.TestCase):

    def setUp(self):
        self.environment = get_environment()
        master = self.environment.node['master']
        self.revert_snapshot()
        self.remote = ssh(master.ip_address, username='root', password='r00tme')
        self.remote.reconnect()
        self.upload_recipes()

    def upload_recipes(self):
        recipes_dir = root('fuel','deployment','puppet')
        for dir in os.listdir(recipes_dir):
            recipe_dir = os.path.join(recipes_dir, dir)
            remote_dir = "/etc/puppet/modules/"
            self.remote.mkdir(remote_dir)
            self.remote.upload(recipe_dir, remote_dir)

    def revert_snapshot(self):
        try:
            for node in self.environment.nodes:
                node.restore_snapshot('blank')
        except:
          pass

    def write_site_pp_manifests(self, remote):
        with open(root('fuel', 'fuel_test', 'nova.site.pp.template')) as f:
            site_pp = f.read()
        remote.mkdir('/etc/puppet/manifests/')
        write_config(remote, '/etc/puppet/manifests/site.pp', site_pp)

