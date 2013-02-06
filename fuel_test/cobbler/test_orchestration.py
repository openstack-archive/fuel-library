import unittest
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
        config_text = (
            "use_case: minimal\n"
            "fuel-controller-01.your-domain-name.com:\n"
            "  role: controller\n"
            "fuel-controller-02.your-domain-name.com:\n"
            "  role: controller\n"
            "fuel-compute-01.your-domain-name.com:\n"
            "  role: compute\n"
            "fuel-compute-02.your-domain-name.com:\n"
            "  role: compute\n"
            )
        remote = self.nodes().stomps[0].remote('public', login='root',
            password='r00tme')
        write_config(remote, '/tmp/nodes.yaml', config_text)
        remote.check_stderr('astute_run /tmp/nodes.yaml')

    def test_orchestrating_simple(self):
        Manifest().write_openstack_simple_manifest(
            remote=self.remote(),
            ci=self.ci(),
            controllers=self.nodes().controllers[:1])
        config_text = (
            "use_case: simple\n"
            "fuel-controller-01.your-domain-name.com:\n"
            "  role: controller\n"
            "fuel-controller-02.your-domain-name.com:\n"
            "  role: controller\n"
            "fuel-compute-01.your-domain-name.com:\n"
            "  role: compute\n"
            "fuel-compute-02.your-domain-name.com:\n"
            "  role: compute\n"
            )
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
        config_text = (
            "use_case: compact\n"
            "fuel-controller-01.your-domain-name.com:\n"
            "    role: controller\n"
            "fuel-controller-02.your-domain-name.com:\n"
            "    role: controller\n"
            "fuel-controller-03.your-domain-name.com:\n"
            "    role: controller\n"
            "fuel-compute-01.your-domain-name.com:\n"
            "    role: compute\n"
            "fuel-compute-02.your-domain-name.com:\n"
            "    role: compute\n"
            )
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
        config_text = (
            "use_case: full\n"
            "fuel-controller-01.your-domain-name.com:\n"
            "    role: controller\n"
            "fuel-controller-02.your-domain-name.com:\n"
            "    role: controller\n"
            "fuel-compute-01.your-domain-name.com:\n"
            "    role: compute\n"
            "fuel-compute-02.your-domain-name.com:\n"
            "    role: compute\n"
            "fuel-swift-01.your-domain-name.com:\n"
            "    role: storage\n"
            "fuel-swift-02.your-domain-name.com:\n"
            "    role: storage\n"
            "fuel-swift-03.your-domain-name.com:\n"
            "    role: storage\n"
            "fuel-swiftproxy-01.your-domain-name.com:\n"
            "    role: proxy\n"
            "fuel-swiftproxy-02.your-domain-name.com:\n"
            "    role: proxy\n"
            )
        remote = self.nodes().stomps[0].remote(login='root',
            password='r00tme')
        write_config(remote, '/tmp/nodes.yaml', config_text)
        remote.check_stderr('astute_run /tmp/nodes.yaml')


if __name__ == '__main__':
    unittest.main()
