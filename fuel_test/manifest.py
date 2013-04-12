from ipaddr import IPNetwork
import re
from fuel_test.helpers import load, write_config, is_not_essex
from fuel_test.root import root
from fuel_test.settings import INTERFACES, TEST_REPO


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
            'site_openstack_ha_minimal.pp'))

    @classmethod
    def compact(cls):
        return cls(root('deployment', 'puppet', 'openstack', 'examples',
            'site_openstack_ha_compact.pp'))

    @classmethod
    def full(cls):
        return cls(root('deployment', 'puppet', 'openstack', 'examples',
            'site_openstack_ha_full.pp'))

    @classmethod
    def nagios(cls):
        return cls(root('deployment', 'puppet', 'nagios', 'examples',
                        'master.pp'))


class Manifest(object):
    def mirror_type(self):
        return 'custom'

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

    def addresses(self, nodes):
        return dict(map(
            lambda x:
            (str(x.name),
               {
                   'internal_address': x.get_ip_address_by_network_name('internal'),
                   'public_address': x.get_ip_address_by_network_name('public'),
               },
        ),
            nodes)
        )

    def generate_dns_nameservers_list(self, ci):
        return map(
            lambda x: x.get_ip_address_by_network_name('internal'), ci.nodes().cobblers)

    def describe_node(self, node, role):
        return {'name': str(node.name), 'role' : role,
         'internal_address': node.get_ip_address_by_network_name('internal'),'public_address': node.get_ip_address_by_network_name('public'),}

    def describe_swift_node(self, node, role, zone):
        node_dict = self.describe_node(node, role)
        node_dict.update({'swift_zone': zone})
        return node_dict

    def generate_nodes_configs_list(self, ci):
        zones = range(1, 50)
        nodes = []
        for node in ci.nodes().computes: nodes.append(self.describe_node(node, 'compute'))
        for node in ci.nodes().controllers: nodes.append(self.describe_swift_node(node, 'controller', zones.pop()))
        for node in ci.nodes().storages: nodes.append(self.describe_swift_node(node, 'storage', zones.pop()))
        for node in ci.nodes().proxies: nodes.append(self.describe_node(node, 'swift-proxy'))
        for node in ci.nodes().quantums: nodes.append(self.describe_node(node, 'quantum'))
        for node in ci.nodes().masters: nodes.append(self.describe_node(node, 'master'))
        for node in ci.nodes().cobblers: nodes.append(self.describe_node(node, 'cobbler'))
        for node in ci.nodes().stomps: nodes.append(self.describe_node(node, 'stomp'))
        return nodes

    def self_test(self):
        class Node(object):
            def __init__(self, name):
                super(Node, self).__init__()
                self.name = name
            def get_ip_address_by_network_name(self, name):
                return '10.0.55.66'
        print self.addresses([Node('fuel-controller-01'), Node('fuel-controller-02')])

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
                                        use_syslog=False,
                                        quantum=True,
                                        cinder=True, cinder_on_computes=False):
        template = Template(
            root(
                'deployment', 'puppet', 'openstack', 'examples',
                'site_openstack_simple.pp')).replace(
            floating_range=self.floating_network(ci, quantum),
            fixed_range=self.fixed_network(ci, quantum),
            public_interface=self.public_interface(),
            internal_interface=self.internal_interface(),
            private_interface=self.private_interface(),
            mirror_type=self.mirror_type(),
            #controller_node_address=controllers[0].get_ip_address_by_network_name('internal'),
            #controller_node_public=controllers[0].get_ip_address_by_network_name('public'),
            cinder=cinder,
            cinder_on_computes=cinder_on_computes,
            nv_physical_volume=self.physical_volumes(),
            nagios_master = controllers[0].name + '.your-domain-name.com',
            external_ipinfo=self.external_ip_info(ci, controllers),
            nodes=self.generate_nodes_configs_list(ci),
            dns_nameservers=self.generate_dns_nameservers_list(ci),
            ntp_servers=['pool.ntp.org',ci.internal_router()],
            default_gateway=ci.public_router(),
            enable_test_repo=TEST_REPO,
            deployment_id = self.deployment_id(ci),
            use_syslog=use_syslog,
            public_netmask = ci.public_net_mask(),
            internal_netmask = ci.internal_net_mask(),
        )
        if is_not_essex():
            template.replace(
                quantum=quantum,
                quantum_netnode_on_cnt=quantum,
            )
        self.write_manifest(remote, template)


    def write_openstack_single_manifest(self, remote, ci,
                                        use_syslog=True,
                                        quantum=True,
                                        cinder=True):
        template = Template(
            root(
                'deployment', 'puppet', 'openstack', 'examples',
                'site_openstack_single.pp')).replace(
            floating_range=self.floating_network(ci, quantum),
            fixed_range=self.fixed_network(ci, quantum),
            public_interface=self.public_interface(),
            private_interface=self.private_interface(),
            mirror_type=self.mirror_type(),
            use_syslog=use_syslog,
            cinder=cinder,
            ntp_servers=['pool.ntp.org',ci.internal_router()],
            quantum=quantum,
            enable_test_repo = TEST_REPO,
        )
        self.write_manifest(remote, template)


    def write_openstack_ha_minimal_manifest(self, remote, template, ci, controllers, quantums,
                                 proxies=None, use_syslog=True,
                                 quantum=True, loopback=True,
                                 cinder=True, cinder_on_computes=False, quantum_netnode_on_cnt=True,
                                 ha_provider='pacemaker'):
        template.replace(
            internal_virtual_ip=ci.internal_virtual_ip(),
            public_virtual_ip=ci.public_virtual_ip(),
            floating_range=self.floating_network(ci, quantum),
            fixed_range=self.fixed_network(ci,quantum),
            mirror_type=self.mirror_type(),
            public_interface=self.public_interface(),
            internal_interface=self.internal_interface(),
            private_interface=self.private_interface(),
            nv_physical_volume=self.physical_volumes(),
            use_syslog=use_syslog,
            cinder=cinder,
            cinder_on_computes=cinder_on_computes,
            nagios_master = controllers[0].name + '.your-domain-name.com',
            external_ipinfo=self.external_ip_info(ci, quantums),
            nodes=self.generate_nodes_configs_list(ci),
            dns_nameservers=self.generate_dns_nameservers_list(ci),
            default_gateway=ci.public_router(),
            ntp_servers=['pool.ntp.org',ci.internal_router()],
            enable_test_repo=TEST_REPO,
            deployment_id = self.deployment_id(ci),
            public_netmask = ci.public_net_mask(),
            internal_netmask = ci.internal_net_mask(),
        )
        if is_not_essex():
            template.replace(
                quantum=quantum,
                quantum_netnode_on_cnt=quantum_netnode_on_cnt,
                ha_provider=ha_provider,
            )

        self.write_manifest(remote, template)


    def write_openstack_manifest(self, remote, template, ci, controllers, quantums,
                                 proxies=None, use_syslog=True,
                                 quantum=True, loopback=True,
                                 cinder=True, swift=True, quantum_netnode_on_cnt=True,
                                 ha_provider='pacemaker'):
        template.replace(
            internal_virtual_ip=ci.internal_virtual_ip(),
            public_virtual_ip=ci.public_virtual_ip(),
            floating_range=self.floating_network(ci, quantum),
            fixed_range=self.fixed_network(ci,quantum),
            mirror_type=self.mirror_type(),
            public_interface=self.public_interface(),
            internal_interface=self.internal_interface(),
            private_interface=self.private_interface(),
            nv_physical_volume=self.physical_volumes(),
            use_syslog=use_syslog,
            cinder=cinder,
            ntp_servers=['pool.ntp.org',ci.internal_router()],
            cinder_on_computes=cinder,
            nagios_master = controllers[0].name + '.your-domain-name.com',
            external_ipinfo=self.external_ip_info(ci, quantums),
            nodes=self.generate_nodes_configs_list(ci),
            dns_nameservers=self.generate_dns_nameservers_list(ci),
            default_gateway=ci.public_router(),
            enable_test_repo=TEST_REPO,
            deployment_id = self.deployment_id(ci),
            public_netmask = ci.public_net_mask(),
            internal_netmask = ci.internal_net_mask(),
        )
        if swift:
            template.replace(swift_loopback=self.loopback(loopback))
        if is_not_essex():
            template.replace(
                quantum=quantum,
                quantum_netnode_on_cnt=quantum_netnode_on_cnt,
                ha_provider=ha_provider,
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
            pxetimeout='3000',
            mirror_type=self.mirror_type(),
        )
        self.write_manifest(remote, site_pp)

    def write_stomp_manifest(self, remote):
        self.write_manifest(remote, Template.stomp().replace(
            mirror_type=self.mirror_type()
        ))

    def write_nagios_manifest(self, remote):
        self.write_manifest(remote, Template.nagios())

    def deployment_id(self, ci):
        try:
            return str(int(ci.internal_network().split('.')[2]) + 1)
        except:
            return '250'
