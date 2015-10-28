anchor { 'ntp::begin':
  before => 'Class[Ntp::Install]',
  name   => 'ntp::begin',
}

anchor { 'ntp::end':
  name => 'ntp::end',
}

class { 'Cluster::Ntp_ocf':
  name => 'Cluster::Ntp_ocf',
}

class { 'Ntp::Config':
  name   => 'Ntp::Config',
  notify => 'Class[Ntp::Service]',
}

class { 'Ntp::Install':
  before => 'Class[Ntp::Config]',
  name   => 'Ntp::Install',
}

class { 'Ntp::Params':
  name => 'Ntp::Params',
}

class { 'Ntp::Service':
  before => 'Anchor[ntp::end]',
  name   => 'Ntp::Service',
}

class { 'Ntp':
  autoupdate        => 'false',
  broadcastclient   => 'false',
  config            => '/etc/ntp.conf',
  config_template   => 'ntp/ntp.conf.erb',
  disable_auth      => 'false',
  disable_monitor   => 'true',
  driftfile         => '/var/lib/ntp/drift',
  fudge             => [],
  iburst_enable     => 'true',
  interfaces        => [],
  keys_controlkey   => '',
  keys_enable       => 'false',
  keys_file         => '/etc/ntp/keys',
  keys_requestkey   => '',
  keys_trusted      => [],
  minpoll           => '3',
  name              => 'Ntp',
  package_ensure    => 'present',
  package_manage    => 'true',
  package_name      => 'ntp',
  panic             => '0',
  peers             => [],
  preferred_servers => [],
  restrict          => ['-4 default kod nomodify notrap nopeer noquery', '-6 default kod nomodify notrap nopeer noquery', '127.0.0.1', '::1'],
  servers           => '10.109.37.1',
  service_enable    => 'true',
  service_ensure    => 'running',
  service_manage    => 'true',
  service_name      => 'ntp',
  stepout           => '5',
  tinker            => 'true',
  udlc              => 'false',
  udlc_stratum      => '10',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

cs_resource { 'p_ntp':
  ensure          => 'present',
  before          => 'Service[ntp]',
  complex_type    => 'clone',
  metadata        => {'failure-timeout' => '120', 'migration-threshold' => '3'},
  ms_metadata     => {'interleave' => 'true'},
  name            => 'p_ntp',
  operations      => {'monitor' => {'interval' => '20', 'timeout' => '10'}, 'start' => {'timeout' => '30'}, 'stop' => {'timeout' => '30'}},
  parameters      => {'ns' => 'vrouter'},
  primitive_class => 'ocf',
  primitive_type  => 'ns_ntp',
  provided_by     => 'fuel',
}

cs_rsc_colocation { 'ntp-with-vrouter-ns':
  ensure     => 'present',
  before     => 'Service[ntp]',
  name       => 'ntp-with-vrouter-ns',
  primitives => ['clone_p_ntp', 'clone_p_vrouter'],
  score      => 'INFINITY',
}

exec { 'remove_ntp_override':
  before  => ['Service[ntp]', 'Service[ntp]'],
  command => 'rm -f /etc/init/ntp.override',
  onlyif  => 'test -f /etc/init/ntp.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

file { '/etc/ntp.conf':
  ensure  => 'file',
  content => '# ntp.conf: Managed by puppet.
#
# Enable next tinker options:
# panic - keep ntpd from panicking in the event of a large clock skew
# when a VM guest is suspended and resumed;
# stepout - allow ntpd change offset faster
tinker panic 0 stepout 5

disable monitor

# Permit time synchronization with our time source, but do not
# permit the source to query or modify the service on this system.
restrict -4 default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery
restrict 127.0.0.1
restrict ::1



# Set up servers for ntpd with next options:
# server - IP address or DNS name of upstream NTP server
# iburst - allow send sync packages faster if upstream unavailable
# prefer - select preferrable server
# minpoll - set minimal update frequency
# maxpoll - set maximal update frequency
server 10.109.37.1 iburst minpoll 3


# Driftfile.
driftfile /var/lib/ntp/drift




',
  group   => '0',
  mode    => '0644',
  owner   => '0',
  path    => '/etc/ntp.conf',
}

file { 'create_ntp_override':
  ensure  => 'present',
  before  => ['Package[ntp]', 'Exec[remove_ntp_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/ntp.override',
}

file { 'ocf_handler_ntp':
  ensure  => 'present',
  before  => 'Service[ntp]',
  content => '#!/bin/bash
export PATH='/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
export OCF_ROOT='/usr/lib/ocf'
export OCF_RA_VERSION_MAJOR='1'
export OCF_RA_VERSION_MINOR='0'
export OCF_RESOURCE_INSTANCE='p_ntp'

# OCF Parameters
                                    export OCF_RESKEY_ns='vrouter'
    
help() {
cat<<EOF
OCF wrapper for ntp Pacemaker primitive

Usage: ocf_handler_ntp [-dh] (action)

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
  bash -x /usr/lib/ocf/resource.d/fuel/ns_ntp "${ACTION}"
else
  /usr/lib/ocf/resource.d/fuel/ns_ntp "${ACTION}"
fi
ec="${?}"

message="$(ec2error ${ec})"
echo "Exit status: ${message} (${ec})"
exit "${ec}"
',
  group   => 'root',
  mode    => '0700',
  owner   => 'root',
  path    => '/usr/local/bin/ocf_handler_ntp',
}

pacemaker_wrappers::service { 'ntp':
  ensure             => 'present',
  complex_type       => 'clone',
  create_primitive   => 'true',
  handler_root_path  => '/usr/local/bin',
  metadata           => {'failure-timeout' => '120', 'migration-threshold' => '3'},
  ms_metadata        => {'interleave' => 'true'},
  name               => 'ntp',
  ocf_root_path      => '/usr/lib/ocf',
  operations         => {'monitor' => {'interval' => '20', 'timeout' => '10'}, 'start' => {'timeout' => '30'}, 'stop' => {'timeout' => '30'}},
  parameters         => {'ns' => 'vrouter'},
  prefix             => 'true',
  primitive_class    => 'ocf',
  primitive_provider => 'fuel',
  primitive_type     => 'ns_ntp',
  use_handler        => 'true',
}

package { 'ntp':
  ensure => 'present',
  before => 'Exec[remove_ntp_override]',
  name   => 'ntp',
}

service { 'ntp':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'ntp',
  provider   => 'pacemaker',
}

stage { 'main':
  name => 'main',
}

tweaks::ubuntu_service_override { 'ntpd':
  name         => 'ntpd',
  package_name => 'ntp',
  service_name => 'ntp',
}

