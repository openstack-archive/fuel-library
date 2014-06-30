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
  $amqp_port = '5673'
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
    $p_vcenter_nova_resources_defaults = {
      ensure          => present,
      primitive_class => 'ocf',
      provided_by     => 'mirantis',
      metadata        => { 'resource-stickiness' => '1', },
      parameters      => { 'amqp_server_port' => $amqp_port },
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

    $p_vcenter_nova_resources = {
      'p_vcenter_nova_network' => { primitive_type  => 'nova-network' },
      'p_vcenter_nova_compute' => { primitive_type  => 'nova-compute' },
    }

    create_resources(cs_resource, $p_vcenter_nova_resources, $p_vcenter_nova_resources_defaults)

    cs_colocation { 'p_vcenter_nova_network_with_vip__management_old':
      ensure     => present,
      primitives => [
        'p_vcenter_nova_network',
        'vip__management_old',
      ],
      score      => 'INFINITY',
    }

    cs_colocation { 'p_vcenter_nova_compute_with_p_vcenter_nova_network':
      ensure     => present,
      primitives => [
        'p_vcenter_nova_compute',
        'p_vcenter_nova_network',
      ],
      score      => 'INFINITY',
    }

    cs_order { 'p_vcenter_nova_compute_after_p_vcenter_nova_network':
      ensure => present,
      first  => 'p_vcenter_nova_network',
      second => 'p_vcenter_nova_compute',
      score  => 'INFINITY',
    }

    $vcenter_nova_services_defaults = {
      ensure => 'running',
      enable => 'true',
      provider => 'pacemaker',
    }

    $vcenter_nova_services = {
      'p_vcenter_nova_network' => {},
      'p_vcenter_nova_compute' => {},
    }

    create_resources(service, $vcenter_nova_services, $vcenter_nova_services_defaults)

    $vcenter_nova_ocf_defaults = {
      owner => 'root',
      group => 'root',
      mode => '0755',
    }

    $vcenter_nova_ocf = {
      'vcenter-nova-network-ocf' => {
        path  => '/usr/lib/ocf/resource.d/mirantis/nova-network',
        source => 'puppet:///nova/ocf/nova-network',
      },
      'vcenter-nova-compute-ocf' => {
        path  => '/usr/lib/ocf/resource.d/mirantis/nova-compute',
        source => 'puppet:///nova/ocf/nova-compute',
      },
    }

    create_resources(file, $vcenter_nova_ocf, $vcenter_nova_ocf_defaults)

    # Note that nova-compute is disabled in vmware::controller
    nova::generic_service { 'network':
      enabled => false,
    }

    Nova::Generic_service['network']->
    Nova::Generic_service['compute']->
    File['vcenter-nova-network-ocf']->
    File['vcenter-nova-compute-ocf']->
    Cs_resource['p_vcenter_nova_network']->
    Cs_resource['p_vcenter_nova_compute']->
    Cs_colocation['p_vcenter_nova_network_with_vip__management_old']->
    Cs_colocation['p_vcenter_nova_compute_with_p_vcenter_nova_network']->
    Cs_order['p_vcenter_nova_compute_after_p_vcenter_nova_network']->
    Service['p_vcenter_nova_network']->
    Service['p_vcenter_nova_compute']
  }

}
