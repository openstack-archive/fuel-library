import logging
import unittest
from devops.helpers import wait
from fuel_test.cobbler.cobbler_client import CobblerClient
from fuel_test.cobbler.cobbler_test_case import CobblerTestCase
from fuel_test.helpers import tcp_ping, udp_ping

class CobblerCase(CobblerTestCase):
    def test_deploy_cobbler(self):
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

    def test_configure_cobbler(self):
        nodes = self.ci().nodes().controllers + self.ci().nodes().computes
        cobbler = self.ci().nodes().cobblers[0]
        client = CobblerClient(cobbler.ip_address_by_network['public'])
        token = client.login('cobbler', 'cobbler')

        for node in nodes:
            system_id = client.new_system(token)
            client.modify_system_args(
                system_id, token,
                ks_meta=self.get_ks_meta('master',
                    cobbler.ip_address_by_network['internal']),
                name=node.name,
                hostname=node.name + ".mirantis.com",
                name_servers=cobbler.ip_address_by_network['internal'],
                name_servers_search="mirantis.com",
                profile="centos63-x86_64",
                netboot_enabled="1")
            client.modify_system(system_id, 'modify_interface', {
                "macaddress-eth0": str(node.interfaces[0].mac_address),
                "ipaddress-eth0": str(node.ip_address_by_network['internal']),
                "dnsname-eth0": node.name + ".mirantis.com",
                "static-eth0": "1",
                "macaddress-eth1": str(node.interfaces[1].mac_address),
                "static-eth1": "0",
                "macaddress-eth2": str(node.interfaces[2].mac_address),
                "static-eth2": "0"
            }, token)
            client.save_system(system_id, token)
            client.sync(token)

    def test_deploy_nodes(self):
        for node in self.ci().nodes().computes + self.ci().nodes().controllers:
            node.restore_snapshot('cobbler')
            node.start()
        for node in self.ci().nodes().computes + self.ci().nodes().controllers:
            logging.info("Waiting ssh... %s" % node.ip_address)
            wait(lambda: tcp_ping(
                self.master_remote.sudo.ssh,
                node.ip_address_by_network['public'], 22),
                timeout=1800)

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


#    # HERE IS IPTABLES RULES TO MAKE COBBLER AVAILABLE FROM OUTSIDE
#    # https://github.com/cobbler/cobbler/wiki/Using%20Cobbler%20Import
#    # SSH
#    access_to_cobbler_port { "ssh":        port => '22' }
#    # DNS
#    access_to_cobbler_port { "dns_tcp":    port => '53' }
#    access_to_cobbler_port { "dns_udp":    port => '53',  protocol => 'udp' }
#    # DHCP
#    access_to_cobbler_port { "dncp_67":    port => '67',  protocol => 'udp' }
#    access_to_cobbler_port { "dncp_68":    port => '68',  protocol => 'udp' }
#    # TFTP
#    access_to_cobbler_port { "tftp_tcp":   port => '69' }
#    access_to_cobbler_port { "tftp_udp":   port => '69',  protocol => 'udp' }
#    # NTP
#    access_to_cobbler_port { "ntp_udp":    port => '123', protocol => 'udp' }
#    # HTTP/HTTPS
#    access_to_cobbler_port { "http":       port => '80' }
#    access_to_cobbler_port { "https":      port => '443'}
#    # SYSLOG FOR COBBLER
#    access_to_cobbler_port { "syslog_tcp": port => '25150'}
#    # xmlrpc API
#    access_to_cobbler_port { "xmlrpc_api": port => '25151' }
#    #:80/api/distro/list
