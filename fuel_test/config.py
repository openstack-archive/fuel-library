import json
import yaml
class Config(object):
    @classmethod
    def generate(cls, ci):
        config = {
            "common":
                { "orchestrator_common": cls.orchestrator_common(),
                  "openstack_common": cls.openstack_common(),
                  "cobbler_common": cls.cobbler_common(),
                  }
        }.update(cls.cobbler_nodes())

    @classmethod
    def orchestrator_common(cls):

        pass

    @classmethod
    def openstack_common(cls):
        pass

    @classmethod
    def cobbler_common(cls):
        pass

    @classmethod
    def cobbler_nodes(cls):
        pass

    def test(self):
        with open('1.yaml') as f:
            a = yaml.load(f)
            print json.dumps(a, indent=4)