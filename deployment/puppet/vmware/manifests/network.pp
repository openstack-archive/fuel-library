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

# VMWare related network configuration class
# It handles whether we use neutron or nova-network and call for an appropriate class

class vmware::network (

  $use_quantum = false,
  $ha_mode = false

)

{ # begin of class

  if $use_quantum { # for quantum
    class { 'vmware::network::neutron': }
  } else { # for nova network
    class { 'vmware::network::nova':
      ha_mode => $ha_mode
    }
  } # end of network check

} # end of class
