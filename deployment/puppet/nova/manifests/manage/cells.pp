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
#
# Configuring the database in each cell
# == Namevar
#  The namevar will be the name of the cell
#
# == Parameters
#  [*cell_type*]
#    Whether the cell is a 'parent' or 'child'
#    Optional. Default to 'parent'
#
#  [*cell_parent_name*]
#    If a child cell, this is the name of the 'parent' cell.
#    If a parent cell, should be left to undef.
#
#  [*rabbit_username*]
#    Username for the message broker in this cell
#    Optional. Default to 'guest'
#
#  [*rabbit_password*]
#    Password for the message broker in this cell
#    Optional. Default to 'guest'
#
#  [*rabbit_hosts*]
#    Address of the message broker in this cell
#    Optional. Default to 'localhost'
#
#  [*rabbit_port*]
#    Port number of the message broker in this cell
#    Optional. Default to '5672'
#
#  [*rabbit_virtual_host*]
#    The virtual host of the message broker in this cell
#    Optional. Default to '/'
#
#  [*weight_offset*]
#    It might be used by some cell scheduling code in the future
#    Optional. Default to '1.0'
#
#  [*weight_scale*]
#    It might be used by some cell scheduling code in the future
#    Optional. Default to '1.0'

define nova::manage::cells (
  $cell_type           = 'parent',
  $cell_parent_name    = undef,
  $rabbit_username     = 'guest',
  $rabbit_password     = 'guest',
  $rabbit_hosts        = 'localhost',
  $rabbit_port         = '5672',
  $rabbit_virtual_host = '/',
  $weight_offset       = '1.0',
  $weight_scale        = '1.0'
) {

  File['/etc/nova/nova.conf'] -> Nova_cells[$name]
  Exec<| title == 'nova-db-sync' |> -> Nova_cells[$name]

  nova_cells { $name:
    ensure              => present,
    cell_type           => $cell_type,
    cell_parent_name    => $cell_parent_name,
    rabbit_username     => $rabbit_username,
    rabbit_password     => $rabbit_password,
    rabbit_hosts        => $rabbit_hosts,
    rabbit_port         => $rabbit_port,
    rabbit_virtual_host => $rabbit_virtual_host,
    weight_offset       => $weight_offset,
    weight_scale        => $weight_scale
  }

}
