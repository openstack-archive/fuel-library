from openstack_site_pp_base import OpenStackSitePPBaseTestCase
import unittest


class NovaSubClassesTestCase(OpenStackSitePPBaseTestCase):
    def test_deploy_nova_compute(self):
        self.validate(
            [self.compute1, ],
            'puppet agent --test --tags openstack::repo::yum,%s' % "nova::compute")

    def test_deploy_nova_api_compute(self):
        self.validate(
            [self.compute1, ],
            'puppet agent --test --tags openstack::repo::yum,%s' % "nova::api")

    def test_deploy_nova_api_controller(self):
        self.validate(
            [self.controller1, ],
            'puppet agent --test --tags openstack::repo::yum,%s' % "nova::api")

    def test_deploy_nova_network(self):
        self.validate(
            [self.compute1, ],
            'puppet agent --test --tags openstack::repo::yum,%s' % "nova::network")

    def test_deploy_nova_consoleauth(self):
        self.validate(
            [self.controller1, self.controller2],
            'puppet agent --test --tags openstack::repo::yum,%s' % "nova::consoleauth")

    def test_deploy_nova_rabbitmq(self):
        self.validate(
            [self.controller1, self.controller2],
            'puppet agent --test --tags openstack::repo::yum,%s' % "nova::rabbitmq")

    def test_deploy_nova_utilities(self):
        self.validate(
            [self.compute1, ],
            'puppet agent --test --tags openstack::repo::yum,%s' % "nova::utilities")

    def test_deploy_nova_vncproxy(self):
        self.validate(
            [self.controller1, ],
            'puppet agent --test --tags openstack::repo::yum,%s' % "nova::vncproxy")

    def test_deploy_nova_volume(self):
        self.validate(
            [self.compute1, ],
            'puppet agent --test --tags openstack::repo::yum,%s' % "nova::volume")


if __name__ == '__main__':
    unittest.main()
