from devops.helpers.helpers import ssh
from time import sleep
from fuel_test.ci.ci_vm import CiVM
from fuel_test.helpers import install_packages, switch_off_ip_tables
from fuel_test.prepare_tempest import PrepareTempest
from fuel_test.root import root
from fuel_test.settings import OS_FAMILY, ADMIN_USERNAME, ADMIN_PASSWORD, ADMIN_TENANT_FOLSOM


class PrepareTempestCI():
    def __init__(self, ha=False):
        self.controllers = self.ci().nodes().controllers
        if not ha:
            self.public_ip = self.controllers[0].get_ip_address_by_network_name('public')
            self.internal_ip = self.controllers[0].get_ip_address_by_network_name('internal')
        else:
            self.public_ip = self.ci().public_virtual_ip()
            self.internal_ip = self.ci().public_virtual_ip()

        self.username = ADMIN_USERNAME
        self.password = ADMIN_PASSWORD
        self.tenant = ADMIN_TENANT_FOLSOM
        self.prepare = self.prepare()

    def ci(self):
        if not hasattr(self, '_ci'):
            self._ci = CiVM()
        return self._ci

    def prepare(self):
        prepare = PrepareTempest(username=self.username,
                                      password=self.password,
                                      tenant=self.tenant,
                                      public_ip=self.public_ip,
                                      internal_ip=self.internal_ip)
        return prepare

    def remote(self):
        return ssh(self.public_ip, login='root', password='r00tme').sudo.ssh

    def make_shared_storage(self):
        self._make_shared_storage(self.ci().nodes().controllers[0].name,
                                  self.ci().nodes().controllers[1:],
                                  self.ci().internal_network())

    def prepare_tempest_folsom(self, template_folsom):
        self.prepare.prepare_tempest_folsom(template_folsom)

    def prepare_tempest_grizzly(self, template_grizzly):
        self.prepare.prepare_tempest_grizzly(template_grizzly)

    def prepare_tempest_essex(self, template_essex):
        self.prepare.prepare_tempest_essex(template_essex)

    def prepare_tempest_essex_minimal(self):
        self.make_shared_storage()
        template = root('fuel_test', 'config', 'tempest.conf.essex.sample')
        self.prepare.prepare_tempest_essex(template)

    def prepare_tempest_folsom_minimal(self):
        self.make_shared_storage()
        template = root('fuel_test', 'config', 'tempest.conf.folsom.sample')
        self.prepare.prepare_tempest_folsom(template)

    def tempest_share_glance_images(self, network):
        if OS_FAMILY == "centos":
            self.remote().check_stderr('chkconfig rpcbind on')
            self.remote().check_stderr('/etc/init.d/rpcbind restart')
            self.remote().check_stderr(
                'echo "/var/lib/glance/images %s(rw,no_root_squash)" >> /etc/exports' % network)
            self.remote().check_stderr('/etc/init.d/nfs restart')
        else:
            install_packages(self.remote(),
                             'nfs-kernel-server nfs-common portmap')
            self.remote().check_stderr(
                'echo "/var/lib/glance/images %s(rw,no_root_squash)" >> /etc/exports' % network)
            self.remote().check_stderr('/etc/init.d/nfs-kernel-server restart')

    def tempest_mount_glance_images(self, remote, host):
        if OS_FAMILY == "centos":
            remote.check_stderr('chkconfig rpcbind on')
            remote.check_stderr('/etc/init.d/rpcbind restart')
            remote.check_stderr(
                'mount %s:/var/lib/glance/images /var/lib/glance/images' % host)
        else:
            install_packages(remote, 'nfs-common portmap')
            remote.check_stderr(
                'mount %s:/var/lib/glance/images /var/lib/glance/images' % host)

    def _make_shared_storage(self, nfs_server, nfs_clients, access_network):
        self.tempest_share_glance_images(access_network)
        switch_off_ip_tables(self.remote())
        self.remote().check_stderr('/etc/init.d/iptables stop')
        sleep(15)
        for client in nfs_clients:
            remote = client.remote(
                'internal', login='root',
                password='r00tme').sudo.ssh
            self.tempest_mount_glance_images(remote, nfs_server)
        sleep(20)



