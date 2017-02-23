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
#
#
#
# This class is intended to serve as
# a way of deploying cobbler server.
#
# [server] IP address that will be used as address of cobbler server.
# It is needed to download kickstart files, call cobbler API and
# so on. Required.
#
# [domain_name] Domain name that will be used as default for
# installed nodes. Required.
# [name_server] DNS ip address to be used by installed nodes
# [next_server] IP address that will be used as PXE tftp server. Required.
#
# [dhcp_start_address] First address of dhcp range
# [dhcp_end_address] Last address of dhcp range
# [dhcp_netmask] Netmask of the network
# [dhcp_gateway] Gateway address for installed nodes
# [dhcp_ipaddress] IP address where to bind dhcp and tftp services
#
# [cobbler_user] Cobbler web interface username
# [cobbler_password] Cobbler web interface password
#
# [pxetimeout] Pxelinux will wail this count of 1/10 seconds before
# use default pxe item. To disable it use 0. Required.

class cobbler(

  $server             = $ipaddress,
  $production         = 'prod',

  $domain_name        = 'local',
  $name_server        = $ipaddress,
  $next_server        = $ipaddress,
  $dns_upstream       = ['8.8.8.8'],
  $dns_domain         = 'domain.tld',
  $dns_search         = 'domain.tld',

  $dhcp_start_address = '10.0.0.201',
  $dhcp_end_address   = '10.0.0.254',
  $dhcp_netmask       = '255.255.255.0',
  $dhcp_gateway       = $ipaddress,
  $dhcp_ipaddress     = '127.0.0.1',

  $cobbler_user       = 'cobbler',
  $cobbler_password   = 'cobbler',

  $pxetimeout         = '0'

  ){

  anchor { 'cobbler-begin': }
  anchor { 'cobbler-end': }

  Anchor<| title == 'cobbler-begin' |> ->
  Class['::cobbler::packages'] ->
  Class['::cobbler::selinux'] ->
  Class['::cobbler::server'] ->
  Anchor<| title == 'cobbler-end' |>

  class { '::cobbler::packages': }
  class { '::cobbler::selinux': }
  class { '::cobbler::iptables': }
  class { '::cobbler::server':
    domain_name    => $domain_name,
    production     => $production,
    dns_upstream   => $dns_upstream,
    dns_domain     => $dns_domain,
    dns_search     => $dns_search,
    dhcp_gateway   => $dhcp_gateway,
    dhcp_ipaddress => $dhcp_ipaddress,
    name_server    => $name_server,
    next_server    => $next_server,
    server         => $server,
    pxetimeout     => $pxetimeout,
  }

  cobbler_digest_user { $cobbler_user:
    password => $cobbler_password,
    require  => Package[$::cobbler::packages::cobbler_package],
    notify   => Service[$::cobbler::server::cobbler_service],
  }

}
