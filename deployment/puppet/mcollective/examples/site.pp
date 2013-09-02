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


$user="mcollective"
$password="AeN5mi5thahz2Aiveexo"
$pskey="un0aez2ei9eiGaequaey4loocohjuch4Ievu3shaeweeg5Uthi"
$host="127.0.0.1"
$stompport="61613"
$mirror_type="external"

stage { 'puppetlabs-repo': before => Stage['main'] }
class { '::openstack::puppetlabs_repos': stage => 'puppetlabs-repo'}
class { '::openstack::mirantis_repos':
  stage => 'puppetlabs-repo',
  type=>$mirror_type,
  disable_puppet_labs_repos => false,
}

node /fuel-mcollective.localdomain/ {

  class { mcollective::rabbitmq:
    user => $user,
    password => $password,
  }

  class { mcollective::client:
    pskey => $pskey,
    user => $user,
    password => $password,
    host => $host,
    stompport => $stompport
  }
  
  class { 'ntp':}

}
