#
# Copyright (C) 2013 eNovance SAS <licensing@enovance.com>
#
# Author: Emilien Macchi <emilien.macchi@enovance.com>
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
# Deploy Ironic
#

$db_host     = 'db'
$db_username = 'ironic'
$db_name     = 'ironic'
$db_password = 'password'
$rabbit_user     = 'ironic'
$rabbit_password = 'ironic'
$rabbit_vhost    = '/'
$rabbit_hosts    = ['rabbitmq:5672']
$rabbit_port     = '5672'
$glance_api_servers = 'glance:9292'
$deploy_kernel  = 'glance://deploy_kernel_uuid'
$deploy_ramdisk = 'glance://deploy_ramdisk_uuid'

node 'db' {

  class { '::mysql::server':
    config_hash => {
      'bind_address' => '0.0.0.0',
    },
  }

  class { '::mysql::ruby': }

  class { '::ironic::db::mysql':
    password      => $db_password,
    dbname        => $db_name,
    user          => $db_username,
    host          => $clientcert,
    allowed_hosts => ['controller'],
  }

}

node controller {

  class { '::ironic':
    db_password         => $db_password,
    db_name             => $db_name,
    db_user             => $db_username,
    db_host             => $db_host,

    rabbit_password     => $rabbit_password,
    rabbit_userid       => $rabbit_user,
    rabbit_virtual_host => $rabbit_vhost,
    rabbit_hosts        => $rabbit_hosts,

    glance_api_servers  => $glance_api_servers,
  }

  class { '::ironic::api': }

  class { '::ironic::conductor': }

  class { '::ironic::drivers::ipmi': }

  class { '::ironic::drivers::pxe':
    deploy_kernel  => $deploy_kernel,
    deploy_ramdisk => $deploy_ramdisk,
  }

}
