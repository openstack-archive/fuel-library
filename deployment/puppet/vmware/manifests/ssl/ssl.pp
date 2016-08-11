#
# Copyright 2016 Mirantis, Inc.
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
# == Class: vmware::ssl::ssl
#
# The VMware driver for cinder-volume, nova-compute, ceilometer, etc establishes
# connections to vCenter over HTTPS, and VMware driver support the vCenter
# server certificate verification as part of the connection process.
# Class configures ssl verification for next cases:
#   1. Bypass vCenter certificate verification. Certificate
#      verification turn off. This case is useful for faster deployment
#      and for testing environment.
#   2. vCenter is using a Self-Signed certificate. In this case the
#      user must upload custom CA bundle file certificate.
#   3. vCenter server certificate was emitted by know CA (e.g. GeoTrust).
#      In this case user have to leave CA certificate bundle upload field empty.
#
# === Parameters
#
# [*vc_insecure*]
#   (optional) If true, the vCenter server certificate is not verified. If
#   false, then the default CA truststore is used for verification. This option
#   is ignored if “ca_file” is set.
#   Defaults to 'True'.
#
# [*vc_ca_file*]
#   (optional) The hash name of the CA bundle file and data in format of:
#   Example:
#   "{"vc_ca_file"=>{"content"=>"RSA", "name"=>"vcenter-ca.pem"}}"
#   Defaults to undef.
#
# [*vc_ca_filepath*]
#   (required) Path CA bundle file to use in verifying the vCenter server
#   certificate.
#   Defaults to $::os_service_default.
#
class vmware::ssl::ssl(
  $vc_insecure    = true,
  $vc_ca_file     = undef,
  $vc_ca_filepath = $::os_service_default,
) {

  $vcenter_ca_file    = pick($vc_ca_file, {})
  $vcenter_ca_content = pick($vcenter_ca_file['content'], {})

  if ! empty($vcenter_ca_content) and ! $vc_insecure {
    if is_service_default($vc_ca_filepath) {
      fail("The vc_ca_filepath parameter is required when vc_insecure is set \
      to false and vcenter_ca_content not empty")
    }
    $vcenter_ca_filepath   = $vc_ca_filepath
    $vcenter_insecure_real = false

    file { $vcenter_ca_filepath:
      ensure  => file,
      content => $vcenter_ca_content,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
    }
  } else {
    $vcenter_ca_filepath   = $::os_service_default
    $vcenter_insecure_real = $vc_insecure
  }
}
