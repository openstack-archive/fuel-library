from time import sleep
import unittest
from devops.error import TimeoutError
from fuel_test.base_test_case import BaseTestCase
from fuel_test.ci.ci_cobbler import CiCobbler
from fuel_test.cobbler.cobbler_client import CobblerClient
from fuel_test.helpers import tcp_ping, udp_ping, build_astute, install_astute, add_to_hosts, await_node_deploy
from fuel_test.manifest import Manifest, Template
from fuel_test.settings import PUPPET_VERSION, OS_FAMILY, CLEAN, DEBUG


class CobblerTestCase(BaseTestCase):
    def ci(self):
        if not hasattr(self, '_ci'):
            self._ci = CiCobbler()
        return self._ci

    def generate_manifests(self):
        Manifest().write_openstack_manifest(
            remote=self.remote(),
            template=Template.minimal(), ci=self.ci(),
            controllers=self.nodes().controllers,
            quantums=self.nodes().quantums,
            swift=False,
            quantum=True)
        Manifest().write_openstack_manifest(
            remote=self.remote(),
            template=Template.compact(), ci=self.ci(),
            controllers=self.nodes().controllers,
            quantums=self.nodes().quantums,
            quantum=False, loopback=False, use_syslog=False)
        Manifest().write_openstack_manifest(
            remote=self.remote(),
            template=Template.compact(), ci=self.ci(),
            controllers=self.nodes().controllers,
            quantums=self.nodes().quantums,
            quantum=False)
        Manifest().write_openstack_manifest(
            remote=self.remote(),
            template=Template.full(), ci=self.ci(),
            controllers=self.nodes().controllers,
            quantums=self.nodes().quantums,
            proxies=self.nodes().proxies,
            quantum=True)
        Manifest().write_openstack_simple_manifest(
            remote=self.remote(),
            ci=self.ci(),
            controllers=self.nodes().controllers)
        Manifest().write_openstack_single_manifest(
            remote=self.remote(),
            ci=self.ci())

    def setUp(self):
        if CLEAN:
            self.get_nodes_deployed_state()
        self.generate_manifests()
        self.update_modules()

    def get_nodes_deployed_state(self):
        if not self.environment().has_snapshot('nodes-deployed'):
            self.ci().get_empty_state()
            self.update_modules()
            self.prepare_cobbler_environment()
        self.environment().revert('nodes-deployed')
        for node in self.nodes():
            node.await('internal')

    def prepare_cobbler_environment(self):
        self.deploy_cobbler()
        self.configure_cobbler()
        self.deploy_stomp_node()
        self.deploy_nodes()

    def deploy_cobbler(self):
        Manifest().write_cobbler_manifest(self.remote(), self.ci(),
            self.nodes().cobblers)
        if DEBUG:
            extargs = ' -vd --evaltrace'
        else:
            extargs = ''
        self.validate(
            self.nodes().cobblers,
            'puppet agent --test'+extargs)
        for node in self.nodes().cobblers:
            self.assert_cobbler_ports(
                node.get_ip_address_by_network_name('internal'))
        self.environment().snapshot('cobbler', force=True)

    def assert_cobbler_ports(self, ip):
        closed_tcp_ports = filter(
            lambda port: not tcp_ping(
                self.remote().sudo.ssh,
                ip,
                port), [22, 53, 80, 443])
        closed_udp_ports = filter(
            lambda port: not udp_ping(
                self.remote().sudo.ssh,
                ip, port), [53, 67, 68, 69])
        self.assertEquals(
            {'tcp': [], 'udp': []},
            {'tcp': closed_tcp_ports, 'udp': closed_udp_ports})

    def deploy_stomp_node(self):
        Manifest().write_stomp_manifest(self.remote())
        if DEBUG:
            extargs = ' -vd --evaltrace'
        else:
            extargs = ''
        self.validate(
            self.nodes().stomps,
            'puppet agent --test'+extargs)
        self.install_astute_gem()

    def install_astute_gem(self):
        build_astute()
        install_astute(self.nodes().stomps[0].remote('public',
            login='root',
            password='r00tme'))

    def get_ks_meta(self, puppet_master, mco_host):
        return  ("puppet_auto_setup=1 "
                 "puppet_master=%(puppet_master)s "
                 "puppet_version=%(puppet_version)s "
                 "puppet_enable=0 "
                 "mco_auto_setup=1 "
                 "ntp_enable=1 "
                 "mco_pskey=un0aez2ei9eiGaequaey4loocohjuch4Ievu3shaeweeg5Uthi "
                 "mco_stomphost=%(mco_host)s "
                 "mco_stompport=61613 "
                 "mco_stompuser=mcollective "
                 "mco_stomppassword=AeN5mi5thahz2Aiveexo "
                 "mco_enable=1 "
                 "interface_extra_eth0_peerdns=no "
                 "interface_extra_eth1_peerdns=no "
                 "interface_extra_eth2_peerdns=no "
                 "interface_extra_eth2_promisc=yes "
                 "interface_extra_eth2_userctl=yes "
                    ) % {'puppet_master': puppet_master,
                         'puppet_version': PUPPET_VERSION,
                         'mco_host': mco_host
                }

    def add_fake_nodes(self):
        cobbler = self.ci().nodes().cobblers[0]
        stomp_name = self.ci().nodes().stomps[0].name
        client = CobblerClient(
            cobbler.get_ip_address_by_network_name('internal'))
        token = client.login('cobbler', 'cobbler')
        for i in range(1, 100):
            for j in range(1, 100):
                self._add_node(
                    client, token, cobbler,
                    node_name='fake' + str(i),
                    node_mac0="00:17:3e:{0:02x}:{1:02x}:01".format(i, j),
                    node_mac1="00:17:3e:{0:02x}:{1:02x}:02".format(i, j),
                    node_mac2="00:17:3e:{0:02x}:{1:02x}:03".format(i, j),
                    node_ip="192.168.{0:d}.{1:d}".format(i, j),
                    net_mask="255.255.0.0",
                    stomp_name=stomp_name,
                    gateway=self.ci().internal_router()
                )

    def _static(self, node_name):
        if node_name.count('quantum'):
            return "1"
        else:
            return "0"

    def _add_node(self, client, token, cobbler, node_name, node_mac0, node_mac1,
                  node_mac2, node_ip, stomp_name, gateway, net_mask):
        system_id = client.new_system(token)
        if OS_FAMILY == 'centos':
            profile = 'centos64_x86_64'
        else:
            profile = 'ubuntu_1204_x86_64'
        client.modify_system_args(
            system_id, token,
            ks_meta=self.get_ks_meta('master.your-domain-name.com',
                stomp_name),
            name=node_name,
            hostname=node_name + ".your-domain-name.com",
            name_servers=cobbler.get_ip_address_by_network_name('internal'),
            name_servers_search="your-domain-name.com",
            profile=profile,
            gateway=gateway,
            netboot_enabled="1")
        client.modify_system(system_id, 'modify_interface', {
            "macaddress-eth0": str(node_mac0),
            "static-eth0": self._static(node_name),
            "macaddress-eth1": str(node_mac1),
            "ipaddress-eth1": str(node_ip),
            "netmask-eth1": str(net_mask),
            "dnsname-eth1": node_name + ".your-domain-name.com",
            "static-eth1": self._static(node_name),
            "macaddress-eth2": str(node_mac2),
            "static-eth2": "1"
        }, token)
        client.save_system(system_id, token)
        client.sync(token)

    def add_node(self, client, token, cobbler, node, gateway, net_mask):
        node_name = node.name
        node_mac0 = str(node.interfaces[0].mac_address)
        node_mac1 = str(node.interfaces[1].mac_address)
        node_mac2 = str(node.interfaces[2].mac_address)
        node_ip = str(node.get_ip_address_by_network_name('internal'))
        self._add_node(
            client, token, cobbler, node_name,
            node_mac0, node_mac1, node_mac2, node_ip,
            stomp_name=self.ci().nodes().stomps[0].name,
            gateway=gateway, net_mask=net_mask,
        )

    def configure_cobbler(self):
        cobbler = self.ci().nodes().cobblers[0]
        client = CobblerClient(
            cobbler.get_ip_address_by_network_name('internal'))
        token = client.login('cobbler', 'cobbler')
        for node in self.ci().client_nodes():
            self.add_node(
                client, token, cobbler, node,
                gateway=self.ci().internal_router(),
                net_mask=self.ci().internal_net_mask()
            )
        master = self.environment().node_by_name('master')
        remote = master.remote('internal',
            login='root',
            password='r00tme')
        add_to_hosts(
            remote,
            master.get_ip_address_by_network_name('internal'),
            master.name,
            master.name + ".your-domain-name.com")
        self.environment().snapshot('cobbler-configured', force=True)

    def deploy_nodes(self):
        cobbler = self.ci().nodes().cobblers[0]
        for node in self.ci().client_nodes():
            node.start()
        for node in self.ci().client_nodes():
            await_node_deploy(
                cobbler.get_ip_address_by_network_name('internal'), node.name)
        for node in self.ci().client_nodes():
            try:
                node.await('internal')
            except TimeoutError:
                node.destroy()
                node.start()
                node.await('internal')
        sleep(20)
        self.environment().snapshot('nodes-deployed', force=True)

if __name__ == '__main__':
    unittest.main()




