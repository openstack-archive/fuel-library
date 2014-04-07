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


class mcollective::client(
  $pskey = "secret",
  $user = "mcollective",
  $password = "mcollective",
  $host = "127.0.0.1",
  $stompport = "61613",
  $vhost = "mcollective",
  $stomp = false,
  ){

  include mcollective::clientpackages

  case $::osfamily {
    'Debian': {
      $mcollective_client_config_template="mcollective/client.cfg.ubuntu.erb"
      $mcollective_agent_path = "/usr/share/mcollective/plugins/mcollective/agent"
    }
    'RedHat': {
      $mcollective_client_config_template="mcollective/client.cfg.erb"
      $mcollective_agent_path = "/usr/libexec/mcollective/mcollective/agent"
    }
    default: {
      fail("Unsupported osfamily: ${osfamily} for os ${operatingsystem}")
    }
  }

  file { "/etc/mcollective": ensure => directory }

  file { "/etc/mcollective/client.cfg":
    ensure  => present,
    content => template($mcollective_client_config_template),
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    require => Class['::mcollective::clientpackages'],
  }
  ###DEPRECATED - RETAINED FROM OLD FUEL VERSIONS####
  #  file {"${mcollective_agent_path}/puppetd.ddl" :
  #  content => template("mcollective/puppetd.ddl.erb"),
  #  owner => root,
  #  group => root,
  #  mode => 0600,
  #  require => Package[$mcollective_client_package],
  # }
  #
  # file {"${mcollective_agent_path}/puppetd.rb" :
  #  content => template("mcollective/puppetd.rb.erb"),
  #  owner => root,
  #  group => root,
  #  mode => 0600,
  #  require => Package[$mcollective_client_package],
  # }
}
