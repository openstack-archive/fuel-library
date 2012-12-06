from time import sleep
import unittest
from devops.helpers import ssh
from fuel_test.cobbler.cobbler_client import CobblerClient
from fuel_test.cobbler.cobbler_test_case import CobblerTestCase
from fuel_test.helpers import tcp_ping, udp_ping, safety_revert_nodes, add_to_hosts, sign_all_node_certificates, sync_time, upload_recipes, upload_keys, await_node_deploy, build_astute, install_astute, write_config, execute
from fuel_test.settings import EMPTY_SNAPSHOT, OS_FAMILY, PUPPET_VERSION, PUBLIC_INTERFACE, INTERNAL_INTERFACE, PRIVATE_INTERFACE
from fuel_test.root import root

class CobblerCase(CobblerTestCase):
    def configure_master_remote(self):
        master = self.environment.node['master']
        self.master_remote = ssh(master.ip_address_by_network['public'],
            username='root',
            password='r00tme')
        upload_recipes(self.master_remote)
        upload_keys(self.master_remote)

    def test_deploy_cobbler(self):
        safety_revert_nodes(self.environment.nodes, EMPTY_SNAPSHOT)
        self.configure_master_remote()
        for node in [self.environment.node['master']] + self.nodes.cobblers:
            remote = ssh(node.ip_address_by_network['public'], username='root', password='r00tme')
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

    def install_astute_gem(self):
        build_astute()
        install_astute(self.nodes.stomps[0].ip_address_by_network['public'])

    def deploy_stomp_node(self):
        self.configure_master_remote()
        for node in [self.environment.node['master']] + self.nodes.cobblers:
            remote = ssh(node.ip_address_by_network['internal'], username='root', password='r00tme')
            sync_time(remote.sudo.ssh)
            remote.sudo.ssh.execute('yum makecache')
        self.write_stomp_manifest()
        self.validate(
            self.nodes.stomps,
            'puppet agent --test')

    def get_ks_meta(self, puppet_master, mco_host):
        return  ("puppet_auto_setup=1 "
                 "puppet_master=%(puppet_master)s "
                 "puppet_version=%(puppet_version)s "
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
                         'puppet_version': PUPPET_VERSION,
                         'mco_host': mco_host
                }

    def add_fake_nodes(self):
        cobbler = self.ci().nodes().cobblers[0]
        stomp_name = self.ci().nodes().stomps[0].name
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
                    node_ip="192.168.{0:d}.{1:d}".format(i, j),
                    stomp_name=stomp_name
                )

    def _add_node(self, client, token, cobbler, node_name, node_mac0, node_mac1, node_mac2, node_ip, stomp_name):
        system_id = client.new_system(token)
        if OS_FAMILY=='centos':
            profile='centos63_x86_64'
        else:
            profile='ubuntu_1204_x86_64'
        client.modify_system_args(
            system_id, token,
            ks_meta=self.get_ks_meta('master',
                stomp_name),
            name=node_name,
            hostname=node_name + ".mirantis.com",
            name_servers=cobbler.ip_address_by_network['internal'],
            name_servers_search="mirantis.com",
            profile=profile,
            netboot_enabled="1")
        client.modify_system(system_id, 'modify_interface', {
            "macaddress-eth0": str(node_mac0),
            "static-eth0": "0",
            "macaddress-eth1": str(node_mac1),
            "ipaddress-eth1": str(node_ip),
            "dnsname-eth1": node_name + ".mirantis.com",
            "static-eth1": "1",
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
            node_mac0, node_mac1, node_mac2, node_ip,
            stomp_name=self.ci().nodes().stomps[0].name
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
        cobbler = self.ci().nodes().cobblers[0]
        safety_revert_nodes(self.environment.nodes,
            snapsot_name='cobbler-configured')
        for node in self.environment.nodes:
            node.start()
        for node in self.ci().nodes().computes + self.ci().nodes().controllers:
            await_node_deploy(
                cobbler.ip_address_by_network['internal'], node.name)
        sleep(20)
        sign_all_node_certificates(self.master_remote)

    def test_orchestrating_minimal(self):
        self.configure_master_remote()
        controller1 = self.nodes.controllers[0]
        controller2 = self.nodes.controllers[1]
        self.write_site_pp_manifest(
            root('deployment', 'puppet', 'openstack', 'examples',
                 'site.pp'),
            internal_virtual_ip="'%s'" % self.ci().get_internal_virtual_ip(),
            public_virtual_ip="'%s'" % self.ci().get_public_virtual_ip(),
            floating_range="'%s'" % self.ci().get_floating_network(),
            fixed_range="'%s'" % self.ci().get_fixed_network(),
            master_hostname="'%s'" % controller1.name,
            mirror_type="'internal'",
            controller_public_addresses="{ '%s' => '%s', '%s' => '%s' }"
            % (
                controller1.name, controller1.ip_address_by_network['public'],
                controller2.name, controller2.ip_address_by_network['public']),
            controller_internal_addresses="{ '%s' => '%s', '%s' => '%s' }"
            % (
                controller1.name, controller1.ip_address_by_network['internal'],
                controller2.name,
                controller2.ip_address_by_network['internal']),
            controller_hostnames=[
                "%s" % controller1.name,
                "%s" % controller2.name],
            public_interface="'%s'" % PUBLIC_INTERFACE,
            internal_interface="'%s'" % INTERNAL_INTERFACE,
            private_interface="'%s'" % PRIVATE_INTERFACE,
            nv_physical_volume= ["/dev/vdb"]
        )
        config_text = \
        "use_case: minimal\n\
        fuel-01:\n\
            role: controller\n\
        fuel-02:\n\
            role: controller\n\
        fuel-03:\n\
            role: compute\n\
        fuel-04:\n\
            role: compute"
        remote = ssh(self.nodes.stomps[0].ip_address_by_network['public'], username='root',
                password='r00tme')
        write_config(remote, '/tmp/nodes.yaml', config_text)
        execute(remote, 'astute_run /tmp/nodes.yaml')

    def test_orchestrating_simple(self):
        self.configure_master_remote()
        controller = self.nodes.controllers[0]
        self.write_site_pp_manifest(
            root('deployment', 'puppet', 'openstack', 'examples',
                'site_simple.pp'),
            floating_network_range="'%s'" % self.ci().get_floating_network(),
            fixed_network_range="'%s'" % self.ci().get_fixed_network(),
            public_interface="'%s'" % PUBLIC_INTERFACE,
            internal_interface="'%s'" % INTERNAL_INTERFACE,
            private_interface="'%s'" % PRIVATE_INTERFACE,
            mirror_type="'internal'",
            controller_node_address="'%s'" % controller.ip_address_by_network[
                                             'internal'],
            controller_node_public="'%s'" % controller.ip_address_by_network[
                                            'public'],
            nv_physical_volume=["/dev/vdb"]
        )
        config_text = \
        "use_case: minimal\n\
        fuel-01:\n\
            role: controller\n\
        fuel-02:\n\
            role: compute\n\
        fuel-03:\n\
            role: compute\n\
        fuel-04:\n\
            role: compute"
        remote = ssh(self.nodes.stomps[0].ip_address_by_network['public'], username='root',
                password='r00tme')
        write_config(remote, '/tmp/nodes.yaml', config_text)
        execute(remote, 'astute_run /tmp/nodes.yaml')

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
