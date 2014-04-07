#    Copyright 2013 Mirantis, Inc.
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


class mcollective::clientpackages
{

  case $::rubyversion {
    '2.1.1': {
      $mcollective_client_package = "ruby21-rubygem-mcollective-client"
      package { 'ruby21-nailgun-mcagents': }
    }
    '1.8.7': {
      $mcollective_client_package = "mcollective-client"
      package { 'nailgun-mcagents': }
    }
  }

  package { $mcollective_client_package :
    ensure => 'present',
  }
}
