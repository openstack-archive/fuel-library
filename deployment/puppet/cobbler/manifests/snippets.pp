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

  ::cobbler::snippet {'send2syslog': }
  ::cobbler::snippet {'target_logs_to_master': }
  ::cobbler::snippet {'target_logs_to_master_ubuntu': }
  ::cobbler::snippet {'kickstart_ntp': }
  ::cobbler::snippet {'ntp_to_masternode': }
  ::cobbler::snippet {'ntp_to_masternode_ubuntu': }
  ::cobbler::snippet {'pre_install_network_config': }
  ::cobbler::snippet {'pre_install_partition': }
  ::cobbler::snippet {'pre_install_partition_lvm': }
  ::cobbler::snippet {'nailgun_repo': }
  ::cobbler::snippet {'ssh_disable_gssapi': }
  ::cobbler::snippet {'sshd_auth_pubkey_only': }
  ::cobbler::snippet {'disable_pxe':}
  ::cobbler::snippet {'post_part_compute':}
  ::cobbler::snippet {'post_part_controller':}
  ::cobbler::snippet {'post_part_storage':}
  ::cobbler::snippet {'post_install_network_config_fuel':}
  ::cobbler::snippet {'puppet_register_if_enabled_fuel':}
  ::cobbler::snippet {'url_proxy':}
  ::cobbler::snippet {'puppet_install_if_enabled':}
  ::cobbler::snippet {'puppet_conf':}
  ::cobbler::snippet {'puppet_register_if_enabled':}
  ::cobbler::snippet {'ntp_register_if_enabled':}
  ::cobbler::snippet {'mcollective_install_if_enabled':}
  ::cobbler::snippet {'mcollective_conf':}
  ::cobbler::snippet {'post_install_network_config':}
  ::cobbler::snippet {'cinder_create_lvm_group':}
  ::cobbler::snippet {'cinder_create_lvm_group__ubuntu':}
  ::cobbler::snippet {'centos_authorized_keys': }
  ::cobbler::snippet {'centos_blacklist_i2c_piix4':}
  ::cobbler::snippet {'centos_static_net':}
  ::cobbler::snippet {'ofed_install_with_sriov':}
  ::cobbler::snippet {'ubuntu_authorized_keys':}
  ::cobbler::snippet {'ubuntu_blacklist_i2c_piix4':}
  ::cobbler::snippet {'ubuntu_disable_pxe':}
  ::cobbler::snippet {'ubuntu_puppet_config':}
  ::cobbler::snippet {'ubuntu_mcollective_config':}
  ::cobbler::snippet {'ubuntu_network':}
  ::cobbler::snippet {'ubuntu_network_console_and_syslog':}
  ::cobbler::snippet {'ubuntu_partition':}
  ::cobbler::snippet {'ubuntu_partition_late':}
  ::cobbler::snippet {'ubuntu_static_net':}
  ::cobbler::snippet {'ubuntu_repos_late':}
  ::cobbler::snippet {'ubuntu_remove_repos_late':}
  ::cobbler::snippet {'ubuntu_precise_packages_late':}
  ::cobbler::snippet {'ubuntu_trusty_packages_late':}
  ::cobbler::snippet {'anaconda_ssh_console':}
  ::cobbler::snippet {'anaconda_yum':}
  ::cobbler::snippet {'centos_post_kernel_lt_if_enabled':}
  ::cobbler::snippet {'centos_pkg_kernel_lt_if_enabled':}
  ::cobbler::snippet {'centos_ofed_prereq_pkgs_if_enabled':}

  case $::operatingsystem {
    /(?i)(debian|ubuntu)/:  {
      file { '/usr/bin/late_command.py' :
        content => template('cobbler/scripts/late_command.py'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
      }
      file { '/usr/bin/pmanager.py' :
        content => template('cobbler/scripts/pmanager.py'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
      }
    }
    /(?i)(centos|redhat)/:  {
      if $::operatingsystemrelease =~ /^7.*/ {
        $pyversion = '2.7'
      } else {
        $pyversion = '2.6'
      }
      file { "/usr/lib/python${pyversion}/site-packages/cobbler/late_command.py" :
        content => template('cobbler/scripts/late_command.py'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
      }
      file { "/usr/lib/python${pyversion}/site-packages/cobbler/pmanager.py" :
        content => template('cobbler/scripts/pmanager.py'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
      }
    }
  }

}
