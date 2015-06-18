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
# == Class: glance::backend::cinder
#
# Setup Glance to backend images into Cinder
#
# === Parameters
#
# [*cinder_catalog_info*]
#   (optional) Info to match when looking for cinder in the service catalog.
#   Format is : separated values of the form:
#   <service_type>:<service_name>:<endpoint_type> (string value)
#   Defaults to 'volume:cinder:publicURL'
#
# [*cinder_endpoint_template*]
#   (optional) Override service catalog lookup with template for cinder endpoint.
#   Should be a valid URL. Example: 'http://localhost:8776/v1/%(project_id)s'
#   Defaults to 'undef'
#
# [*os_region_name*]
#   (optional) The os_region_name parameter is deprecated and has no effect.
#   Use glance::api::os_region_name instead.
#   Defaults to 'undef'
#
# [*cinder_ca_certificates_file*]
#   (optional) Location of ca certicate file to use for cinder client requests.
#   Should be a valid ca certicate file
#   Defaults to undef
#
# [*cinder_http_retries*]
#   (optional) Number of cinderclient retries on failed http calls.
#   Should be a valid integer
#   Defaults to '3'
#
# [*cinder_api_insecure*]
#   (optional) Allow to perform insecure SSL requests to cinder.
#   Should be a valid boolean value
#   Defaults to false
#

class glance::backend::cinder(
  $os_region_name              = undef,
  $cinder_ca_certificates_file = undef,
  $cinder_api_insecure         = false,
  $cinder_catalog_info         = 'volume:cinder:publicURL',
  $cinder_endpoint_template    = undef,
  $cinder_http_retries         = '3'

) {

  if $os_region_name {
    notice('The os_region_name parameter is deprecated and has no effect. Use glance::api::os_region_name instead.')
  }

  glance_api_config {
    'DEFAULT/cinder_api_insecure':         value => $cinder_api_insecure;
    'DEFAULT/cinder_catalog_info':         value => $cinder_catalog_info;
    'DEFAULT/cinder_http_retries':         value => $cinder_http_retries;
    'glance_store/default_store':          value => 'cinder';
  }

  glance_cache_config {
    'DEFAULT/cinder_api_insecure':         value => $cinder_api_insecure;
    'DEFAULT/cinder_catalog_info':         value => $cinder_catalog_info;
    'DEFAULT/cinder_http_retries':         value => $cinder_http_retries;
  }

  if $cinder_endpoint_template {
    glance_api_config { 'DEFAULT/cinder_endpoint_template':   value => $cinder_endpoint_template; }
    glance_cache_config { 'DEFAULT/cinder_endpoint_template': value => $cinder_endpoint_template; }
  } else {
    glance_api_config { 'DEFAULT/cinder_endpoint_template':   ensure => absent; }
    glance_cache_config { 'DEFAULT/cinder_endpoint_template': ensure => absent; }
  }

  if $cinder_ca_certificates_file {
    glance_api_config { 'DEFAULT/cinder_ca_certificates_file':   value => $cinder_ca_certificates_file; }
    glance_cache_config { 'DEFAULT/cinder_ca_certificates_file': value => $cinder_ca_certificates_file; }
  } else {
    glance_api_config { 'DEFAULT/cinder_ca_certificates_file':   ensure => absent; }
    glance_cache_config { 'DEFAULT/cinder_ca_certificates_file': ensure => absent; }
  }

}
