#
# Copyright (C) 2013 eNovance SAS <licensing@enovance.com>
#
# Author: Emilien Macchi <emilien.macchi@enovance.com>
#         Martin Magr <mmagr@redhat.com>
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
# Advanced validation when using GRE
#

module Puppet::Parser::Functions
  newfunction(:validate_tunnel_id_ranges) do |args|
    value = args[0]
    if not value.kind_of?(Array)
      value = [value]
    end

    value.each do |range|
      if m = /^(\d+):(\d+)$/.match(range)
        first_id = Integer(m[1])
        second_id = Integer(m[2])
        if ((second_id - first_id) > 1000000)
          raise Puppet::Error, "tunnel id ranges are to large."
        end
        if ((second_id - first_id) < 0 )
          raise Puppet::Error, "tunnel id ranges are invalid."
        end
      elsif range
        raise Puppet::Error, "tunnel id ranges are invalid."
      end
    end
  end
end
