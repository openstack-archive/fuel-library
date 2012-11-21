from fuel_test.base_test_case import BaseTestCase
from fuel_test.ci.ci_openstack_swift import CiOpenStackSwift
from fuel_test.root import root

class OpenStackSwiftTestCase(BaseTestCase):
    def ci(self):
        if not hasattr(self, '_ci'):
            self._ci = CiOpenStackSwift()
        return self._ci

    def setUp(self):
        super(OpenStackSwiftTestCase, self).setUp()
        self.write_openstack_sitepp(self.nodes.controllers, self.nodes.proxies)

    def write_openstack_sitepp(self, controllers, proxies):
        controller_public_addresses="{"
        controller_internal_addresses="{"
        swift_proxies="{"
        for controller in controllers:
            controller_public_addresses +="'%s' => '%s'" % (controller.name,controller.ip_address_by_network['public'])
            if controller != controllers[-1]:
                controller_public_addresses +=","
            else:
                controller_public_addresses +="}"
        for controller in controllers:
            controller_internal_addresses +="'%s' => '%s'" % (controller.name,controller.ip_address_by_network['internal'])
            if controller != controllers[-1]:
                controller_internal_addresses +=","
            else:
                controller_internal_addresses +="}"
        for proxy in proxies:
            swift_proxies +="'%s' => '%s'" % (proxy.name,proxy.ip_address_by_network['internal'])
            if proxy != proxies[-1]:
                swift_proxies +=","
            else:
                swift_proxies +="}"



        self.write_site_pp_manifest(

            root('fuel', 'deployment', 'puppet', 'openstack', 'examples',
                'site_openstack_swift_standalone.pp'),
            internal_virtual_ip="'%s'" % self.ci().get_internal_virtual_ip(),
            public_virtual_ip="'%s'" % self.ci().get_public_virtual_ip(),
            floating_range="'%s'" % self.ci().get_floating_network(),
            fixed_range="'%s'" % self.ci().get_fixed_network(),
            master_hostname="'%s'" % controllers[0].name,
            swift_proxy_address="'%s'" % self.ci().get_internal_virtual_ip(),
            controller_public_addresses = controller_public_addresses,
            controller_internal_addresses = controller_internal_addresses, 
            swift_proxies = swift_proxies,
            mirror_type = "'internal'",
#            controller_public_addresses="{ '%s' => '%s', '%s' => '%s' }"
#                                        % (
#                node01.name, node01.ip_address_by_network['public'],
#                node02.name,
#                node02.ip_address_by_network['public']),
#            controller_internal_addresses="{ '%s' => '%s', '%s' => '%s' }"
#                                          % (
#                node01.name, node01.ip_address_by_network['internal'],
#                node02.name,
#                node02.ip_address_by_network['internal']),
            controller_hostnames=["%s" % controller.name for controller in controllers],
            public_interface="'eth2'",
            internal_interface="'eth0'",
            internal_address="$ipaddress_eth0",
            private_interface="'eth1'",
            nv_physical_volume= ["/dev/vdb"]
        )
