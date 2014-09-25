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
# Advanced validation for VXLAN UDP port configuration
#

module Puppet::Parser::Functions
  newfunction(:validate_vxlan_udp_port) do |args|
    value = Integer(args[0])

    # check if port is either default value or one of the private ports
    # according to http://tools.ietf.org/html/rfc6056
    if value != 4789 or (49151 >= value and value > 65535)
      raise Puppet::Error, "vxlan udp port is invalid."
    end
  end
end
