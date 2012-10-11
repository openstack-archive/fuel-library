import unittest
from fuel_test.cobbler.cobbler_test_case import CobblerTestCase
from fuel_test.helpers import tcp_ping, udp_ping


class CobblerCase(CobblerTestCase):
    def test_deploy_cobbler(self):
        self.validate(
            self.nodes.cobblers,
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
