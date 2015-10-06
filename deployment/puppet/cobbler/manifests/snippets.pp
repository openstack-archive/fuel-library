#    Copyright 2013 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.


class cobbler::snippets {
  cobbler::cobbler_snippet {"send2syslog": }
  cobbler::cobbler_snippet {"target_logs_to_master": }
  cobbler::cobbler_snippet {"target_logs_to_master_ubuntu": }
  cobbler::cobbler_snippet {"kickstart_ntp": }
  cobbler::cobbler_snippet {"ntp_to_masternode": }
  cobbler::cobbler_snippet {"ntp_to_masternode_ubuntu": }
  cobbler::cobbler_snippet {"pre_install_network_config": }
  cobbler::cobbler_snippet {"pre_install_partition": }
  cobbler::cobbler_snippet {"pre_install_partition_lvm": }
  cobbler::cobbler_snippet {"nailgun_repo": }
  cobbler::cobbler_snippet {"ssh_disable_gssapi": }
  cobbler::cobbler_snippet {"sshd_auth_pubkey_only": }
  cobbler::cobbler_snippet {"disable_pxe":}
  cobbler::cobbler_snippet {"post_part_compute":}
  cobbler::cobbler_snippet {"post_part_controller":}
  cobbler::cobbler_snippet {"post_part_storage":}
  cobbler::cobbler_snippet {"post_install_network_config_fuel":}
  cobbler::cobbler_snippet {"puppet_register_if_enabled_fuel":}
  cobbler::cobbler_snippet {"url_proxy":}
  cobbler::cobbler_snippet {"puppet_install_if_enabled":}
  cobbler::cobbler_snippet {"puppet_conf":}
  cobbler::cobbler_snippet {"puppet_register_if_enabled":}
  cobbler::cobbler_snippet {'ntp_register_if_enabled':}
  cobbler::cobbler_snippet {"mcollective_install_if_enabled":}
  cobbler::cobbler_snippet {"mcollective_conf":}
  cobbler::cobbler_snippet {"post_install_network_config":}
  cobbler::cobbler_snippet {"cinder_create_lvm_group":}
  cobbler::cobbler_snippet {"cinder_create_lvm_group__ubuntu":}
  cobbler::cobbler_snippet {"centos_authorized_keys": }
  cobbler::cobbler_snippet {"centos_blacklist_i2c_piix4":}
  cobbler::cobbler_snippet {"centos_static_net":}
  cobbler::cobbler_snippet {"ofed_install_with_sriov":}
  cobbler::cobbler_snippet {"ubuntu_authorized_keys":}
  cobbler::cobbler_snippet {"ubuntu_blacklist_i2c_piix4":}
  cobbler::cobbler_snippet {"ubuntu_disable_pxe":}
  cobbler::cobbler_snippet {"ubuntu_puppet_config":}
  cobbler::cobbler_snippet {"ubuntu_mcollective_config":}
  cobbler::cobbler_snippet {"ubuntu_network":}
  cobbler::cobbler_snippet {"ubuntu_network_console_and_syslog":}
  cobbler::cobbler_snippet {"ubuntu_partition":}
  cobbler::cobbler_snippet {"ubuntu_partition_late":}
  cobbler::cobbler_snippet {"ubuntu_static_net":}
  cobbler::cobbler_snippet {"ubuntu_repos_late":}
  cobbler::cobbler_snippet {"ubuntu_remove_repos_late":}
  cobbler::cobbler_snippet {"ubuntu_precise_packages_late":}
  cobbler::cobbler_snippet {"ubuntu_trusty_packages_late":}
  cobbler::cobbler_snippet {"anaconda_ssh_console":}
  cobbler::cobbler_snippet {"anaconda_yum":}
  cobbler::cobbler_snippet {'centos_post_kernel_lt_if_enabled':}
  cobbler::cobbler_snippet {'centos_pkg_kernel_lt_if_enabled':}
  cobbler::cobbler_snippet {'centos_ofed_prereq_pkgs_if_enabled':}

  case $::operatingsystem {
    /(?i)(debian|ubuntu)/:  {
      file { "/usr/bin/late_command.py" :
        content => template("cobbler/scripts/late_command.py"),
        owner => 'root',
        group => 'root',
        mode => '0644',
      }
      file { "/usr/bin/pmanager.py" :
        content => template("cobbler/scripts/pmanager.py"),
        owner => 'root',
        group => 'root',
        mode => '0644',
      }
    }
    /(?i)(centos|redhat)/:  {
      file { "/usr/lib/python2.6/site-packages/cobbler/late_command.py" :
        content => template("cobbler/scripts/late_command.py"),
        owner => 'root',
        group => 'root',
        mode => '0644',
      }
      file { "/usr/lib/python2.6/site-packages/cobbler/pmanager.py" :
        content => template("cobbler/scripts/pmanager.py"),
        owner => 'root',
        group => 'root',
        mode => '0644',
      }
    }
  }

}
