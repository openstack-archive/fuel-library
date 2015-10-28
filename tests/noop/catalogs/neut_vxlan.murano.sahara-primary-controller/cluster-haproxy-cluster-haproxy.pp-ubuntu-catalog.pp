class { 'Cluster::Haproxy':
  debug              => 'false',
  haproxy_bufsize    => '32768',
  haproxy_log_file   => '/var/log/haproxy.log',
  haproxy_maxconn    => '16000',
  haproxy_maxrewrite => '1024',
  name               => 'Cluster::Haproxy',
  other_networks     => '172.16.0.0/24 10.108.0.0/24 192.168.0.0/24 192.168.1.0/24',
  primary_controller => 'true',
  stats_ipaddresses  => ['192.168.0.2', '192.168.0.2', '192.168.0.2', '127.0.0.1'],
}

class { 'Cluster::Haproxy_ocf':
  debug          => 'false',
  name           => 'Cluster::Haproxy_ocf',
  other_networks => '172.16.0.0/24 10.108.0.0/24 192.168.0.0/24 192.168.1.0/24',
}

class { 'Concat::Setup':
  name => 'Concat::Setup',
}

class { 'Haproxy::Base':
  defaults_options  => {'log' => 'global', 'maxconn' => '8000', 'mode' => 'http', 'option' => ['redispatch', 'http-server-close', 'splice-auto'], 'retries' => '3', 'timeout' => ['http-request 20s', 'queue 1m', 'connect 10s', 'client 1m', 'server 1m', 'check 10s']},
  global_options    => {'daemon' => '', 'group' => 'haproxy', 'log' => '/dev/log local0', 'maxconn' => '16000', 'pidfile' => '/var/run/haproxy.pid', 'stats' => 'socket /var/lib/haproxy/stats', 'tune.bufsize' => '32768', 'tune.maxrewrite' => '1024', 'user' => 'haproxy'},
  name              => 'Haproxy::Base',
  notify            => 'Service[haproxy]',
  stats_ipaddresses => ['192.168.0.2', '192.168.0.2', '192.168.0.2', '127.0.0.1'],
  stats_port        => '10000',
  use_include       => 'true',
  use_stats         => 'false',
}

class { 'Haproxy::Params':
  name => 'Haproxy::Params',
}

class { 'Rsyslog::Params':
  name => 'Rsyslog::Params',
}

class { 'Settings':
  name => 'Settings',
}

class { 'Sysctl::Base':
  name => 'Sysctl::Base',
}

class { 'main':
  name => 'main',
}

concat::fragment { 'haproxy-base':
  content => 'global
  daemon  
  group  haproxy
  log  /dev/log local0
  maxconn  16000
  pidfile  /var/run/haproxy.pid
  stats  socket /var/lib/haproxy/stats
  tune.bufsize  32768
  tune.maxrewrite  1024
  user  haproxy

defaults
  log  global
  maxconn  8000
  mode  http
  option  redispatch
  option  http-server-close
  option  splice-auto
  retries  3
  timeout  http-request 20s
  timeout  queue 1m
  timeout  connect 10s
  timeout  client 1m
  timeout  server 1m
  timeout  check 10s
',
  name    => 'haproxy-base',
  order   => '10',
  target  => '/etc/haproxy/haproxy.cfg',
}

concat::fragment { 'haproxy-header':
  content => '# This file managed by Puppet
',
  name    => 'haproxy-header',
  order   => '01',
  target  => '/etc/haproxy/haproxy.cfg',
}

concat::fragment { 'haproxy-include':
  content => '
include conf.d/*.cfg
',
  name    => 'haproxy-include',
  order   => '99',
  target  => '/etc/haproxy/haproxy.cfg',
}

concat { '/etc/haproxy/haproxy.cfg':
  ensure         => 'present',
  backup         => 'puppet',
  before         => 'Service[haproxy]',
  ensure_newline => 'false',
  force          => 'false',
  group          => '0',
  mode           => '0644',
  name           => '/etc/haproxy/haproxy.cfg',
  order          => 'alpha',
  owner          => '0',
  path           => '/etc/haproxy/haproxy.cfg',
  replace        => 'true',
  warn           => 'false',
}

cs_resource { 'p_haproxy':
  ensure          => 'present',
  before          => ['Cs_rsc_colocation[vip_public-with-haproxy]', 'Cs_rsc_colocation[vip_management-with-haproxy]', 'Service[p_haproxy]'],
  complex_type    => 'clone',
  metadata        => {'failure-timeout' => '120', 'migration-threshold' => '3'},
  ms_metadata     => {'interleave' => 'true'},
  name            => 'p_haproxy',
  operations      => {'monitor' => {'interval' => '30', 'timeout' => '60'}, 'start' => {'timeout' => '60'}, 'stop' => {'timeout' => '60'}},
  parameters      => {'debug' => 'false', 'ns' => 'haproxy', 'other_networks' => '172.16.0.0/24 10.108.0.0/24 192.168.0.0/24 192.168.1.0/24'},
  primitive_class => 'ocf',
  primitive_type  => 'ns_haproxy',
  provided_by     => 'fuel',
}

cs_rsc_colocation { 'vip_management-with-haproxy':
  ensure     => 'present',
  before     => 'Service[p_haproxy]',
  name       => 'vip_management-with-haproxy',
  primitives => ['vip__management', 'clone_p_haproxy'],
  score      => 'INFINITY',
}

cs_rsc_colocation { 'vip_public-with-haproxy':
  ensure     => 'present',
  before     => 'Service[p_haproxy]',
  name       => 'vip_public-with-haproxy',
  primitives => ['vip__public', 'clone_p_haproxy'],
  score      => 'INFINITY',
}

exec { 'concat_/etc/haproxy/haproxy.cfg':
  alias     => 'concat_/tmp//_etc_haproxy_haproxy.cfg',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_haproxy.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_haproxy.cfg"',
  notify    => 'File[/etc/haproxy/haproxy.cfg]',
  require   => ['File[/tmp//_etc_haproxy_haproxy.cfg]', 'File[/tmp//_etc_haproxy_haproxy.cfg/fragments]', 'File[/tmp//_etc_haproxy_haproxy.cfg/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_haproxy_haproxy.cfg]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_haproxy_haproxy.cfg/fragments.concat.out" -d "/tmp//_etc_haproxy_haproxy.cfg" -t',
}

exec { 'remove_haproxy_override':
  before  => 'Service[haproxy]',
  command => 'rm -f /etc/init/haproxy.override',
  onlyif  => 'test -f /etc/init/haproxy.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

file { '/etc/haproxy/conf.d':
  ensure => 'directory',
  group  => '0',
  owner  => '0',
  path   => '/etc/haproxy/conf.d',
}

file { '/etc/haproxy/haproxy.cfg':
  ensure  => 'present',
  alias   => 'concat_/etc/haproxy/haproxy.cfg',
  backup  => 'puppet',
  group   => '0',
  mode    => '0644',
  owner   => '0',
  path    => '/etc/haproxy/haproxy.cfg',
  replace => 'true',
  source  => '/tmp//_etc_haproxy_haproxy.cfg/fragments.concat.out',
}

file { '/etc/rsyslog.d/haproxy.conf':
  ensure  => 'present',
  content => '# Create an additional socket in haproxy's chroot in order to allow logging via
# /dev/log to chroot'ed HAProxy processes
$AddUnixListenSocket /var/lib/haproxy/dev/log

# Send HAProxy messages to a dedicated logfile
if $programname startswith 'haproxy' then /var/log/haproxy.log
&~
',
  notify  => 'Service[rsyslog]',
  path    => '/etc/rsyslog.d/haproxy.conf',
}

file { '/etc/sysctl.conf':
  ensure => 'present',
  group  => '0',
  mode   => '0644',
  owner  => 'root',
  path   => '/etc/sysctl.conf',
}

file { '/tmp//_etc_haproxy_haproxy.cfg/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_haproxy.cfg/fragments.concat.out',
}

file { '/tmp//_etc_haproxy_haproxy.cfg/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_haproxy_haproxy.cfg/fragments.concat',
}

file { '/tmp//_etc_haproxy_haproxy.cfg/fragments/01_haproxy-header':
  ensure  => 'file',
  alias   => 'concat_fragment_haproxy-header',
  backup  => 'puppet',
  content => '# This file managed by Puppet
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/haproxy.cfg]',
  path    => '/tmp//_etc_haproxy_haproxy.cfg/fragments/01_haproxy-header',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_haproxy.cfg/fragments/10_haproxy-base':
  ensure  => 'file',
  alias   => 'concat_fragment_haproxy-base',
  backup  => 'puppet',
  content => 'global
  daemon  
  group  haproxy
  log  /dev/log local0
  maxconn  16000
  pidfile  /var/run/haproxy.pid
  stats  socket /var/lib/haproxy/stats
  tune.bufsize  32768
  tune.maxrewrite  1024
  user  haproxy

defaults
  log  global
  maxconn  8000
  mode  http
  option  redispatch
  option  http-server-close
  option  splice-auto
  retries  3
  timeout  http-request 20s
  timeout  queue 1m
  timeout  connect 10s
  timeout  client 1m
  timeout  server 1m
  timeout  check 10s
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/haproxy.cfg]',
  path    => '/tmp//_etc_haproxy_haproxy.cfg/fragments/10_haproxy-base',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_haproxy.cfg/fragments/99_haproxy-include':
  ensure  => 'file',
  alias   => 'concat_fragment_haproxy-include',
  backup  => 'puppet',
  content => '
include conf.d/*.cfg
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/haproxy/haproxy.cfg]',
  path    => '/tmp//_etc_haproxy_haproxy.cfg/fragments/99_haproxy-include',
  replace => 'true',
}

file { '/tmp//_etc_haproxy_haproxy.cfg/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/haproxy/haproxy.cfg]',
  path    => '/tmp//_etc_haproxy_haproxy.cfg/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_haproxy_haproxy.cfg':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_haproxy_haproxy.cfg',
}

file { '/tmp//bin/concatfragments.rb':
  ensure => 'file',
  mode   => '0755',
  path   => '/tmp//bin/concatfragments.rb',
  source => 'puppet:///modules/concat/concatfragments.rb',
}

file { '/tmp//bin':
  ensure => 'directory',
  mode   => '0755',
  path   => '/tmp//bin',
}

file { '/tmp/':
  ensure => 'directory',
  mode   => '0755',
  path   => '/tmp',
}

file { 'create_haproxy_override':
  ensure  => 'present',
  before  => ['Package[haproxy]', 'Package[haproxy]', 'Exec[remove_haproxy_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/haproxy.override',
}

file { 'ocf_handler_p_haproxy':
  ensure  => 'present',
  before  => 'Service[p_haproxy]',
  content => '#!/bin/bash
export PATH='/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
export OCF_ROOT='/usr/lib/ocf'
export OCF_RA_VERSION_MAJOR='1'
export OCF_RA_VERSION_MINOR='0'
export OCF_RESOURCE_INSTANCE='p_haproxy'

# OCF Parameters
                                    export OCF_RESKEY_ns='haproxy'
                                    export OCF_RESKEY_debug='false'
                                    export OCF_RESKEY_other_networks='172.16.0.0/24 10.108.0.0/24 192.168.0.0/24 192.168.1.0/24'
    
help() {
cat<<EOF
OCF wrapper for p_haproxy Pacemaker primitive

Usage: ocf_handler_p_haproxy [-dh] (action)

Options:
-d - Use set -x to debug the shell script
-h - Show this help

Main actions:
* start
* stop
* monitor
* meta-data
* validate-all

Multistate:
* promote
* demote
* notify

Migration:
* migrate_to
* migrate_from

Optional and unused:
* usage
* help
* status
* reload
* restart
* recover
EOF
}

red() {
  echo -e "\033[31m${1}\033[0m"
}

green() {
  echo -e "\033[32m${1}\033[0m"
}

blue() {
  echo -e "\033[34m${1}\033[0m"
}

ec2error() {
  case "${1}" in
    0) green 'Success' ;;
    1) red 'Error: Generic' ;;
    2) red 'Error: Arguments' ;;
    3) red 'Error: Unimplemented' ;;
    4) red 'Error: Permissions' ;;
    5) red 'Error: Installation' ;;
    6) red 'Error: Configuration' ;;
    7) blue 'Not Running' ;;
    8) green 'Master Running' ;;
    9) red 'Master Failed' ;;
    *) red "Unknown" ;;
  esac
}

DEBUG='0'
while getopts ':dh' opt; do
  case $opt in
    d)
      DEBUG='1'
      ;;
    h)
      help
      exit 0
      ;;
    \?)
      echo "Invalid option: -${OPTARG}" >&2
      help
      exit 1
      ;;
  esac
done

shift "$((OPTIND - 1))"

ACTION="${1}"

# set default action to monitor
if [ "${ACTION}" = '' ]; then
  ACTION='monitor'
fi

# alias status to monitor
if [ "${ACTION}" = 'status' ]; then
  ACTION='monitor'
fi

# view defined OCF parameters
if [ "${ACTION}" = 'params' ]; then
  env | grep 'OCF_'
  exit 0
fi

if [ "${DEBUG}" = '1' ]; then
  bash -x /usr/lib/ocf/resource.d/fuel/ns_haproxy "${ACTION}"
else
  /usr/lib/ocf/resource.d/fuel/ns_haproxy "${ACTION}"
fi
ec="${?}"

message="$(ec2error ${ec})"
echo "Exit status: ${message} (${ec})"
exit "${ec}"
',
  group   => 'root',
  mode    => '0700',
  owner   => 'root',
  path    => '/usr/local/bin/ocf_handler_p_haproxy',
}

pacemaker_wrappers::service { 'p_haproxy':
  ensure             => 'present',
  complex_type       => 'clone',
  create_primitive   => 'true',
  handler_root_path  => '/usr/local/bin',
  metadata           => {'failure-timeout' => '120', 'migration-threshold' => '3'},
  ms_metadata        => {'interleave' => 'true'},
  name               => 'p_haproxy',
  ocf_root_path      => '/usr/lib/ocf',
  operations         => {'monitor' => {'interval' => '30', 'timeout' => '60'}, 'start' => {'timeout' => '60'}, 'stop' => {'timeout' => '60'}},
  parameters         => {'debug' => 'false', 'ns' => 'haproxy', 'other_networks' => '172.16.0.0/24 10.108.0.0/24 192.168.0.0/24 192.168.1.0/24'},
  prefix             => 'false',
  primitive_class    => 'ocf',
  primitive_provider => 'fuel',
  primitive_type     => 'ns_haproxy',
  use_handler        => 'true',
}

package { 'haproxy':
  before => ['Class[Haproxy::Base]', 'Exec[remove_haproxy_override]', 'Exec[remove_haproxy_override]'],
  name   => 'haproxy',
  notify => 'Service[haproxy]',
}

service { 'haproxy':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'p_haproxy',
  provider   => 'pacemaker',
}

service { 'rsyslog':
  ensure => 'running',
  enable => 'true',
  name   => 'rsyslog',
}

stage { 'main':
  name => 'main',
}

sysctl::value { 'net.ipv4.ip_nonlocal_bind':
  key     => 'net.ipv4.ip_nonlocal_bind',
  name    => 'net.ipv4.ip_nonlocal_bind',
  notify  => 'Service[haproxy]',
  require => 'Class[Sysctl::Base]',
  value   => '1',
}

sysctl { 'net.ipv4.ip_nonlocal_bind':
  before => 'Sysctl_runtime[net.ipv4.ip_nonlocal_bind]',
  name   => 'net.ipv4.ip_nonlocal_bind',
  val    => '1',
}

sysctl_runtime { 'net.ipv4.ip_nonlocal_bind':
  name => 'net.ipv4.ip_nonlocal_bind',
  val  => '1',
}

tweaks::ubuntu_service_override { 'haproxy':
  name         => 'haproxy',
  package_name => 'haproxy',
  service_name => 'haproxy',
}

