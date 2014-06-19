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
# == Class: cinder::glance
#
# Glance drive Cinder as a block storage backend to store image data.
#
# === Parameters
#
# [*glance_api_servers*]
#   (optional) A list of the glance api servers available to cinder.
#   Should be an array with [hostname|ip]:port
#   Defaults to undef
#
# [*glance_api_version*]
#   (optional) Glance API version.
#   Should be 1 or 2
#   Defaults to 2 (current version)
#
# [*glance_num_retries*]
#   (optional) Number retries when downloading an image from glance.
#   Defaults to 0
#
# [*glance_api_insecure*]
#   (optional) Allow to perform insecure SSL (https) requests to glance.
#   Defaults to false
#
# [*glance_api_ssl_compression*]
#   (optional) Whether to attempt to negotiate SSL layer compression when
#   using SSL (https) requests. Set to False to disable SSL
#   layer compression. In some cases disabling this may improve
#   data throughput, eg when high network bandwidth is available
#   and you are using already compressed image formats such as qcow2.
#   Defaults to false
#
# [*glance_request_timeout*]
#   (optional) http/https timeout value for glance operations.
#   Defaults to undef
#

class cinder::glance (
  $glance_api_servers         = undef,
  $glance_api_version         = '2',
  $glance_num_retries         = '0',
  $glance_api_insecure        = false,
  $glance_api_ssl_compression = false,
  $glance_request_timeout     = undef
) {

  if is_array($glance_api_servers) {
    cinder_config {
      'DEFAULT/glance_api_servers': value => join($glance_api_servers, ',');
    }
  } elsif is_string($glance_api_servers) {
    cinder_config {
      'DEFAULT/glance_api_servers': value => $glance_api_servers;
    }
  }

  cinder_config {
    'DEFAULT/glance_api_version':         value => $glance_api_version;
    'DEFAULT/glance_num_retries':         value => $glance_num_retries;
    'DEFAULT/glance_api_insecure':        value => $glance_api_insecure;
    'DEFAULT/glance_api_ssl_compression': value => $glance_api_ssl_compression;
    'DEFAULT/glance_request_timeout':     value => $glance_request_timeout;
  }

}
