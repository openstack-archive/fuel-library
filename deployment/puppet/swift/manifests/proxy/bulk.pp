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
# Configure Bulk
#
# === Parameters
#
# [*max_containers_per_extraction*]
# The maximum number of containers that can be extracted from an archive.
# Default to 10000.
#
# [*max_failed_extractions*]
# The maximum number of failed extractions allowed when an archive has
# extraction failures.
# Default to 1000.
#
# [*max_deletes_per_request*]
# The maximum number of deletes allowed by each request.
# Default to 10000.
#
# [*yield_frequency*]
# The frequency the server will spit out an ' ' to keep the connection alive
# while its processing the request.
# Default to 60.
#

class swift::proxy::bulk(
  $max_containers_per_extraction = '10000',
  $max_failed_extractions        = '1000',
  $max_deletes_per_request       = '10000',
  $yield_frequency               = '60',
) {
  concat::fragment { 'swift_bulk':
    target  => '/etc/swift/proxy-server.conf',
    content => template('swift/proxy/bulk.conf.erb'),
    order   => '21',
  }
}
