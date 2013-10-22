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
#
#
#
# This class is intended to make cobbler profile ubuntu_1204_x86_64.
#
# [distro] The name of cobbler distro to bind profile to.
#
# [ks_system_timezone] System timezone on installed system.
#
# [ks_encrypted_root_password] Hash of the root password on installed system.

class cobbler::profile::ubuntu_1204_x86_64(
  $distro  = "ubuntu_1204_x86_64",
  $ks_repo = [
    {
      "name" => "Mirantis",
      "url"  => "http://download.mirantis.com/precise-grizzly-fuel-3.2/",
      "key"  => "http://download.mirantis.com/precise-grizzly-fuel-3.2/Mirantis.key",
      "release" => "precise",
      "repos" => "main",
    },
  ],

  $ks_system_timezone = "America/Los_Angeles",

  # default password is 'r00tme'
  $ks_encrypted_root_password = "\$6\$tCD3X7ji\$1urw6qEMDkVxOkD33b4TpQAjRiCeDZx0jmgMhDYhfB9KuGfqO9OcMaKyUxnGGWslEDQ4HxTw7vcAMP85NxQe61",

  $kopts = "priority=critical locale=en_US biosdevname=0 netcfg/choose_interface=auto auto=true",
  ){

  case $operatingsystem {
    /(?i)(ubuntu|debian|centos|redhat)$/:  {
      $ks_dir = "/var/lib/cobbler/kickstarts"
    }
  }

  file { "${ks_dir}/ubuntu_1204_x86_64.preseed":
    content => template("cobbler/preseed/ubuntu-1204.preseed.erb"),
    owner => root,
    group => root,
    mode => 0644,
  } ->

  cobbler_profile { "ubuntu_1204_x86_64":
    kickstart => "${ks_dir}/ubuntu_1204_x86_64.preseed",
    kopts => $kopts,
    distro => $distro,
    ksmeta => "",
    menu => true,
  }

  }
