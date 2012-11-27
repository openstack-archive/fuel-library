import logging
from time import sleep
import unittest
import devops
from devops.helpers import wait, ssh
from fuel_test.cobbler.cobbler_client import CobblerClient
from fuel_test.cobbler.cobbler_test_case import CobblerTestCase
from fuel_test.helpers import tcp_ping, udp_ping, safety_revert_nodes, add_to_hosts, sign_all_node_certificates, sync_time, upload_recipes, upload_keys
from fuel_test.settings import EMPTY_SNAPSHOT, OS_FAMILY

class CobblerCase(CobblerTestCase):
    def test_deploy_cobbler(self):
        safety_revert_nodes(self.environment.nodes, EMPTY_SNAPSHOT)
        master = self.environment.node['master']
        self.master_remote = ssh(master.ip_address_by_network['public'],
            username='root',
            password='r00tme')
        upload_recipes(self.master_remote)
        upload_keys(self.master_remote)
        for node in [self.environment.node['master']] + self.nodes.cobblers:
            remote = ssh(node.ip_address, username='root', password='r00tme')
            sync_time(remote.sudo.ssh)
            remote.sudo.ssh.execute('yum makecache')
        self.write_cobbler_manifest()
        self.validate(
            self.nodes.cobblers,
            'puppet agent --test')
        for node in self.nodes.cobblers:
            self.assert_cobbler_ports(node.ip_address_by_network['internal'])
        for node in self.environment.nodes:
            node.save_snapshot('cobbler', force=True)

    def get_ks_meta(self, puppet_master, mco_host):
        return  ("puppet_auto_setup=1 "
                 "puppet_master=%(puppet_master)s "
                 "puppet_version=2.7.19 "
                 "puppet_enable=0 "
                 "mco_auto_setup=1 "
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
                         'mco_host': mco_host
                }

    def add_fake_nodes(self):
        cobbler = self.ci().nodes().cobblers[0]
        client = CobblerClient(cobbler.ip_address_by_network['internal'])
        token = client.login('cobbler', 'cobbler')
        for i in range(1,100):
            for j in range(1,100):
                self._add_node(
                    client, token, cobbler,
                    node_name='fake' + str(i),
                    node_mac0="00:17:3e:{0:02x}:{1:02x}:01".format(i, j),
                    node_mac1="00:17:3e:{0:02x}:{1:02x}:02".format(i, j),
                    node_mac2="00:17:3e:{0:02x}:{1:02x}:03".format(i, j),
                    node_ip="192.168.{0:d}.{1:d}".format(i, j)
                )

    def _add_node(self, client, token, cobbler, node_name, node_mac0, node_mac1, node_mac2, node_ip):
        system_id = client.new_system(token)
        if OS_FAMILY=='centos':
            profile='centos63-x86_64'
        else:
            profile='ubuntu-1204-x86_64'
        client.modify_system_args(
            system_id, token,
            ks_meta=self.get_ks_meta('master',
                cobbler.ip_address_by_network['internal']),
            name=node_name,
            hostname=node_name + ".mirantis.com",
            name_servers=cobbler.ip_address_by_network['internal'],
            name_servers_search="mirantis.com",
            profile=profile,
            netboot_enabled="1")
        client.modify_system(system_id, 'modify_interface', {
            "macaddress-eth0": str(node_mac0),
            "ipaddress-eth0": str(node_ip),
            "dnsname-eth0": node_name + ".mirantis.com",
            "static-eth0": "1",
            "macaddress-eth1": str(node_mac1),
            "static-eth1": "0",
            "macaddress-eth2": str(node_mac2),
            "static-eth2": "0"
        }, token)
        client.save_system(system_id, token)
        client.sync(token)

    def add_node(self, client, token, cobbler, node):
        node_name=node.name
        node_mac0=str(node.interfaces[0].mac_address)
        node_mac1=str(node.interfaces[1].mac_address)
        node_mac2=str(node.interfaces[2].mac_address)
        node_ip=str(node.ip_address_by_network['internal'])
        self._add_node(
            client, token, cobbler, node_name,
            node_mac0, node_mac1, node_mac2, node_ip
        )

    def test_configure_cobbler(self):
        safety_revert_nodes(self.ci().environment.nodes, 'cobbler')

        client_nodes = self.ci().nodes().controllers + self.ci().nodes().computes
        cobbler = self.ci().nodes().cobblers[0]
        client = CobblerClient(cobbler.ip_address_by_network['internal'])
        token = client.login('cobbler', 'cobbler')

        for node in client_nodes:
            self.add_node(client, token, cobbler, node)

        master = self.ci().environment.node['master']
        remote = ssh(
            self.ci().nodes().cobblers[0].ip_address_by_network['internal'],
            username='root',
            password='r00tme')

        add_to_hosts(
            remote,
            master.ip_address_by_network['internal'],
            master.name,
            master.name + ".mirantis.com")

        for node in self.environment.nodes:
            node.save_snapshot('cobbler-configured', force=True)

    def test_deploy_nodes(self):
        safety_revert_nodes(self.environment.nodes,
            snapsot_name='cobbler-configured')
        for node in self.environment.nodes:
            node.start()
        for node in self.ci().nodes().computes + self.ci().nodes().controllers:
            logging.info("Waiting ssh... %s" % node.ip_address)
            wait(lambda: devops.helpers.tcp_ping(
                node.ip_address_by_network['internal'], 22),
                timeout=900)
        sleep(20)
        sign_all_node_certificates(self.master_remote)
        self.validate(
            self.ci().nodes().computes + self.ci().nodes().controllers,
            'puppet agent --test')

    def assert_cobbler_ports(self, ip):
        closed_tcp_ports = filter(
            lambda port: not tcp_ping(
                self.master_remote.sudo.ssh,
                ip,
                port), [22, 53, 80, 443])
        closed_udp_ports = filter(
            lambda port: not udp_ping(
                self.master_remote.sudo.ssh,
                ip, port), [53, 67, 68, 69])
        self.assertEquals(
            {'tcp': [], 'udp': []},
            {'tcp': closed_tcp_ports, 'udp': closed_udp_ports})


if __name__ == '__main__':
    unittest.main()
