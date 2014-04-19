#    Copyright 2014 Mirantis, Inc.
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

# modules needed: nova
# limitations:
# - only one vmware cluster supported

class vmware::controller (

  $vcenter_user = 'user',
  $vcenter_password = 'password',
  $vcenter_host_ip = '10.10.10.10',
  $vcenter_cluster = 'cluster',
  $use_quantum = false,
  $ensure_package = 'present',

)

{ # begin of class

  # installing the nova-compute service
  nova::generic_service { 'compute':
    enabled        => true,
    package_name   => $::nova::params::compute_package_name,
    service_name   => $::nova::params::compute_service_name,
    ensure_package => $ensure_package,
    before         => Exec['networking-refresh']
  }

  # network configuration
  class { 'vmware::network':
    use_quantum => $use_quantum,
  }

  # workaround for Ubuntu additional package for hypervisor
  case $::osfamily { # open case
    'RedHat': { # open RedHat
      # nova-compute service configuration
      class { 'nova::compute::vmware':
        host_ip => $vcenter_host_ip,
        host_username => $vcenter_user,
        host_password => $vcenter_password,
        cluster_name => $vcenter_cluster,
      }
    } # close RedHat
    'Debian': { # open Ubuntu
      class { 'nova::compute::vmware':
        host_ip => $vcenter_host_ip,
        host_username => $vcenter_user,
        host_password => $vcenter_password,
        cluster_name => $vcenter_cluster,
      } -> # and then we should do the workaround
      exec { 'clean-nova-compute-conf': # open exec
        command => "/bin/echo > /etc/nova/nova-compute.conf"
      } # close exec
    } # close Ubuntu
  } # close case

  # install cirros vmdk package

  package { 'cirros-testvmware':
    ensure => "present"
  }

} # end of class
