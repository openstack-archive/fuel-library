class { 'Cluster::Vrouter_ocf':
  name           => 'Cluster::Vrouter_ocf',
  other_networks => '10.108.0.0/24 10.108.4.0/24 10.108.2.0/24 10.108.1.0/24',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

cs_resource { 'p_vrouter':
  ensure          => 'present',
  before          => 'Service[p_vrouter]',
  complex_type    => 'clone',
  metadata        => {'failure-timeout' => '120', 'migration-threshold' => '3'},
  ms_metadata     => {'interleave' => 'true'},
  name            => 'p_vrouter',
  operations      => {'monitor' => {'interval' => '30', 'timeout' => '60'}, 'start' => {'timeout' => '30'}, 'stop' => {'timeout' => '60'}},
  parameters      => {'ns' => 'vrouter', 'other_networks' => '10.108.0.0/24 10.108.4.0/24 10.108.2.0/24 10.108.1.0/24'},
  primitive_class => 'ocf',
  primitive_type  => 'ns_vrouter',
  provided_by     => 'fuel',
}

file { 'ocf_handler_p_vrouter':
  ensure  => 'present',
  before  => 'Service[p_vrouter]',
  content => '#!/bin/bash
export PATH='/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
export OCF_ROOT='/usr/lib/ocf'
export OCF_RA_VERSION_MAJOR='1'
export OCF_RA_VERSION_MINOR='0'
export OCF_RESOURCE_INSTANCE='p_vrouter'

# OCF Parameters
                                    export OCF_RESKEY_ns='vrouter'
                                    export OCF_RESKEY_other_networks='10.108.0.0/24 10.108.4.0/24 10.108.2.0/24 10.108.1.0/24'
    
help() {
cat<<EOF
OCF wrapper for p_vrouter Pacemaker primitive

Usage: ocf_handler_p_vrouter [-dh] (action)

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
  bash -x /usr/lib/ocf/resource.d/fuel/ns_vrouter "${ACTION}"
else
  /usr/lib/ocf/resource.d/fuel/ns_vrouter "${ACTION}"
fi
ec="${?}"

message="$(ec2error ${ec})"
echo "Exit status: ${message} (${ec})"
exit "${ec}"
',
  group   => 'root',
  mode    => '0700',
  owner   => 'root',
  path    => '/usr/local/bin/ocf_handler_p_vrouter',
}

pacemaker_wrappers::service { 'p_vrouter':
  ensure             => 'present',
  complex_type       => 'clone',
  create_primitive   => 'true',
  handler_root_path  => '/usr/local/bin',
  metadata           => {'failure-timeout' => '120', 'migration-threshold' => '3'},
  ms_metadata        => {'interleave' => 'true'},
  name               => 'p_vrouter',
  ocf_root_path      => '/usr/lib/ocf',
  operations         => {'monitor' => {'interval' => '30', 'timeout' => '60'}, 'start' => {'timeout' => '30'}, 'stop' => {'timeout' => '60'}},
  parameters         => {'ns' => 'vrouter', 'other_networks' => '10.108.0.0/24 10.108.4.0/24 10.108.2.0/24 10.108.1.0/24'},
  prefix             => 'false',
  primitive_class    => 'ocf',
  primitive_provider => 'fuel',
  primitive_type     => 'ns_vrouter',
  use_handler        => 'true',
}

service { 'p_vrouter':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'p_vrouter',
  provider   => 'pacemaker',
}

stage { 'main':
  name => 'main',
}

