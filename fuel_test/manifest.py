from ipaddr import IPNetwork
import re
from fuel_test.helpers import load, write_config, is_not_essex
from fuel_test.root import root
from fuel_test.settings import INTERFACES, OS_FAMILY


class Template(object):
    def __init__(self, path):
        super(Template, self).__init__()
        self.value = load(path)

    def p_(self, value):
        """
        :rtype : str
        """
        if isinstance(value, dict):
            return self._hash(value)
        if isinstance(value, list):
            return self._list(value)
        if isinstance(value, bool):
            return self._bool(value)
        if isinstance(value, int):
            return str(value)
        if isinstance(value, type(None)):
            return 'undef'
        return self._str(value)

    def _hash(self, value):
        return '{%s}' % ','.join(
            ["%s => %s" % (self.p_(k), self.p_(v)) for k, v in value.items()])

    def _list(self, value):
        return '[%s]' % ','.join(["%s" % self.p_(k) for k in value])

    def _str(self, value):
        ret = str(value)
        if ret.startswith('$'):
            return ret
        return "'%s'" % ret

    def _bool(self, value):
        if not value: return 'false'
        return 'true'

    def _replace(self, template, **kwargs):
        for key, value in kwargs.items():
            template, count = re.subn(
                '^(\$' + str(key) + ')\s*=.*', "\\1 = " + self.p_(value),
                template,
                flags=re.MULTILINE)
            if count == 0:
                raise Exception("Variable ${0:>s} not found".format(key))
        return template

    def replace(self, **kwargs):
        self.value = self._replace(self.value, **kwargs)
        return self

    def __str__(self):
        return str(self.value)

    @classmethod
    def stomp(cls):
        return cls(root('deployment', 'puppet', 'mcollective', 'examples',
            'site.pp'))

    @classmethod
    def minimal(cls):
        return cls(root('deployment', 'puppet', 'openstack', 'examples',
            'site.pp'))

    @classmethod
    def compact(cls):
        return cls(root('deployment', 'puppet', 'openstack', 'examples',
            'site_openstack_swift_compact.pp'))

    @classmethod
    def full(cls):
        return cls(root('deployment', 'puppet', 'openstack', 'examples',
            'site_openstack_swift_standalone.pp'))


class Manifest(object):
    def mirror_type(self):
        if OS_FAMILY == 'centos':
            return 'internal-stage'
        else:
            return 'internal'

    def write_manifest(self, remote, manifest):
        write_config(remote, '/etc/puppet/manifests/site.pp',
            str(manifest))

    def public_addresses(self, controllers):
        return dict(map(
            lambda x: (x.name, x.get_ip_address_by_network_name('public')),
            controllers))

    def internal_addresses(self, controllers):
        return dict(map(
            lambda x: (x.name, x.get_ip_address_by_network_name('internal')),
            controllers))

    def external_ip_info(self, ci, quantums):
        floating_network = IPNetwork(ci.floating_network())
        return {
           'public_net_router' : ci.public_router(),
           'ext_bridge'        : quantums[0].get_ip_address_by_network_name('public'),
           'pool_start'        : floating_network[2],
           'pool_end'          : floating_network[-2]
        }

    def hostnames(self, controllers):
        return [x.name for x in controllers]

    def public_interface(self):
        return INTERFACES['public']

    def internal_interface(self):
        return INTERFACES['internal']

    def private_interface(self):
        return INTERFACES['private']

    def physical_volumes(self):
        return ["/dev/vdb"]

    def loopback(self, loopback):
        return "loopback" if loopback else False

    def floating_network(self, ci, quantum):
        if quantum:
            return ci.public_network()
        else:
            return ci.floating_network()

    def fixed_network(self, ci, quantum):
        if quantum:
            return '192.168.111.0/24'
        else:
            return ci.fixed_network()

    def write_openstack_simple_manifest(self, remote, ci, controllers,
                                        use_syslog=True,
                                        quantum=True,
                                        cinder=True):
        template = Template(
            root(
                'deployment', 'puppet', 'openstack', 'examples',
                'site_simple.pp')).replace(
            floating_range=self.floating_network(ci, quantum),
            fixed_range=self.fixed_network(ci, quantum),
            public_interface=self.public_interface(),
            internal_interface=self.internal_interface(),
            private_interface=self.private_interface(),
            mirror_type=self.mirror_type(),
            controller_node_address=controllers[
                                    0].get_ip_address_by_network_name(
                'internal'),
            controller_node_public=controllers[
                                   0].get_ip_address_by_network_name(
                'public'),
            nv_physical_volume=self.physical_volumes(),
            use_syslog=use_syslog
        )
        self.write_manifest(remote, template)


    def write_openstack_single_manifest(self, remote, ci,
                                        use_syslog=True,
                                        quantum=True,
                                        cinder=True):
        template = Template(
            root(
                'deployment', 'puppet', 'openstack', 'examples',
                'site_singlenode.pp')).replace(
            floating_range=self.floating_network(ci, quantum),
            fixed_range=self.fixed_network(ci, quantum),
            public_interface=self.public_interface(),
            private_interface=self.private_interface(),
            mirror_type=self.mirror_type(),
            use_syslog=use_syslog,
            cinder=cinder,
            quantum=quantum,
        )
        self.write_manifest(remote, template)


    def write_openstack_manifest(self, remote, template, ci, controllers, quantums,
                                 proxies=None, use_syslog=True,
                                 quantum=True, loopback=True,
                                 cinder=True, swift=True):
        template.replace(
            internal_virtual_ip=ci.internal_virtual_ip(),
            public_virtual_ip=ci.public_virtual_ip(),
            floating_range=self.floating_network(ci, quantum),
            fixed_range=self.fixed_network(ci,quantum),
            master_hostname=controllers[0].name,
            mirror_type=self.mirror_type(),
            controller_public_addresses=self.public_addresses(
                controllers),
            controller_internal_addresses=self.internal_addresses(
                controllers),
            controller_hostnames=self.hostnames(controllers),
            public_interface=self.public_interface(),
            internal_interface=self.internal_interface(),
            private_interface=self.private_interface(),
            nv_physical_volume=self.physical_volumes(),
            use_syslog=use_syslog,
            cinder=cinder,
            cinder_on_computes=cinder,
            external_ipinfo = self.external_ip_info(ci, quantums),
        )
        if swift:
            template.replace(swift_loopback=self.loopback(loopback))
            if proxies:
                template.replace(
                    swift_master=proxies[0].name,
                    swift_proxies=self.internal_addresses(proxies)
                )
            else:
                template.replace(
                    swift_master="%s" % controllers[0].name,
                    swift_proxies=self.internal_addresses(controllers)
                )
        if is_not_essex():
            template.replace(
                quantum=quantum,
                )

        self.write_manifest(remote, template)


    def write_swift_manifest(self, remote, controllers,
                             proxies=None):
        template = Template(
            root('deployment', 'puppet', 'swift', 'examples',
                'site.pp'))
        template.replace(
            swift_proxy_address=proxies[0].get_ip_address_by_network_name(
                'internal'),
            controller_node_public=controllers[
                                   0].get_ip_address_by_network_name(
                'public'),
        )
        self.write_manifest(remote, template)

    def write_cobbler_manifest(self, remote, ci, cobblers):
        site_pp = Template(root('deployment', 'puppet', 'cobbler', 'examples',
            'server_site.pp'))
        cobbler = cobblers[0]
        cobbler_address = cobbler.get_ip_address_by_network_name('internal')
        network = IPNetwork(ci.environment().network_by_name(
            'internal').ip_network)
        site_pp.replace(
            server=cobbler_address,
            name_server=cobbler_address,
            next_server=cobbler_address,
            dhcp_start_address=network[5],
            dhcp_end_address=network[-1],
            dhcp_netmask=network.netmask,
            dhcp_gateway=network[1],
            pxetimeout='3000'
        )
        self.write_manifest(remote, site_pp)

    def write_stomp_manifest(self, remote):
        self.write_manifest(remote, Template.stomp().replace(
            mirror_type=self.mirror_type()
        ))





