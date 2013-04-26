import yaml
from fuel_test.ci.ci_vm import CiVM
from fuel_test.manifest import Manifest
from fuel_test.settings import CURRENT_PROFILE, PUPPET_VERSION

class Config():
    def generate(self, ci):
        config = {
           "common":
               {"orchestrator_common": self.orchestrator_common(ci),
                "openstack_common": self.openstack_common(ci),
                "cobbler_common": self.cobbler_common(ci),
              }
        }

        config.update(self.cobbler_nodes(ci))

        return config

    def orchestrator_common(self, ci):
        config = {"task_uuid": "deployment_task"}
        attributes = {"attributes": {"deployment_mode": "multinode_compute", "deployment_engine": "simplepuppet"}}
        config.update(attributes)

        return config

    def openstack_common(self, ci, quantums=[]):
        nodes = []

        for node in Manifest().generate_nodes_configs_list(ci):
            if node["role"] is not "master":
                nodes.append(node)

        config = {"auto_assign_floating_ip": True,
                   "cinder": True,
                   "cinder_on_computes": True,
                   "create_networks": True,
                   "default_gateway": ci.public_router(),
                   "deployment_id": Manifest().deployment_id(ci),
                   "dns_nameservers": Manifest().generate_dns_nameservers_list(ci),
                   #"external_ip_info": Manifest().external_ip_info(ci, quantums),
                   "fixed_range": Manifest().fixed_network(ci),
                   "floating_range": Manifest().floating_network(ci),
                   "internal_interface": Manifest().internal_interface(),
                   "internal_netmask": ci.internal_net_mask(),
                   "internal_virtual_ip": ci.internal_virtual_ip(),
                   "mirror_type": Manifest().mirror_type(),
                   "nagios_master": "%s.your-domain-name.com" % ci.nodes().controllers[0].name,
                   "network_manager": "nova.network.manager.FlatDHCPManager",
                   "nv_physical_volumes": ["/dev/sdz", "/dev/sdy"],
                   "private_interface": Manifest().private_interface(),
                   "public_interface": Manifest().public_interface(),
                   "public_netmask": ci.public_net_mask(),
                   "public_virtual_ip": ci.public_virtual_ip(),
                   "quantum": True,
                   "quantum_netnode_on_cnt": True,
                   "repo_proxy": "http://10.0.0.100:3128",
                   "segment_range": "900:999",
                   "swift": True,
                   "swift_loopback": "loopback",
                   "syslog_server": "10.49.63.12",
                   "use_syslog": True,
                  "nodes": nodes
        }

        return config

    def cobbler_common(self, ci):
        config = {"gateway": ci.public_router(),
                  "name-servers": ci.public_router(),
                  "name-servers-search": "your-domain-name.com",
                  "profile": CURRENT_PROFILE}

        ksmeta_list = {"puppet_version": PUPPET_VERSION,
                       "puppet_auto_setup": 1,
                       "puppet_master": "%s.your-domain-name.com" % ci.nodes().masters[0].name,
                       "puppet_enable": 0,
                       "ntp_enable": 1,
                       "mco_auto_setup": 1,
                       "mco_pskey": "un0aez2ei9eiGaequaey4loocohjuch4Ievu3shaeweeg5Uthi",
                       "mco_stomphost": "10.0.0.100",
                       "mco_stompport": 61613,
                       "mco_stompuser": "mcollective",
                       "mco_stomppassword": "AeN5mi5thahz2Aiveexo",
                       "mco_enable": 1}

        ksmeta = {"ksmeta": ' '.join(['%s=%s' % (str(k), str(v)) for k, v in ksmeta_list.items()])}

        config.update(ksmeta)

        return config

    def cobbler_nodes(self, ci):
        nodes = Manifest().generate_nodes_configs_list(ci)
        all_nodes = {}
        for node in nodes:
            node_name = str(node["name"])
            interfaces = {"eth0":
                              {"mac": ci.public_net_mask(),
                               "static": 1,
                               "ip-address": node["public_address"],
                               "netmask": "255.255.255.0",
                               "dns-name": "%s.your-domain-name.com" % node_name,
                               "management": "1"},
                          "eth1":
                              {"mac": ci.internal_net_mask(),
                               "static": "0"},
                          "eth2":
                              {"mac": ci.public_net_mask(),
                               "static": "1"}
            }

            interfaces_extra = {"eth0":
                                    {"peerdns": 'no'},
                                "eth1":
                                    {"peerdns": 'no'},
                                "eth2":
                                    {"peerdns": 'no',
                                     "promisc": 'yes',
                                     "userctl": 'yes'}
            }

            all_nodes.update({node_name: {"hostname": node_name,
                                          "interfaces": interfaces,
                                          "interfaces_extra": interfaces_extra,
                                          "role": node["role"]}
                            }
            )

        return all_nodes


if __name__ == "__main__":
    ci = CiVM()
    config = Config().generate(ci)
    print yaml.safe_dump(config, default_flow_style=False)

    #with open("/home/alan/fuel/deployment/mcollective/astute/samples/config_test.yaml", "r") as f:
    #    config = yaml.safe_load(f)
    #   print config
