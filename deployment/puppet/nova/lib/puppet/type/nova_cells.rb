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
# nova_cells type
#
# == Parameters
#  [*name*]
#    Name for the new cell
#    Optional
#
#  [*cell_type*]
#    Whether the cell is a 'parent' or 'child'
#    Required
#
#  [*rabbit_username*]
#    Username for the message broker in this cell
#    Optional
#
#  [*rabbit_password*]
#    Password for the message broker in this cell
#    Optional
#
#  [*rabbit_hosts*]
#    Address of the message broker in this cell
#    Optional
#
#  [*rabbit_port*]
#    Port number of the message broker in this cell
#    Optional
#
#  [*rabbit_virtual_host*]
#    The virtual host of the message broker in this cell
#    Optional
#
#  [*weight_offset*]
#    It might be used by some cell scheduling code in the future
#    Optional
#
#  [*weight_scale*]
#    It might be used by some cell scheduling code in the future
#    Optional
#

Puppet::Type.newtype(:nova_cells) do

  @doc = "Manage creation/deletion of nova cells."

  ensurable

  newparam(:name) do
    desc "Name for the new cell"
    defaultto "api"
  end

  newparam(:cell_type) do
    desc 'Whether the cell is a parent or child'
  end

  newparam(:rabbit_username) do
    desc 'Username for the message broker in this cell'
    defaultto "guest"
  end

  newparam(:rabbit_password) do
    desc 'Password for the message broker in this cell'
    defaultto "guest"
  end

  newparam(:rabbit_port) do
    desc 'Port number for the message broker in this cell'
    defaultto "5672"
  end

  newparam(:rabbit_hosts) do
    desc 'Address of the message broker in this cell'
    defaultto "localhost"
  end

  newparam(:rabbit_virtual_host) do
    desc 'The virtual host of the message broker in this cell'
    defaultto "/"
  end

  newparam(:weight_offset) do
    desc 'It might be used by some cell scheduling code in the future'
    defaultto "1.0"
  end

  newparam(:weight_scale) do
    desc 'It might be used by some cell scheduling code in the future'
    defaultto "1.0"
  end


  validate do
    raise(Puppet::Error, 'Cell type must be set') unless self[:cell_type]
  end

end
