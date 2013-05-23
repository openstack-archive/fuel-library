from ipaddr import IPNetwork
import re
from fuel_test.helpers import load, write_config
from fuel_test.root import root
from fuel_test.settings import INTERFACES, TEST_REPO, DOMAIN_NAME


class Template(object):
    def __init__(self, path, deployment_mode=None):
        super(Template, self).__init__()
        self.value = load(path)
        self.deployment_mode = deployment_mode

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
        return cls(root('deployment', 'puppet', 'mcollective', 'examples', 'site.pp'))

    @classmethod
    def minimal(cls):
        return cls(root('deployment', 'puppet', 'openstack', 'examples', 'site_openstack_ha_minimal.pp'),
                   deployment_mode='ha_minimal')

    @classmethod
    def compact(cls):
        return cls(root('deployment', 'puppet', 'openstack', 'examples', 'site_openstack_ha_compact.pp'),
                   deployment_mode='ha_compact')

    @classmethod
    def full(cls):
        return cls(root('deployment', 'puppet', 'openstack', 'examples', 'site_openstack_ha_full.pp'),
                   deployment_mode='ha_full')

    @classmethod
    def nagios(cls):
        return cls(root('deployment', 'puppet', 'nagios', 'examples', 'master.pp'))

    @classmethod
    def simple(cls):
        return cls(
            root(
                'deployment', 'puppet', 'openstack', 'examples',
                'site_openstack_simple.pp'))

    @classmethod
    def single(cls):
        return cls(
            root(
                'deployment', 'puppet', 'openstack', 'examples',
                'site_openstack_single.pp'))


class Manifest(object):
    def mirror_type(self):
        return 'default'

    @classmethod
    def write_manifest(cls, remote, manifest):
        write_config(
            remote, '/etc/puppet/manifests/site.pp',
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
            lambda x: x.get_ip_address_by_network_name('internal'), ci.nodes().masters)

    def describe_node(self, node, role):
        return {'name': str(node.name),
                'role': role,
                'internal_address': node.get_ip_address_by_network_name('internal'),
                'public_address': node.get_ip_address_by_network_name('public')
        }

    def describe_swift_node(self, node, role, zone):
        node_dict = self.describe_node(node, role)
        node_dict.update({'swift_zone': zone})
        node_dict.update({'storage_local_net_ip': node.get_ip_address_by_network_name('internal')})
        node_dict.update({'mountpoints': '1 2\n 2 1'})
        return node_dict

    def generate_node_configs_list(self, ci, nodes):
        zones = range(1, 50)
        node_configs = []

        for node in nodes:
            if node in ci.nodes().computes: node_configs.append(self.describe_node(node, 'compute'))
            elif node in ci.nodes().controllers[:1]: node_configs.append(self.describe_swift_node(node, 'primary-controller', zones.pop()))
            elif node in ci.nodes().controllers[1:]: node_configs.append(self.describe_swift_node(node, 'controller', zones.pop()))
            elif node in ci.nodes().storages: node_configs.append(self.describe_swift_node(node, 'storage', zones.pop()))
            elif node in ci.nodes().proxies[:1]: node_configs.append(self.describe_node(node, 'primary-swift-proxy'))
            elif node in ci.nodes().proxies[1:]: node_configs.append(self.describe_node(node, 'swift-proxy'))
            elif node in ci.nodes().quantums: node_configs.append(self.describe_node(node, 'quantum'))
            elif node in ci.nodes().masters: node_configs.append(self.describe_node(node, 'master'))
            elif node in ci.nodes().cobblers: node_configs.append(self.describe_node(node, 'cobbler'))
            elif node in ci.nodes().stomps: node_configs.append(self.describe_node(node, 'stomp'))

        return node_configs

    def external_ip_info(self, ci, quantums):
        if len(quantums):
            ext_bridge = str(quantums[0].get_ip_address_by_network_name('public'))
        else:
            ext_bridge = '0.0.0.0'

        floating_network = IPNetwork(ci.floating_network())
        return {
            'public_net_router': ci.public_router(),
            'ext_bridge': ext_bridge,
            'pool_start': str(floating_network[2]),
            'pool_end': str(floating_network[-2])
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

    def floating_network(self, ci, quantum=True):
        if quantum:
            return ci.public_network()
        else:
            return ci.floating_network()

    def fixed_network(self, ci, quantum=True):
        if quantum:
            return '192.168.111.0/24'
        else:
            return ci.fixed_network()

    def generate_openstack_single_manifest(self, ci,
                                           use_syslog=True,
                                           quantum=True,
                                           cinder=True):
        return Template.single().replace(
            floating_range=self.floating_network(ci, quantum),
            fixed_range=self.fixed_network(ci, quantum),
            public_interface=self.public_interface(),
            private_interface=self.private_interface(),
            mirror_type=self.mirror_type(),
            use_syslog=use_syslog,
            cinder=cinder,
            ntp_servers=['pool.ntp.org', ci.internal_router()],
            quantum=quantum,
            enable_test_repo=TEST_REPO,
        )

    def generate_openstack_manifest(self, template,
                                    ci,
                                    controllers,
                                    quantums,
                                    proxies=None,
                                    use_syslog=True,
                                    quantum=True,
                                    loopback=True,
                                    cinder=True,
                                    cinder_nodes=None,
                                    quantum_netnode_on_cnt=True,
                                    swift=True,
                                    ha_provider='pacemaker', ha=True):
        if ha:
            template.replace(
                internal_virtual_ip=ci.internal_virtual_ip(),
                public_virtual_ip=ci.public_virtual_ip(),
        )
        template.replace(
            floating_range=self.floating_network(ci, quantum),
            fixed_range=self.fixed_network(ci, quantum),
            mirror_type=self.mirror_type(),
            public_interface=self.public_interface(),
            internal_interface=self.internal_interface(),
            private_interface=self.private_interface(),
            nv_physical_volume=self.physical_volumes(),
            use_syslog=use_syslog,
            cinder=cinder,
            ntp_servers=['pool.ntp.org', ci.internal_router()],
            nagios_master=controllers[0].name + DOMAIN_NAME,
            cinder_nodes=cinder_nodes,
            external_ipinfo=self.external_ip_info(ci, quantums),
            nodes=self.generate_node_configs_list(ci, ci.nodes()),
            dns_nameservers=self.generate_dns_nameservers_list(ci),
            default_gateway=ci.public_router(),
            enable_test_repo=TEST_REPO,
            deployment_id=self.deployment_id(ci),
            public_netmask=ci.public_net_mask(),
            internal_netmask=ci.internal_net_mask(),
            quantum=quantum,
            quantum_netnode_on_cnt=quantum_netnode_on_cnt,
            ha_provider=ha_provider
        )
        if swift:
            template.replace(swift_loopback=self.loopback(loopback))
        return template

    def generate_swift_manifest(self, controllers,
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
        return template

    def generate_cobbler_manifest(self, ci, cobblers):
        site_pp = Template(root('deployment', 'puppet', 'cobbler', 'examples', 'server_site.pp'))
        cobbler = cobblers[0]
        cobbler_address = cobbler.get_ip_address_by_network_name('internal')
        network = IPNetwork(ci.environment().network_by_name('internal').ip_network)
        self.replace = site_pp.replace(server=cobbler_address,
                                       name_server=cobbler_address,
                                       next_server=cobbler_address,
                                       dhcp_start_address=network[5],
                                       dhcp_end_address=network[-1],
                                       dhcp_netmask=network.netmask,
                                       dhcp_gateway=network[1],
                                       pxetimeout='3000',
                                       mirror_type=self.mirror_type(),
        )

    def generate_stomp_manifest(self):
        return Template.stomp().replace(
            mirror_type=self.mirror_type()
        )

    def generate_nagios_manifest(self):
        return Template.nagios()

    def deployment_id(self, ci):
        try:
            return str(int(ci.internal_network().split('.')[2]) + 1)
        except:
            return '250'
