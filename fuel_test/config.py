import yaml
from fuel_test.manifest import Manifest
from fuel_test.settings import CURRENT_PROFILE, PUPPET_VERSION, INTERFACES, DOMAIN_NAME


class Config():
    def generate(self, ci, nodes, template, quantums=None, cinder=True, quantum_netnode_on_cnt=True,
                 create_networks=True, quantum=True, swift=True, loopback="loopback", use_syslog=True,
                 cinder_nodes=None):
        config = {
            "common":
                {"orchestrator_common": self.orchestrator_common(ci, template=template),
                 "openstack_common": self.openstack_common(ci, nodes=nodes,
                                                           quantums=quantums,
                                                           cinder=cinder,
                                                           cinder_nodes=cinder_nodes,
                                                           quantum_netnode_on_cnt=quantum_netnode_on_cnt,
                                                           create_networks=create_networks,
                                                           quantum=quantum,
                                                           swift=swift,
                                                           loopback=loopback,
                                                           use_syslog=use_syslog),
                 "cobbler_common": self.cobbler_common(ci),
                }
        }

        config.update(self.cobbler_nodes(ci, nodes))

        return yaml.safe_dump(config, default_flow_style=False)

    def orchestrator_common(self, ci, template):
        config = {"task_uuid": "deployment_task"}
        attributes = {"attributes": {"deployment_mode": template.deployment_mode, "deployment_engine": "simplepuppet"}}
        config.update(attributes)

        return config

    def openstack_common(self, ci, nodes, quantums, cinder, quantum_netnode_on_cnt, create_networks, quantum, swift,
                         loopback, use_syslog, cinder_nodes):
        if not cinder_nodes: cinder_nodes = []
        if not quantums: quantums = []

        node_configs = Manifest().generate_node_configs_list(ci, nodes)

        master = ci.nodes().masters[0]

        config = {"auto_assign_floating_ip": True,
                  "create_networks": create_networks,
                  "default_gateway": ci.public_router(),
                  "deployment_id": Manifest().deployment_id(ci),
                  "dns_nameservers": Manifest().generate_dns_nameservers_list(ci),
                  "external_ip_info": Manifest().external_ip_info(ci, quantums),
                  "fixed_range": Manifest().fixed_network(ci),
                  "floating_range": Manifest().floating_network(ci),
                  "internal_interface": Manifest().internal_interface(),
                  "internal_netmask": ci.internal_net_mask(),
                  "internal_virtual_ip": ci.internal_virtual_ip(),
                  "mirror_type": Manifest().mirror_type(),
                  "nagios_master": ci.nodes().controllers[0].name + DOMAIN_NAME,
                  "network_manager": "nova.network.manager.FlatDHCPManager",
                  "nv_physical_volumes": ["/dev/vdb"],
                  "private_interface": Manifest().private_interface(),
                  "public_interface": Manifest().public_interface(),
                  "public_netmask": ci.public_net_mask(),
                  "public_virtual_ip": ci.public_virtual_ip(),
                  "quantum": quantum,
                  "repo_proxy": "http://%s:3128" % master.get_ip_address_by_network_name('internal'),
                  "segment_range": "900:999",
                  "swift": swift,
                  "swift_loopback": loopback,
                  "syslog_server": str(master.get_ip_address_by_network_name('internal')),
                  "use_syslog": use_syslog,
                  "cinder": cinder,
                  "quantum_netnode_on_cnt": quantum_netnode_on_cnt
        }

        config.update({"cinder_nodes": cinder_nodes})

        config.update({"nodes": node_configs})

        return config

    def cobbler_common(self, ci):
        config = {"gateway": str(ci.nodes().masters[0].get_ip_address_by_network_name('internal')),
                  "name-servers": str(ci.nodes().masters[0].get_ip_address_by_network_name('internal')),
                  "name-servers-search": "localdomain",
                  "profile": CURRENT_PROFILE}

        ksmeta = self.get_ks_meta(ci.nodes().masters[0].name + DOMAIN_NAME, ci.nodes().masters[0].name)

        config.update({"ksmeta": ksmeta})

        return config

    def get_ks_meta(self, puppet_master, mco_host):
        return ("puppet_auto_setup=1 "
                "puppet_master=%(puppet_master)s "
                "puppet_version=%(puppet_version)s "
                "puppet_enable=0 "
                "mco_auto_setup=1 "
                "ntp_enable=1 "
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

    def cobbler_nodes(self, ci, nodes):
        all_nodes = {}
        for node in nodes:
            interfaces = {
                INTERFACES.get('internal'):
                    {
                        "mac": node.interfaces.filter(network__name='internal')[0].mac_address,
                        "static": 1,
                        "ip-address": str(node.get_ip_address_by_network_name('internal')),
                        "netmask": ci.internal_net_mask(),
                        "dns-name": node.name + DOMAIN_NAME,
                        "management": "1"
                    }
            }
            interfaces_extra = {
                "eth0":
                    {"peerdns": 'no'},
                "eth1":
                    {"peerdns": 'no'},
                "eth2":
                    {"peerdns": 'no',
                     "promisc": 'yes',
                     "userctl": 'yes'}
            }
            all_nodes.update({node.name: {"hostname": node.name,
                                          "interfaces": interfaces,
                                          "interfaces_extra": interfaces_extra,
                                          }
            }
        )

        return all_nodes
