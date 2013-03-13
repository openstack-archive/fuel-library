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