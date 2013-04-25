from fuel_test.ci.ci_vm import CiVM
from fuel_test.settings import CURRENT_PROFILE, PUPPET_VERSION, INTERFACES

class Config(object):
    @classmethod
    def generate(cls, ci):
        config = {
            "common":
                { "orchestrator_common": cls.orchestrator_common(ci),
                  "openstack_common": cls.openstack_common(ci),
                  "cobbler_common": cls.cobbler_common(ci),
                  }
        }.update(cls.cobbler_nodes(ci.nodes))

    @classmethod
    def orchestrator_common(cls):
        config = {"task_uuid": "deployment_task"}
        attributes = {"attributes": {"deployment_mode": "multinode_compute", "deployment_engine": "simplepuppet"}}
        config.update(attributes)

        return config

    @classmethod
    def openstack_common(cls, ci):
        external_ip_info = {"ext_bridge": "10.49.54.15",
                            "pool_end": "10.49.54.239",
                            "pool_start": "10.49.54.225",
                            "public_net_router": "10.49.54.1"
        }

        nodes = []
        for node in ci.nodes().cobblers + ci.nodes().computes:
            nodes.appent({"internal_address": "10.0.0.100",
                   "name": str(node.name),
                   "public_address": node.get_ip_address_by_network_name('public'),
                   "role": str(node.role)})

        for node in ci.nodes().controllers + ci.nodes().storages:
            nodes.appent({"internal_address": "10.0.0.101",
                          "mountpoints": "1 2\n 2 1",
                          "name": str(node.name),
                          "public_address": "10.0.1.101",
                          "role": str(node.role),
                          "storage_local_net_ip": "10.0.0.101",
                          "swift_zone": "1"})

        config = {"auto_assign_floating_ip": "true",
                  "cinder": "true",
                  "cinder_on_computes": "true",
                  "create_networks": "true",
                  "default_gateway": "10.0.1.100",
                  "deployment_id": "53",
                  "dns_nameservers": ["10.0.0.100", "8.8.8.8"],
                  "external_ip_info": external_ip_info,
                  "fixed_range": "192.168.0.0/16",
                  "floating_range": "10.49.54.0/24",
                  "internal_interface": "eth0",
                  "internal_netmask": "255.255.255.0",
                  "internal_virtual_ip": "10.49.63.127",
                  "mirror_type": "custom",
                  "nagios_master": "%s.your-domain-name.com" % ci.nodes().controllers[0].name,
                  "network_manager": "nova.network.manager.FlatDHCPManager",
                  "nv_physical_volumes": ["/dev/sdz", "/dev/sdy"],
                  "private_interface": INTERFACES["private"],
                  "public_interface": INTERFACES["public"],
                  "public_netmask": "255.255.255.0",
                  "public_virtual_ip": "10.49.54.127",
                  "quantum": "true",
                  "quantum_netnode_on_cnt": "true",
                  "repo_proxy": "http://10.0.0.100:3128",
                  "segment_range": "900:999",
                  "swift": "true",
                  "swift_loopback": "loopback",
                  "syslog_server": "10.49.63.12",
                  "use_syslog": "true",
                  "nodes": nodes
        }

        return config

    @classmethod
    def cobbler_common(cls, ci):
        config = {"gateway": "10.0.0.100",
                  "name-servers": "10.0.0.100",
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

    @classmethod
    def cobbler_nodes(cls, nodes):
        all_nodes = {}
        for node in nodes():
            node_name = str(node.name)
            all_nodes.update({node_name: {"hostname": node_name,
                                          "interfaces": interfacse,
                                          "interfaces_extra": interfaces_extra,
                                          "role": node.role}})

        return all_nodes
