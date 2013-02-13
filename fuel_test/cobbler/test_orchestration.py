import unittest
from fuel_test.astute import Astute
from fuel_test.cobbler.cobbler_test_case import CobblerTestCase
from fuel_test.helpers import    write_config
from fuel_test.manifest import Manifest, Template

class CobblerCase(CobblerTestCase):
    def test_orchestrating_minimal(self):
        Manifest().write_openstack_manifest(
            remote=self.remote(),
            template=Template.minimal(), ci=self.ci(),
            controllers=self.nodes().controllers[:2],
            quantums=self.nodes().quantums,
            swift=False,
            quantum=True)
        config_text = Astute.config('minimal', controllers=self.nodes().controllers,
            computes=self.nodes().computes)
        remote = self.nodes().stomps[0].remote('public', login='root',
            password='r00tme')
        write_config(remote, '/tmp/nodes.yaml', config_text)
        remote.check_stderr('astute_run /tmp/nodes.yaml')

    def test_orchestrating_simple(self):
        Manifest().write_openstack_simple_manifest(
            remote=self.remote(),
            ci=self.ci(),
            controllers=self.nodes().controllers[:1])
        config_text = Astute.config('simple', controllers=self.nodes().controllers[:1],
            computes=self.nodes().computes, quantums=self.nodes().quantums)
        remote = self.nodes().stomps[0].remote('public', login='root',
            password='r00tme')
        write_config(remote, '/tmp/nodes.yaml', config_text)
        remote.check_stderr('astute_run /tmp/nodes.yaml')

    def test_orchestrating_compact(self):
        Manifest().write_openstack_manifest(
            remote=self.remote(),
            template=Template.compact(), ci=self.ci(),
            controllers=self.nodes().controllers,
            quantums=self.nodes().quantums,
            quantum=True)
        config_text = Astute.config('compact', controllers=self.nodes().controllers,
            computes=self.nodes().computes, quantums=self.nodes().quantums)
        remote = self.nodes().stomps[0].remote('public', login='root',
            password='r00tme')
        write_config(remote, '/tmp/nodes.yaml', config_text)
        remote.check_stderr('astute_run /tmp/nodes.yaml')

    def test_orchestrating_full(self):
        Manifest().write_openstack_manifest(
            remote=self.remote(),
            template=Template.full(), ci=self.ci(),
            controllers=self.nodes().controllers,
            quantums=self.nodes().quantums,
            proxies=self.nodes().proxies,
            quantum=True)
        config_text = Astute.config('full', controllers=self.nodes().controllers,
            computes=self.nodes().computes,
            quantums=self.nodes().quantums,
            storages=self.nodes().storages,
            proxies=self.nodes().proxies)
        remote = self.nodes().stomps[0].remote(login='root',
            password='r00tme')
        write_config(remote, '/tmp/nodes.yaml', config_text)
        remote.check_stderr('astute_run /tmp/nodes.yaml')


if __name__ == '__main__':
    unittest.main()
