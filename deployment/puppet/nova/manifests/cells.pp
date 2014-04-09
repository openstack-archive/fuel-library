#
# Copyright (C) 2013 eNovance SAS <licensing@enovance.com>
#
# Author: Emilien Macchi <emilien.macchi@enovance.com>
#         François Charlier <francois.charlier@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# The nova::cells class installs the Nova Cells
#
# == Parameters
#  [*enabled*]
#    Use Nova Cells or not
#    Defaults to 'False'
#
#  [*create_cells*]
#    Create cells with nova-manage
#    Defaults to 'True'
#
#  [*driver*]
#    Cells communication driver to use
#    Defaults to 'nova.cells.rpc_driver.CellsRPCDriver'
#
#  [*instance_updated_at_threshold*]
#    Number of seconds after an instance was updated or deleted to continue to update cells
#    Defaults to '3600'
#
#  [*max_hop_count*]
#    Maximum number of hops for cells routing
#    Defaults to '10'
#
#  [*scheduler*]
#    Cells scheduler to use
#    Defaults to 'nova.cells.scheduler.CellsScheduler'
#
#  [*instance_update_num_instances*]
#    Number of instances to update per periodic task run
#    Defaults to '1'
#
#  [*manager*]
#    Number of instances to update per periodic task run
#    Defaults to 'nova.cells.manager.CellsManager'
#
#  [*cell_name*]
#    name of this cell
#    Defaults to 'nova'
#
#  [*cell_parent_name*]
#    * If a child cell, this is the name of the 'parent' cell.
#    * If a parent cell, should be left to undef.
#
#  [*capabilities*]
#    Key/Multi-value list with the capabilities of the cell
#    Defaults to 'hypervisor=xenserver;kvm,os=linux;windows'
#
#  [*call_timeout*]
#    Seconds to wait for response from a call to a cell
#    Defaults to '60'
#
#  [*reserve_percent*]
#    Percentage of cell capacity to hold in reserve. Affects both memory and disk utilization
#    Defaults to '10.0'
#
#  [*cell_type*]
#    Type of cell: parent or child
#    Defaults to 'None'
#
#  [*mute_child_interval*]
#    Number of seconds after which a lack of capability and
#    capacity updates signals the child cell is to be treated as a mute
#    Defaults to '300'
#
#  [*bandwidth_update_interval*]
#    Seconds between bandwidth updates for cells
#    Defaults to '600'
#
#  [*rpc_driver_queue_base*]
#    Base queue name to use when communicating between cells
#    Various topics by message type will be appended to this
#    Defaults to 'cells.intercell'
#
#  [*scheduler_filter_classes*]
#    Filter classes the cells scheduler should use
#    Defaults to 'nova.cells.filters.all_filters'
#
#  [*scheduler_weight_classes*]
#    Weigher classes the cells scheduler should use
#    Defaults to 'nova.cells.weights.all_weighers'
#
#  [*scheduler_retries*]
#    How many retries when no cells are available
#    Defaults to '10'
#
#  [*scheduler_retry_delay*]
#    How often to retry in seconds when no cells are available
#    Defaults to '2'
#
#  [*db_check_interval*]
#    Seconds between getting fresh cell info from db
#    Defaults to '60'
#
#  [*mute_weight_multiplier*]
#    Multiplier used to weigh mute children (The value should be negative)
#    Defaults to '-10.0'
#
#  [*mute_weight_value*]
#    Weight value assigned to mute children (The value should be positive)
#    Defaults to '1000.0'
#
#  [*ram_weight_multiplier*]
#    Multiplier used for weighing ram. Negative numbers mean to stack vs spread
#    Defaults to '10.0'
#
#  [*weight_offset*]
#    It might be used by some cell scheduling code in the future
#    Defaults to '1.0'
#
#  [*weight_scale*]
#    It might be used by some cell scheduling code in the future
#    Defaults to '1.0'
#

class nova::cells (
  $bandwidth_update_interval     = '600',
  $call_timeout                  = '60',
  $capabilities                  = ['hypervisor=xenserver;kvm','os=linux;windows'],
  $cell_name                     = 'nova',
  $cell_type                     = undef,
  $cell_parent_name              = undef,
  $create_cells                  = true,
  $db_check_interval             = '60',
  $driver                        = 'nova.cells.rpc_driver.CellsRPCDriver',
  $enabled                       = false,
  $ensure_package                = 'present',
  $instance_updated_at_threshold = '3600',
  $instance_update_num_instances = '1',
  $manager                       = 'nova.cells.manager.CellsManager',
  $max_hop_count                 = '10',
  $mute_child_interval           = '300',
  $mute_weight_multiplier        = '-10.0',
  $mute_weight_value             = '1000.0',
  $ram_weight_multiplier         = '10.0',
  $reserve_percent               = '10.0',
  $rpc_driver_queue_base         = 'cells.intercell',
  $scheduler_filter_classes      = 'nova.cells.filters.all_filters',
  $scheduler                     = 'nova.cells.scheduler.CellsScheduler',
  $scheduler_retries             = '10',
  $scheduler_retry_delay         = '2',
  $scheduler_weight_classes      = 'nova.cells.weights.all_weighers',
  $weight_offset                 = '1.0',
  $weight_scale                  = '1.0'
) {

  include nova::params

  case $cell_type {
    'parent': {
      nova_config { 'DEFAULT/compute_api_class': value => 'nova.compute.cells_api.ComputeCellsAPI' }
      nova_config { 'DEFAULT/cell_type': value         => 'api' }
    }
    'child': {
      nova_config { 'DEFAULT/quota_driver': value => 'nova.quota.NoopQuotaDriver' }
      nova_config { 'DEFAULT/cell_type': value    => 'compute' }
    }
    default: { fail("Unsupported cell_type parameter value: '${cell_type}'. Should be 'parent' or 'child'.") }
  }

  nova_config {
    'cells/bandwidth_update_interval':     value => $bandwidth_update_interval;
    'cells/call_timeout':                  value => $call_timeout;
    'cells/capabilities':                  value => join($capabilities, ',');
    'cells/db_check_interval':             value => $db_check_interval;
    'cells/driver':                        value => $driver;
    'cells/enable':                        value => $enabled;
    'cells/instance_updated_at_threshold': value => $instance_updated_at_threshold;
    'cells/instance_update_num_instances': value => $instance_update_num_instances;
    'cells/manager':                       value => $manager;
    'cells/max_hop_count':                 value => $max_hop_count;
    'cells/mute_child_interval':           value => $mute_child_interval;
    'cells/mute_weight_multiplier':        value => $mute_weight_multiplier;
    'cells/mute_weight_value':             value => $mute_weight_value;
    'cells/name':                          value => $cell_name;
    'cells/ram_weight_multiplier':         value => $ram_weight_multiplier;
    'cells/reserve_percent':               value => $reserve_percent;
    'cells/rpc_driver_queue_base':         value => $rpc_driver_queue_base;
    'cells/scheduler_filter_classes':      value => $scheduler_filter_classes;
    'cells/scheduler_retries':             value => $scheduler_retries;
    'cells/scheduler_retry_delay':         value => $scheduler_retry_delay;
    'cells/scheduler':                     value => $scheduler;
    'cells/scheduler_weight_classes':      value => $scheduler_weight_classes;
  }

  nova::generic_service { 'cells':
    enabled        => $enabled,
    package_name   => $::nova::params::cells_package_name,
    service_name   => $::nova::params::cells_service_name,
    ensure_package => $ensure_package,
  }

  if $create_cells {
    @@nova::manage::cells { $cell_name:
      cell_type           => $cell_type,
      cell_parent_name    => $cell_parent_name,
      rabbit_username     => $::nova::init::rabbit_userid,
      rabbit_password     => $::nova::init::rabbit_password,
      rabbit_hosts        => $::nova::init::rabbit_hosts,
      rabbit_port         => $::nova::init::rabbit_port,
      rabbit_virtual_host => $::nova::init::virtual_host,
      weight_offset       => $weight_offset,
      weight_scale        => $weight_scale,
      before              => Service['cells']
    }

    case $cell_type {
      'parent': {
        # A parent cell must declare its child cell(s)
        Nova::Manage::Cells <<| cell_parent_name == $cell_parent_name and cell_type == 'child' |>>
      }
      'child': {
        # A child cell must declare its parent cell
        Nova::Manage::Cells <<| name == $cell_parent_name and cell_type == 'parent' |>>
      }
      default: {
        fail("Invalid cell_type parameter value: ${cell_type}")
      }
    }
  }

}
