from devops.helpers import ssh, tcp_ping
from fuel_test.helpers import udp_ping, execute
from fuel_test.openstack.openstack_test_case import OpenStackTestCase
from fuel_test.root import root
import unittest

class CobblerTestCase(OpenStackTestCase):
    def test_deploy_cobbler(self):
        node01 = self.environment.node[self.ci().controllers[0]]
        self.write_site_pp_manifest(
            root('fuel', 'deployment', 'puppet', 'cobbler', 'examples',
                'server_site.pp'),
            server="'%s'" % node01.ip_address,
            name_server="'%s'" % node01.ip_address,
            next_server="'%s'" % node01.ip_address,
            dhcp_start_address="'%s'" % self.environment.network[
                                        'internal'].ip_addresses[-5],
            dhcp_end_address="'%s'" %
                             self.environment.network['internal'].ip_addresses[
                             -5],
            dhcp_netmask="'%s'" % '255.255.255.0',
            dhcp_gateway="'%s'" % node01.ip_address
        )
        remote = ssh(node01.ip_address, username='root', password='r00tme')
        result = execute(remote.sudo.ssh, 'puppet agent --test')
        #25151
        closed_tcp_ports = filter(
            lambda port: not tcp_ping(
                node01.ip_address,
                port), [22, 53, 80, 443])
        closed_udp_ports = filter(
            lambda port: not udp_ping(
                self.master_remote.sudo.ssh,
                node01.ip_address, port), [53, 67, 68, 69])
        self.assertEquals({'tcp': [], 'udp': []},
            {'tcp': closed_tcp_ports, 'udp': closed_udp_ports})
        self.assertResult(result)

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
