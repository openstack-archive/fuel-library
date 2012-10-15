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


    ks_meta = ("puppet_auto_setup=1 "
               "puppet_master=fuel-pm.mirantis.com "
               "puppet_version=2.7.19 "
               "puppet_enable=0 "
               "mco_auto_setup=1 "
               "mco_pskey=un0aez2ei9eiGaequaey4loocohjuch4Ievu3shaeweeg5Uthi "
               "mco_stomphost=10.0.0.100 "
               "mco_stompport=61613 "
               "mco_stompuser=mcollective "
               "mco_stomppassword=AeN5mi5thahz2Aiveexo "
               "mco_enable=1 "
               "interface_extra_eth0_peerdns=no"
               "interface_extra_eth1_peerdns=no"
               "interface_extra_eth2_peerdns=no"
               "interface_extra_eth2_promisc=yes"
               "interface_extra_eth2_userctl=yes"
        )

    def test_configure_cobbler(self):
        nodes = self.ci().nodes().computes + self.ci().nodes().controllers
        cobbler = self.ci().nodes().cobblers[0]
        client = CobblerClient(cobbler.ip_address_by_network['public'])
        token = client.login('cobbler', 'cobbler')

        for node in nodes:
            system_id = client.new_system(token)
            client.modify_system_args(
                system_id, token,
                ks_meta=self.ks_meta,
                name=node.name,
                hostname=node.name + "mirantis.com",
                name_servers=cobbler.ip_address_by_network['internal'],
                name_servers_search="mirantis.com",
                profile="centos63-x86_64",
                netboot_enabled="1")
            client.modify_system(system_id, 'modify_interface', {
                "macaddress-eth0": node.interfaces[0].mac_address,
                "ipaddress-eth0": node.ip_address_by_network['internal'],
                "dnsname-eth0": node.name + "mirantis.com",
                "static-eth0": "1",
                "macaddress-eth1": node.interfaces[1].mac_address,
                "static-eth1": "0",
                "macaddress-eth2": node.interfaces[2].mac_address,
                "static-eth2": "0"
            }, token)
            client.save_system(system_id, token)
            client.sync(token)


            #fuel-01:
            #  profile: "centos63-x86_64"
            #  netboot-enabled: "1"
            #  hostname: "fuel-01"
            #  name-servers: "10.0.0.100"
            #  name-servers-search: "mirantis.com"
            #  interfaces:
            #    eth0:
            #      mac: "52:54:00:e6:dc:c9"
            #      static: "0"
            #    eth1:
            #      mac: "52:54:00:0a:39:ec"
            #      static: "1"
            #      ip-address: "10.0.0.101"
            #      netmask: "255.255.255.0"
            #      dns-name: "fuel-01.mirantis.com"
            #    eth2:
            #      mac: "52:54:00:ae:22:04"
            #      static: "1"
            #  interfaces_extra:
            #    eth0:
            #      peerdns: "no"
            #    eth1:
            #      peerdns: "no"
            #    eth2:
            #      promisc: "yes"
            #      userctl: "yes"
            #      peerdns: "no"
            #fuel-02:
            #  profile: "centos63-x86_64"
            #  netboot-enabled: "1"
            #  hostname: "fuel-02"
            #  name-servers: "10.0.0.100"
            #  name-servers-search: "mirantis.com"
            #  interfaces:
            #    eth0:
            #      mac: "52:54:00:b4:a5:25"
            #      static: "0"
            #    eth1:
            #      mac: "52:54:00:e4:46:5c"
            #      static: "1"
            #      ip-address: "10.0.0.102"
            #      netmask: "255.255.255.0"
            #      dns-name: "fuel-02.mirantis.com"
            #    eth2:
            #      mac: "52:54:00:28:f8:06"
            #      static: "1"
            #  interfaces_extra:
            #    eth0:
            #      peerdns: "no"
            #    eth1:
            #      peerdns: "no"
            #    eth2:
            #      promisc: "yes"
            #      userctl: "yes"
            #      peerdns: "no"
            #fuel-03:
            #  profile: "centos63-x86_64"
            #  netboot-enabled: "1"
            #  hostname: "fuel-03"
            #  name-servers: "10.0.0.100"
            #  name-servers-search: "mirantis.com"
            #  interfaces:
            #    eth0:
            #      mac: "52:54:00:78:23:b7"
            #      static: "0"
            #    eth1:
            #      mac: "52:54:00:09:04:40"
            #      static: "1"
            #      ip-address: "10.0.0.103"
            #      netmask: "255.255.255.0"
            #      dns-name: "fuel-03.mirantis.com"
            #    eth2:
            #      mac: "52:54:00:84:60:bf"
            #      static: "1"
            #  interfaces_extra:
            #    eth0:
            #      peerdns: "no"
            #    eth1:
            #      peerdns: "no"
            #    eth2:
            #      promisc: "yes"
            #      userctl: "yes"
            #      peerdns: "no"
            #fuel-04:
            #  profile: "centos63-x86_64"
            #  netboot-enabled: "1"
            #  ksmeta: "puppet_auto_setup=1 \
            #puppet_master=fuel-pm.mirantis.com \
            #puppet_version=2.7.19 \
            #puppet_enable=0 \
            #mco_auto_setup=1 \
            #mco_pskey=un0aez2ei9eiGaequaey4loocohjuch4Ievu3shaeweeg5Uthi \
            #mco_stomphost=10.0.0.100 \
            #mco_stompport=61613 \
            #mco_stompuser=mcollective \
            #mco_stomppassword=AeN5mi5thahz2Aiveexo \
            #mco_enable=1"
            #  hostname: "fuel-04"
            #  name-servers: "10.0.0.100"
            #  name-servers-search: "mirantis.com"
            #  interfaces:
            #    eth0:
            #      mac: "52:54:00:27:49:44"
            #      static: "0"
            #    eth1:
            #      mac: "52:54:00:68:ff:9b"
            #      static: "1"
            #      ip-address: "10.0.0.104"
            #      netmask: "255.255.255.0"
            #      dns-name: "fuel-04.mirantis.com"
            #    eth2:
            #      mac: "52:54:00:19:0d:56"
            #      static: "1"
            #  interfaces_extra:
            #    eth0:
            #      peerdns: "no"
            #    eth1:
            #      peerdns: "no"
            #    eth2:
            #      promisc: "yes"
            #      userctl: "yes"
            #      peerdns: "no"


            #        print server.get_distros()
            #        print server.get_profiles()
            #        print server.get_systems()
            #        print server.get_images()
            #        print server.get_repos()

    def test_deploy_nodes(self):
        for node in self.nodes.computes + self.nodes.controllers:
            node.start()
        for node in self.nodes.computes + self.nodes.controllers:
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
