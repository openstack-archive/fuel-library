from fuel_test.settings import DOMAIN_NAME

__author__ = 'vic'
import yaml

class Astute(object):
    @classmethod
    def config(cls, use_case, controllers, computes=None, storages=None,
               proxies=None,
               quantums=None):
        if not quantums: quantums = []
        if not proxies: proxies = []
        if not storages: storages = []
        if not computes: computes = []
        config = {
            'common' : {
                'orchestrator_common' : { 'use_case': use_case, 'domain_name': DOMAIN_NAME }
            }
        }
        map(lambda x: config.update({str(x.name): {'role': 'controller'}}), controllers)
        map(lambda x: config.update({str(x.name): {'role': 'compute'}}), computes)
        map(lambda x: config.update({str(x.name): {'role': 'storage'}}), storages)
        map(lambda x: config.update({str(x.name): {'role': 'swift-proxy'}}), proxies)
        map(lambda x: config.update({str(x.name): {'role': 'quantum'}}), quantums)
        return yaml.dump(config)

    def test_minimal_config(self):
        class Node(object):
            def __init__(self, name):
                super(Node, self).__init__()
                self.name = name
        print Astute.config('minimal', [Node('a'), Node('c')], [Node('d'), Node('r')])

