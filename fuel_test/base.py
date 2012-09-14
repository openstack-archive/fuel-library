import unittest
from devops.helpers import ssh
from ci import get_environment
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
        remote_dir = "/etc/puppet/modules/"
        self.remote.mkdir(remote_dir)
        self.remote.upload(recipes_dir, remote_dir)

    def revert_snapshot(self):
        try:
            for node in self.environment.nodes:
                node.restore_snapshot('blank')
        except:
          pass

