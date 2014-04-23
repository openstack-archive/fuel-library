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


class mcollective::server(
  $pskey = "secret",
  $user = "mcollective",
  $password = "mcollective",
  $host = "127.0.0.1",
  $stompport = "61613",
  $vhost = "mcollective",
  $stomp = false,
  ){

  include mcollective::clientpackages

  case $operatingsystem {
    /(?i)(centos|redhat)/:  {
      # THIS PACKAGE ALSO INSTALLS REQUIREMENTS
      case $::rubyversion {
        # ruby21-mcollective-common
        # ruby21-rubygem-stomp
        '2.1.1': {
          $mcollective_package = "ruby21-mcollective"
        }
        # mcollective-common
        # rubygems
        # rubygem-stomp
        '1.8.7': {
          $mcollective_package = "mcollective"
        }
      }
    }
    default: {
      fail("Unsupported operating system: ${operatingsystem}")
    }
  }

  package { $mcollective_package : }

  file {"/etc/mcollective/server.cfg" :
    content => template("mcollective/server.cfg.erb"),
    owner => root,
    group => root,
    mode => 0600,
    require => Package[$mcollective_package],
    notify => Service['mcollective'],
  }

  service { "mcollective":
    enable => true,
    ensure => "running",
    require => File["/etc/mcollective/server.cfg"],
  }

}
