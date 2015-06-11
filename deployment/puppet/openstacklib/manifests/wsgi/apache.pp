#
# Copyright (C) 2014 eNovance SAS <licensing@enovance.com>
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
# == Class: openstacklib::wsgi::apache
#
# Serve a service with apache mod_wsgi
# When using this class you should disable your service.
#
# == Parameters
#
# [*service_name*]
#   (optional) Name of the service to run.
#   Example: nova-api
#   Defaults to $name
#
# [*servername*]
#   (optional) The servername for the virtualhost.
#   Defaults to $::fqdn
#
# [*bind_host*]
#   (optional) The host/ip address Apache will listen on.
#   Defaults to undef (listen on all ip addresses).
#
# [*bind_port*]
#   (optional) The port to listen.
#   Defaults to undef
#
# [*group*]
#   (optional) Group with permissions on the script
#   Defaults to undef
#
# [*path*]
#   (optional) The prefix for the endpoint.
#   Defaults to '/'
#
# [*priority*]
#   (optional) The priority for the vhost.
#   Defaults to '10'
#
# [*ssl*]
#   (optional) Use ssl ? (boolean)
#   Defaults to false
#
# [*ssl_cert*]
#   (optional) Path to SSL certificate
#   Default to apache::vhost 'ssl_*' defaults.
#
# [*ssl_key*]
#   (optional) Path to SSL key
#   Default to apache::vhost 'ssl_*' defaults.
#
# [*ssl_chain*]
#   (optional) SSL chain
#   Default to apache::vhost 'ssl_*' defaults.
#
# [*ssl_ca*]
#   (optional) Path to SSL certificate authority
#   Default to apache::vhost 'ssl_*' defaults.
#
# [*ssl_crl_path*]
#   (optional) Path to SSL certificate revocation list
#   Default to apache::vhost 'ssl_*' defaults.
#
# [*ssl_crl*]
#   (optional) SSL certificate revocation list name
#   Default to apache::vhost 'ssl_*' defaults.
#
# [*ssl_certs_dir*]
#   (optional) Path to SSL certificate directory
#   Default to apache::vhost 'ssl_*' defaults.
#
# [*threads*]
#   (optional) The number of threads for the vhost.
#   Defaults to $::processorcount
#
# [*user*]
#   (optional) User with permissions on the script
#   Defaults to undef
#
# [*workers*]
#   (optional) The number of workers for the vhost.
#   Defaults to '1'
#
# [*wsgi_daemon_process*]
#   (optional) Name of the WSGI daemon process.
#   Defaults to $name
#
# [*wsgi_process_group*]
#   (optional) Name of the WSGI process group.
#   Defaults to $name
#
# [*wsgi_script_dir*]
#   (optional) The directory path of the WSGI script.
#   Defaults to undef
#
# [*wsgi_script_file*]
#   (optional) The file path of the WSGI script.
#   Defaults to undef
#
# [*wsgi_script_source*]
#   (optional) The source of the WSGI script.
#   Defaults to undef
#
define openstacklib::wsgi::apache (
  $service_name        = $name,
  $bind_host           = undef,
  $bind_port           = undef,
  $group               = undef,
  $path                = '/',
  $priority            = '10',
  $servername          = $::fqdn,
  $ssl                 = false,
  $ssl_ca              = undef,
  $ssl_cert            = undef,
  $ssl_certs_dir       = undef,
  $ssl_chain           = undef,
  $ssl_crl             = undef,
  $ssl_crl_path        = undef,
  $ssl_key             = undef,
  $threads             = $::processorcount,
  $user                = undef,
  $workers             = 1,
  $wsgi_daemon_process = $name,
  $wsgi_process_group  = $name,
  $wsgi_script_dir     = undef,
  $wsgi_script_file    = undef,
  $wsgi_script_source  = undef,
) {

  include ::apache
  include ::apache::mod::wsgi
  if $ssl {
    include ::apache::mod::ssl
  }

  # Ensure there's no trailing '/' except if this is also the only character
  $path_real = regsubst($path, '(^/.*)/$', '\1')

  if !defined(File[$wsgi_script_dir]) {
    file { $wsgi_script_dir:
      ensure  => directory,
      owner   => $user,
      group   => $group,
      require => Package['httpd'],
    }
  }

  file { $service_name:
    ensure  => file,
    path    => "${wsgi_script_dir}/${wsgi_script_file}",
    source  => $wsgi_script_source,
    owner   => $user,
    group   => $group,
    mode    => '0644',
    require => File[$wsgi_script_dir],
  }

  $wsgi_daemon_process_options = {
    user      => $user,
    group     => $group,
    processes => $workers,
    threads   => $threads,
  }
  $wsgi_script_aliases = hash([$path_real,"${wsgi_script_dir}/${wsgi_script_file}"])

  ::apache::vhost { $service_name:
    ensure                      => 'present',
    servername                  => $servername,
    ip                          => $bind_host,
    port                        => $bind_port,
    docroot                     => $wsgi_script_dir,
    docroot_owner               => $user,
    docroot_group               => $group,
    priority                    => $priority,
    ssl                         => $ssl,
    ssl_cert                    => $ssl_cert,
    ssl_key                     => $ssl_key,
    ssl_chain                   => $ssl_chain,
    ssl_ca                      => $ssl_ca,
    ssl_crl_path                => $ssl_crl_path,
    ssl_crl                     => $ssl_crl,
    ssl_certs_dir               => $ssl_certs_dir,
    wsgi_daemon_process         => $wsgi_daemon_process,
    wsgi_daemon_process_options => $wsgi_daemon_process_options,
    wsgi_process_group          => $wsgi_process_group,
    wsgi_script_aliases         => $wsgi_script_aliases,
    require                     => File[$service_name],
  }

}
