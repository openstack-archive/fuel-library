#
# Copyright (C) 2013 eNovance SAS <licensing@enovance.com>
#
# Author: Emilien Macchi <emilien.macchi@enovance.com>
#         Francois Charlier <francois.charlier@enovance.com>
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
# nova_cells provider
#

Puppet::Type.type(:nova_cells).provide(:nova_manage) do

  desc "Manage nova cells"

  optional_commands :nova_manage => 'nova-manage'

  def self.instances
    begin
      cells_list = nova_manage("cell", "list")
    rescue Exception => e
      if e.message =~ /No cells defined/
        return []
      else
        raise(e)
      end
    end
    cells_list.split("\n")[1..-1].collect do |net|
      if net =~ /^(\S+)\s+(\S+)/
        new(:name => $2 )
      end
    end.compact
  end


  def create
    optional_opts = []
    {
      :name                => '--name',
      :cell_type           => '--cell_type',
      :rabbit_username     => '--username',
      :rabbit_password     => '--password',
      :rabbit_hosts        => '--hostname',
      :rabbit_port         => '--port',
      :rabbit_virtual_host => '--virtual_host',
      :weight_offset       => '--woffset',
      :weight_scale        => '--wscale'

    }.each do |param, opt|
      if resource[param]
        optional_opts.push(opt).push(resource[param])
      end
    end

    nova_manage('cell', 'create',
      optional_opts
    )
  end

  def exists?
    begin
      cells_list = nova_manage("cell", "list")
      return cells_list.split("\n")[1..-1].detect do |n|
        n =~ /^(\S+)\s+(#{resource[:cells].split('/').first})/
      end
    rescue
      return false
    end
  end


  def destroy
    nova_manage("cell", "delete", resource[:name])
  end

end
