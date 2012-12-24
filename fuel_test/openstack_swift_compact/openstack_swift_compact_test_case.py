from fuel_test.base_test_case import BaseTestCase
from fuel_test.ci.ci_openstack_swift_compact import CiOpenStackSwiftCompact
from fuel_test.helpers import is_not_essex
from fuel_test.root import root
from fuel_test.settings import PUBLIC_INTERFACE, INTERNAL_INTERFACE, PRIVATE_INTERFACE

class OpenStackSwiftCompactTestCase(BaseTestCase):
    def ci(self):
        if not hasattr(self, '_ci'):
            self._ci = CiOpenStackSwiftCompact()
        return self._ci

    def setUp(self):
        super(OpenStackSwiftCompactTestCase, self).setUp()

    def write_openstack_sitepp(self, controllers, quantum=False):
        controller_public_addresses="{"
        controller_internal_addresses="{"
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
        if is_not_essex():
            self.write_site_pp_manifest(
                root('deployment', 'puppet', 'openstack', 'examples',
                    'site_openstack_swift_compact.pp'),
                internal_virtual_ip="'%s'" % self.ci().get_internal_virtual_ip(),
                public_virtual_ip="'%s'" % self.ci().get_public_virtual_ip(),
                floating_range="'%s'" % self.ci().get_floating_network(),
                fixed_range="'%s'" % self.ci().get_fixed_network(),
                master_hostname = "'%s'" % controllers[0].name,
                swift_master = "%s" % controllers[0].name,
                controller_public_addresses = controller_public_addresses,
                controller_internal_addresses = controller_internal_addresses,
                controller_hostnames=["%s" % controller.name for controller in controllers],
                swift_proxy_address="'%s'" % self.ci().get_internal_virtual_ip(),
                public_interface="'%s'" % PUBLIC_INTERFACE,
                internal_interface="'%s'" % INTERNAL_INTERFACE,
                private_interface="'%s'" % PRIVATE_INTERFACE,
                mirror_type ="'internal'",
                nv_physical_volume= ["/dev/vdb"],
                quantum = "true" if quantum else "false",
            )
        else:
            self.write_site_pp_manifest(
                root('deployment', 'puppet', 'openstack', 'examples',
                    'site_openstack_swift_compact.pp'),
                internal_virtual_ip="'%s'" % self.ci().get_internal_virtual_ip(),
                public_virtual_ip="'%s'" % self.ci().get_public_virtual_ip(),
                floating_range="'%s'" % self.ci().get_floating_network(),
                fixed_range="'%s'" % self.ci().get_fixed_network(),
                master_hostname = "'%s'" % controllers[0].name,
                swift_master = "%s" % controllers[0].name,
                controller_public_addresses = controller_public_addresses,
                controller_internal_addresses = controller_internal_addresses,
                controller_hostnames=["%s" % controller.name for controller in controllers],
                swift_proxy_address="'%s'" % self.ci().get_internal_virtual_ip(),
                public_interface="'%s'" % PUBLIC_INTERFACE,
                internal_interface="'%s'" % INTERNAL_INTERFACE,
                private_interface="'%s'" % PRIVATE_INTERFACE,
                mirror_type ="'internal'",
                nv_physical_volume= ["/dev/vdb"],
            )




