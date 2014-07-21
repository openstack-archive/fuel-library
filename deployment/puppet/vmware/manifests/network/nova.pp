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

# VMWare network class for nova-network

class vmware::network::nova (
  $ensure_package = 'present',
  $ha_mode = false,
  $amqp_port = '5673',
  $nova_network_config = '/etc/nova/nova.conf'
)
{
  if ! $ha_mode {
    nova::generic_service { 'network':
      enabled        => true,
      # We cant ensure that ::nova::params is parsed so it is possible for these to become undef.
      # TODO (adanin) Rewrite it properly.
      package_name   => $::nova::params::network_package_name,
      service_name   => $::nova::params::network_service_name,
      ensure_package => $ensure_package,
      before         => Exec['networking-refresh']
    }
  } else {
    # Note that nova-compute is disabled in vmware::controller
    nova::generic_service { 'network':
      enabled        => false,
      package_name   => $::nova::params::network_package_name,
      service_name   => $::nova::params::network_service_name,
      ensure_package => present,
      before         => Exec['networking-refresh']
    }

    Nova_config <| title == 'DEFAULT/multi_host' |> { value => 'False' }

    cs_resource { 'p_vcenter_nova_network':
      ensure          => present,
      primitive_class => 'ocf',
      provided_by     => 'mirantis',
      primitive_type  => 'nova-network',
      metadata        => {
        'resource-stickiness' => '1'
      },
      parameters      => {
        'amqp_server_port' => $amqp_port,
        'config' => $nova_network_config,
      },
      operations      => {
        'monitor' => {
          'interval' => '20',
          'timeout'  => '30',
        },
        'start'   => {
          'timeout' => '20',
        },
        'stop'    => {
          'timeout' => '20',
        }
      }
    }

    file { 'vcenter-nova-network-ocf':
      path  => '/usr/lib/ocf/resource.d/mirantis/nova-network',
      source => 'puppet:///modules/vmware/ocf/nova-network',
      owner => 'root',
      group => 'root',
      mode => '0755',
    }

    service { 'p_vcenter_nova_network':
      ensure => 'running',
      enable => true,
      provider => 'pacemaker',
    }

    anchor { 'vcenter-nova-network-start': }
    anchor { 'vcenter-nova-network-end': }

    Anchor <| title == 'nailgun::rabbitmq end' |>->
    Anchor['vcenter-nova-network-start']

    Anchor['vcenter-nova-network-start']->
    Nova::Generic_service['network']->
    File['vcenter-nova-network-ocf']->
    Cs_resource['p_vcenter_nova_network']->
    Service['p_vcenter_nova_network']->
    Anchor['vcenter-nova-network-end']
  }

}
