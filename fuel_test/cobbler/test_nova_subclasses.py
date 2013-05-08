import unittest
from fuel_test.cobbler.vm_test_case import CobblerTestCase
from fuel_test.manifest import Manifest, Template


class NovaSubClassesTestCase(CobblerTestCase):
    def setUp(self):
        super(NovaSubClassesTestCase, self).setUp()
        Manifest.write_manifest(
            self.remote(),
            Manifest().generate_openstack_manifest(
                template=Template.full(), ci=self.ci(),
                controllers=self.nodes().controllers,
                proxies=self.nodes().proxies,
                quantums=self.nodes().quantums,
                quantum=True)
        )

    def test_deploy_nova_compute(self):
        self.validate(
            [self.nodes().computes[0], ],
            'puppet agent --test --tags openstack::mirantis_repos,%s' % "nova::compute")

    def test_deploy_nova_api_compute(self):
        self.validate(
            [self.nodes().computes[0], ],
            'puppet agent --test --tags openstack::mirantis_repos,%s' % "nova::api")

    def test_deploy_nova_api_controller(self):
        self.validate(
            [self.nodes().controllers[0], ],
            'puppet agent --test --tags openstack::mirantis_repos,%s' % "nova::api")

    def test_deploy_nova_network(self):
        self.validate(
            [self.nodes().computes[0], ],
            'puppet agent --test --tags openstack::mirantis_repos,%s' % "nova::network")

    def test_deploy_nova_consoleauth(self):
        self.validate(
            [self.nodes().controllers[0], self.nodes().controllers[1]],
            'puppet agent --test --tags openstack::mirantis_repos,%s' % "nova::consoleauth")

    def test_deploy_nova_rabbitmq(self):
        self.validate(
            [self.nodes().controllers[0], self.nodes().controllers[1]],
            'puppet agent --test --tags openstack::mirantis_repos,%s' % "nova::rabbitmq")

    def test_deploy_nova_utilities(self):
        self.validate(
            [self.nodes().computes[0], ],
            'puppet agent --test --tags openstack::mirantis_repos,%s' % "nova::utilities")

    def test_deploy_nova_vncproxy(self):
        self.validate(
            [self.nodes().controllers[0], ],
            'puppet agent --test --tags openstack::mirantis_repos,%s' % "nova::vncproxy")

    def test_deploy_nova_volume(self):
        self.validate(
            [self.nodes().computes[0], ],
            'puppet agent --test --tags openstack::mirantis_repos,%s' % "nova::volume")

if __name__ == '__main__':
    unittest.main()
