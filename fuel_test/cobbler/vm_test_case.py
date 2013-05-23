from time import sleep
import unittest
from ipaddr import IPNetwork
from devops.error import TimeoutError
from fuel_test import iso_master
from fuel_test.base_test_case import BaseTestCase
from fuel_test.ci.ci_vm import CiVM
from fuel_test.cobbler.cobbler_client import CobblerClient
from fuel_test.config import Config
from fuel_test.helpers import tcp_ping, udp_ping, add_to_hosts, await_node_deploy, write_config
from fuel_test.manifest import Manifest
from fuel_test.settings import OS_FAMILY, CLEAN, USE_ISO, INTERFACES, PARENT_PROXY, DOMAIN_NAME


class CobblerTestCase(BaseTestCase):
    def ci(self):
        if not hasattr(self, '_ci'):
            self._ci = CiVM()
        return self._ci

    def setUp(self):
        if CLEAN:
            self.get_nodes_deployed_state()
        self.update_modules()

    def get_nodes_deployed_state(self):
        if not self.environment().has_snapshot('nodes-deployed'):
            self.ci().get_empty_state()
            self.update_modules()
            self.remote().execute("killall bootstrap_admin_node.sh")
            write_config(self.remote(), "/root/fuel.defaults",
                         iso_master.get_config(
                             hostname="master",
                             domain="your-domain-name.com",
                             management_interface=INTERFACES["internal"],
                             management_ip=self.nodes().masters[
                                 0].get_ip_address_by_network_name("internal"),
                             management_mask=self.ci().internal_net_mask(),
                             external_interface=INTERFACES["public"],
                             dhcp_start_address=
                             IPNetwork(self.ci().internal_network())[50],
                             dhcp_end_address=
                             IPNetwork(self.ci().internal_network())[100],
                             mirror_type='custom',
                             external_ip="",
                             external_mask="",
                             parent_proxy=PARENT_PROXY))
            self.remote().execute("/usr/local/sbin/bootstrap_admin_node.sh --batch-mode")
            self.prepare_cobbler_environment()
        self.environment().revert('nodes-deployed')
        for node in self.nodes():
            node.await('internal')

    def prepare_cobbler_environment(self):
        self.deploy_cobbler()
        if USE_ISO:
            self.configure_cobbler(self.ci().nodes().masters[0])
        else:
            self.configure_cobbler(self.ci().nodes().cobblers[0])
        self.deploy_nodes()

    def deploy_cobbler(self):
        if USE_ISO:
            nodes = self.nodes().masters
        else:
            nodes = self.nodes().cobblers

        # Manifest().write_cobbler_manifest(self.remote(), self.ci(), nodes)

        # self.validate(nodes, 'puppet agent --test --server master.your-domain-name.com')

        for node in nodes:
            self.assert_cobbler_ports(
                node.get_ip_address_by_network_name('internal'))
        self.environment().snapshot('cobbler', force=True)

    def assert_cobbler_ports(self, ip):
        closed_tcp_ports = filter(
            lambda port: not tcp_ping(self.remote().sudo.ssh, ip, port),
            [22, 53, 80, 443])
        closed_udp_ports = filter(
            lambda port: not udp_ping(
                self.remote().sudo.ssh,
                ip, port), [53, 67, 68, 69])
        self.assertEquals(
            {'tcp': [], 'udp': []},
            {'tcp': closed_tcp_ports, 'udp': closed_udp_ports})

    def deploy_stomp_node(self):
        Manifest().generate_stomp_manifest()
        self.validate(self.nodes().stomps, 'puppet agent --test')

    def add_fake_nodes(self):
        cobbler = self.ci().nodes().masters[0]
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

    def _add_node(self, client, token, cobbler, node_name, node_mac0, node_mac1,
                  node_mac2, node_ip, stomp_name, gateway, net_mask):
        system_id = client.new_system(token)
        if OS_FAMILY == 'centos':
            profile = 'centos64_x86_64'
        else:
            profile = 'ubuntu_1204_x86_64'
        client.modify_system_args(system_id, token,
            ks_meta=Config().get_ks_meta('master.your-domain-name.com',
                                         stomp_name),
            name=node_name,
            hostname=node_name,
            name_servers=cobbler.get_ip_address_by_network_name('internal'),
            name_servers_search="your-domain-name.com",
            profile=profile,
            gateway=gateway,
            netboot_enabled="1")
        client.modify_system(system_id, 'modify_interface', {
            "macaddress-eth0": str(node_mac0),
            "static-eth0": "1",
            "macaddress-eth1": str(node_mac1),
            "ipaddress-eth1": str(node_ip),
            "netmask-eth1": str(net_mask),
            "dnsname-eth1": node_name + DOMAIN_NAME,
            "static-eth1": "1",
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
            stomp_name=self.ci().nodes().masters[0].name,
            gateway=gateway, net_mask=net_mask,
        )

    def configure_cobbler(self, cobbler):
        client = CobblerClient(cobbler.get_ip_address_by_network_name('internal'))
        token = client.login('cobbler', 'cobbler')
        master = self.environment().node_by_name('master')
        for node in self.ci().client_nodes():
            self.add_node(client,
                          token,
                          cobbler,
                          node,
                          gateway=cobbler.get_ip_address_by_network_name('internal'),
                          net_mask=self.ci().internal_net_mask()
            )

        remote = master.remote('internal',
                               login='root',
                               password='r00tme')
        add_to_hosts(
            remote,
            master.get_ip_address_by_network_name('internal'),
            master.name,
            master.name + DOMAIN_NAME)

        self.environment().snapshot('cobbler-configured', force=True)

    def deploy_nodes(self):
        cobbler = self.ci().nodes().masters[0]
        cobbler_ip = cobbler.get_ip_address_by_network_name('internal')
        for node in self.ci().client_nodes():
            node.start()
        for node in self.ci().client_nodes():
            await_node_deploy(cobbler.get_ip_address_by_network_name('internal'), node.name)
        for node in self.ci().client_nodes():
            try:
                node.await('internal')
            except TimeoutError:
                node.destroy()
                node.start()
                node.await('internal')
        sleep(20)
        #for node in self.ci().client_nodes():
        #    node_remote = node.remote('public', login='root', password='r00tme')
        #puppet_apply(node_remote, 'class {rsyslog::client: log_remote => true, server => "%s"}' % cobbler_ip)
        self.environment().snapshot('nodes-deployed', force=True)


if __name__ == '__main__':
    unittest.main()




