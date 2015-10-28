class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

cluster::virtual_ip { 'management':
  key  => 'management',
  name => 'management',
  vip  => {'base_veth' => 'v_management', 'bridge' => 'br-mgmt', 'cidr_netmask' => '24', 'gateway' => 'none', 'gateway_metric' => '0', 'ip' => '10.122.12.2', 'namespace' => 'haproxy', 'ns_veth' => 'b_management'},
}

cluster::virtual_ip { 'public':
  key  => 'public',
  name => 'public',
  vip  => {'base_veth' => 'v_public', 'bridge' => 'br-ex', 'cidr_netmask' => '24', 'gateway' => '10.122.11.1', 'gateway_metric' => '10', 'ip' => '10.122.11.3', 'namespace' => 'haproxy', 'ns_veth' => 'b_public'},
}

cluster::virtual_ip { 'vrouter':
  key  => 'vrouter',
  name => 'vrouter',
  vip  => {'base_veth' => 'v_vrouter', 'bridge' => 'br-mgmt', 'cidr_netmask' => '24', 'gateway' => 'none', 'gateway_metric' => '0', 'ip' => '10.122.12.1', 'namespace' => 'vrouter', 'ns_veth' => 'b_vrouter'},
}

cluster::virtual_ip { 'vrouter_pub':
  key  => 'vrouter_pub',
  name => 'vrouter_pub',
  vip  => {'base_veth' => 'v_vrouter_pub', 'bridge' => 'br-ex', 'cidr_netmask' => '24', 'colocation_before' => 'vrouter', 'gateway' => '10.122.11.1', 'gateway_metric' => '0', 'ip' => '10.122.11.2', 'namespace' => 'vrouter', 'ns_iptables_start_rules' => 'iptables -t nat -A POSTROUTING -o b_vrouter_pub -j MASQUERADE', 'ns_iptables_stop_rules' => 'iptables -t nat -D POSTROUTING -o b_vrouter_pub -j MASQUERADE', 'ns_veth' => 'b_vrouter_pub'},
}

cs_resource { 'vip__management':
  ensure          => 'present',
  before          => 'Service[vip__management]',
  metadata        => {'failure-timeout' => '60', 'migration-threshold' => '3', 'resource-stickiness' => '1'},
  name            => 'vip__management',
  operations      => {'monitor' => {'interval' => '5', 'timeout' => '20'}, 'start' => {'timeout' => '30'}, 'stop' => {'timeout' => '30'}},
  parameters      => {'base_veth' => 'v_management', 'bridge' => 'br-mgmt', 'cidr_netmask' => '24', 'gateway' => 'none', 'gateway_metric' => '0', 'iflabel' => 'ka', 'ip' => '10.122.12.2', 'iptables_comment' => 'undef', 'ns' => 'haproxy', 'ns_iptables_start_rules' => 'undef', 'ns_iptables_stop_rules' => 'undef', 'ns_veth' => 'b_management', 'other_networks' => 'undef'},
  primitive_class => 'ocf',
  primitive_type  => 'ns_IPaddr2',
  provided_by     => 'fuel',
}

cs_resource { 'vip__public':
  ensure          => 'present',
  before          => 'Service[vip__public]',
  metadata        => {'failure-timeout' => '60', 'migration-threshold' => '3', 'resource-stickiness' => '1'},
  name            => 'vip__public',
  operations      => {'monitor' => {'interval' => '5', 'timeout' => '20'}, 'start' => {'timeout' => '30'}, 'stop' => {'timeout' => '30'}},
  parameters      => {'base_veth' => 'v_public', 'bridge' => 'br-ex', 'cidr_netmask' => '24', 'gateway' => '10.122.11.1', 'gateway_metric' => '10', 'iflabel' => 'ka', 'ip' => '10.122.11.3', 'iptables_comment' => 'undef', 'ns' => 'haproxy', 'ns_iptables_start_rules' => 'undef', 'ns_iptables_stop_rules' => 'undef', 'ns_veth' => 'b_public', 'other_networks' => 'undef'},
  primitive_class => 'ocf',
  primitive_type  => 'ns_IPaddr2',
  provided_by     => 'fuel',
}

cs_resource { 'vip__vrouter':
  ensure          => 'present',
  before          => 'Service[vip__vrouter]',
  metadata        => {'failure-timeout' => '60', 'migration-threshold' => '3', 'resource-stickiness' => '1'},
  name            => 'vip__vrouter',
  operations      => {'monitor' => {'interval' => '5', 'timeout' => '20'}, 'start' => {'timeout' => '30'}, 'stop' => {'timeout' => '30'}},
  parameters      => {'base_veth' => 'v_vrouter', 'bridge' => 'br-mgmt', 'cidr_netmask' => '24', 'gateway' => 'none', 'gateway_metric' => '0', 'iflabel' => 'ka', 'ip' => '10.122.12.1', 'iptables_comment' => 'undef', 'ns' => 'vrouter', 'ns_iptables_start_rules' => 'undef', 'ns_iptables_stop_rules' => 'undef', 'ns_veth' => 'b_vrouter', 'other_networks' => 'undef'},
  primitive_class => 'ocf',
  primitive_type  => 'ns_IPaddr2',
  provided_by     => 'fuel',
}

cs_resource { 'vip__vrouter_pub':
  ensure          => 'present',
  before          => ['Cs_resource[vip__vrouter]', 'Service[vip__vrouter_pub]'],
  metadata        => {'failure-timeout' => '60', 'migration-threshold' => '3', 'resource-stickiness' => '1'},
  name            => 'vip__vrouter_pub',
  operations      => {'monitor' => {'interval' => '5', 'timeout' => '20'}, 'start' => {'timeout' => '30'}, 'stop' => {'timeout' => '30'}},
  parameters      => {'base_veth' => 'v_vrouter_pub', 'bridge' => 'br-ex', 'cidr_netmask' => '24', 'gateway' => '10.122.11.1', 'gateway_metric' => '0', 'iflabel' => 'ka', 'ip' => '10.122.11.2', 'iptables_comment' => 'undef', 'ns' => 'vrouter', 'ns_iptables_start_rules' => 'iptables -t nat -A POSTROUTING -o b_vrouter_pub -j MASQUERADE', 'ns_iptables_stop_rules' => 'iptables -t nat -D POSTROUTING -o b_vrouter_pub -j MASQUERADE', 'ns_veth' => 'b_vrouter_pub', 'other_networks' => 'undef'},
  primitive_class => 'ocf',
  primitive_type  => 'ns_IPaddr2',
  provided_by     => 'fuel',
}

cs_rsc_colocation { 'vip__vrouter-with-vip__vrouter_pub':
  ensure     => 'present',
  name       => 'vip__vrouter-with-vip__vrouter_pub',
  primitives => ['vip__vrouter', 'vip__vrouter_pub'],
  score      => 'INFINITY',
}

file { 'ocf_handler_vip__management':
  ensure  => 'present',
  before  => 'Service[vip__management]',
  content => '#!/bin/bash
export PATH='/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
export OCF_ROOT='/usr/lib/ocf'
export OCF_RA_VERSION_MAJOR='1'
export OCF_RA_VERSION_MINOR='0'
export OCF_RESOURCE_INSTANCE='vip__management'

# OCF Parameters
                                    export OCF_RESKEY_bridge='br-mgmt'
                                    export OCF_RESKEY_base_veth='v_management'
                                    export OCF_RESKEY_ns_veth='b_management'
                                    export OCF_RESKEY_ip='10.122.12.2'
                                    export OCF_RESKEY_iflabel='ka'
                                    export OCF_RESKEY_cidr_netmask='24'
                                    export OCF_RESKEY_ns='haproxy'
                                    export OCF_RESKEY_gateway_metric='0'
                                    export OCF_RESKEY_other_networks='undef'
                                    export OCF_RESKEY_iptables_comment='undef'
                                    export OCF_RESKEY_ns_iptables_start_rules='undef'
                                    export OCF_RESKEY_ns_iptables_stop_rules='undef'
                                    export OCF_RESKEY_gateway='none'
    
help() {
cat<<EOF
OCF wrapper for vip__management Pacemaker primitive

Usage: ocf_handler_vip__management [-dh] (action)

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
  bash -x /usr/lib/ocf/resource.d/fuel/ns_IPaddr2 "${ACTION}"
else
  /usr/lib/ocf/resource.d/fuel/ns_IPaddr2 "${ACTION}"
fi
ec="${?}"

message="$(ec2error ${ec})"
echo "Exit status: ${message} (${ec})"
exit "${ec}"
',
  group   => 'root',
  mode    => '0700',
  owner   => 'root',
  path    => '/usr/local/bin/ocf_handler_vip__management',
}

file { 'ocf_handler_vip__public':
  ensure  => 'present',
  before  => 'Service[vip__public]',
  content => '#!/bin/bash
export PATH='/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
export OCF_ROOT='/usr/lib/ocf'
export OCF_RA_VERSION_MAJOR='1'
export OCF_RA_VERSION_MINOR='0'
export OCF_RESOURCE_INSTANCE='vip__public'

# OCF Parameters
                                    export OCF_RESKEY_bridge='br-ex'
                                    export OCF_RESKEY_base_veth='v_public'
                                    export OCF_RESKEY_ns_veth='b_public'
                                    export OCF_RESKEY_ip='10.122.11.3'
                                    export OCF_RESKEY_iflabel='ka'
                                    export OCF_RESKEY_cidr_netmask='24'
                                    export OCF_RESKEY_ns='haproxy'
                                    export OCF_RESKEY_gateway_metric='10'
                                    export OCF_RESKEY_other_networks='undef'
                                    export OCF_RESKEY_iptables_comment='undef'
                                    export OCF_RESKEY_ns_iptables_start_rules='undef'
                                    export OCF_RESKEY_ns_iptables_stop_rules='undef'
                                    export OCF_RESKEY_gateway='10.122.11.1'
    
help() {
cat<<EOF
OCF wrapper for vip__public Pacemaker primitive

Usage: ocf_handler_vip__public [-dh] (action)

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
  bash -x /usr/lib/ocf/resource.d/fuel/ns_IPaddr2 "${ACTION}"
else
  /usr/lib/ocf/resource.d/fuel/ns_IPaddr2 "${ACTION}"
fi
ec="${?}"

message="$(ec2error ${ec})"
echo "Exit status: ${message} (${ec})"
exit "${ec}"
',
  group   => 'root',
  mode    => '0700',
  owner   => 'root',
  path    => '/usr/local/bin/ocf_handler_vip__public',
}

file { 'ocf_handler_vip__vrouter':
  ensure  => 'present',
  before  => 'Service[vip__vrouter]',
  content => '#!/bin/bash
export PATH='/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
export OCF_ROOT='/usr/lib/ocf'
export OCF_RA_VERSION_MAJOR='1'
export OCF_RA_VERSION_MINOR='0'
export OCF_RESOURCE_INSTANCE='vip__vrouter'

# OCF Parameters
                                    export OCF_RESKEY_bridge='br-mgmt'
                                    export OCF_RESKEY_base_veth='v_vrouter'
                                    export OCF_RESKEY_ns_veth='b_vrouter'
                                    export OCF_RESKEY_ip='10.122.12.1'
                                    export OCF_RESKEY_iflabel='ka'
                                    export OCF_RESKEY_cidr_netmask='24'
                                    export OCF_RESKEY_ns='vrouter'
                                    export OCF_RESKEY_gateway_metric='0'
                                    export OCF_RESKEY_other_networks='undef'
                                    export OCF_RESKEY_iptables_comment='undef'
                                    export OCF_RESKEY_ns_iptables_start_rules='undef'
                                    export OCF_RESKEY_ns_iptables_stop_rules='undef'
                                    export OCF_RESKEY_gateway='none'
    
help() {
cat<<EOF
OCF wrapper for vip__vrouter Pacemaker primitive

Usage: ocf_handler_vip__vrouter [-dh] (action)

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
  bash -x /usr/lib/ocf/resource.d/fuel/ns_IPaddr2 "${ACTION}"
else
  /usr/lib/ocf/resource.d/fuel/ns_IPaddr2 "${ACTION}"
fi
ec="${?}"

message="$(ec2error ${ec})"
echo "Exit status: ${message} (${ec})"
exit "${ec}"
',
  group   => 'root',
  mode    => '0700',
  owner   => 'root',
  path    => '/usr/local/bin/ocf_handler_vip__vrouter',
}

file { 'ocf_handler_vip__vrouter_pub':
  ensure  => 'present',
  before  => 'Service[vip__vrouter_pub]',
  content => '#!/bin/bash
export PATH='/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
export OCF_ROOT='/usr/lib/ocf'
export OCF_RA_VERSION_MAJOR='1'
export OCF_RA_VERSION_MINOR='0'
export OCF_RESOURCE_INSTANCE='vip__vrouter_pub'

# OCF Parameters
                                    export OCF_RESKEY_bridge='br-ex'
                                    export OCF_RESKEY_base_veth='v_vrouter_pub'
                                    export OCF_RESKEY_ns_veth='b_vrouter_pub'
                                    export OCF_RESKEY_ip='10.122.11.2'
                                    export OCF_RESKEY_iflabel='ka'
                                    export OCF_RESKEY_cidr_netmask='24'
                                    export OCF_RESKEY_ns='vrouter'
                                    export OCF_RESKEY_gateway_metric='0'
                                    export OCF_RESKEY_other_networks='undef'
                                    export OCF_RESKEY_iptables_comment='undef'
                                    export OCF_RESKEY_ns_iptables_start_rules='iptables -t nat -A POSTROUTING -o b_vrouter_pub -j MASQUERADE'
                                    export OCF_RESKEY_ns_iptables_stop_rules='iptables -t nat -D POSTROUTING -o b_vrouter_pub -j MASQUERADE'
                                    export OCF_RESKEY_gateway='10.122.11.1'
    
help() {
cat<<EOF
OCF wrapper for vip__vrouter_pub Pacemaker primitive

Usage: ocf_handler_vip__vrouter_pub [-dh] (action)

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
  bash -x /usr/lib/ocf/resource.d/fuel/ns_IPaddr2 "${ACTION}"
else
  /usr/lib/ocf/resource.d/fuel/ns_IPaddr2 "${ACTION}"
fi
ec="${?}"

message="$(ec2error ${ec})"
echo "Exit status: ${message} (${ec})"
exit "${ec}"
',
  group   => 'root',
  mode    => '0700',
  owner   => 'root',
  path    => '/usr/local/bin/ocf_handler_vip__vrouter_pub',
}

pacemaker_wrappers::service { 'vip__management':
  ensure             => 'present',
  create_primitive   => 'true',
  handler_root_path  => '/usr/local/bin',
  metadata           => {'failure-timeout' => '60', 'migration-threshold' => '3', 'resource-stickiness' => '1'},
  name               => 'vip__management',
  ocf_root_path      => '/usr/lib/ocf',
  operations         => {'monitor' => {'interval' => '5', 'timeout' => '20'}, 'start' => {'timeout' => '30'}, 'stop' => {'timeout' => '30'}},
  parameters         => {'base_veth' => 'v_management', 'bridge' => 'br-mgmt', 'cidr_netmask' => '24', 'gateway' => 'none', 'gateway_metric' => '0', 'iflabel' => 'ka', 'ip' => '10.122.12.2', 'iptables_comment' => 'undef', 'ns' => 'haproxy', 'ns_iptables_start_rules' => 'undef', 'ns_iptables_stop_rules' => 'undef', 'ns_veth' => 'b_management', 'other_networks' => 'undef'},
  prefix             => 'false',
  primitive_class    => 'ocf',
  primitive_provider => 'fuel',
  primitive_type     => 'ns_IPaddr2',
  use_handler        => 'true',
}

pacemaker_wrappers::service { 'vip__public':
  ensure             => 'present',
  create_primitive   => 'true',
  handler_root_path  => '/usr/local/bin',
  metadata           => {'failure-timeout' => '60', 'migration-threshold' => '3', 'resource-stickiness' => '1'},
  name               => 'vip__public',
  ocf_root_path      => '/usr/lib/ocf',
  operations         => {'monitor' => {'interval' => '5', 'timeout' => '20'}, 'start' => {'timeout' => '30'}, 'stop' => {'timeout' => '30'}},
  parameters         => {'base_veth' => 'v_public', 'bridge' => 'br-ex', 'cidr_netmask' => '24', 'gateway' => '10.122.11.1', 'gateway_metric' => '10', 'iflabel' => 'ka', 'ip' => '10.122.11.3', 'iptables_comment' => 'undef', 'ns' => 'haproxy', 'ns_iptables_start_rules' => 'undef', 'ns_iptables_stop_rules' => 'undef', 'ns_veth' => 'b_public', 'other_networks' => 'undef'},
  prefix             => 'false',
  primitive_class    => 'ocf',
  primitive_provider => 'fuel',
  primitive_type     => 'ns_IPaddr2',
  use_handler        => 'true',
}

pacemaker_wrappers::service { 'vip__vrouter':
  ensure             => 'present',
  create_primitive   => 'true',
  handler_root_path  => '/usr/local/bin',
  metadata           => {'failure-timeout' => '60', 'migration-threshold' => '3', 'resource-stickiness' => '1'},
  name               => 'vip__vrouter',
  ocf_root_path      => '/usr/lib/ocf',
  operations         => {'monitor' => {'interval' => '5', 'timeout' => '20'}, 'start' => {'timeout' => '30'}, 'stop' => {'timeout' => '30'}},
  parameters         => {'base_veth' => 'v_vrouter', 'bridge' => 'br-mgmt', 'cidr_netmask' => '24', 'gateway' => 'none', 'gateway_metric' => '0', 'iflabel' => 'ka', 'ip' => '10.122.12.1', 'iptables_comment' => 'undef', 'ns' => 'vrouter', 'ns_iptables_start_rules' => 'undef', 'ns_iptables_stop_rules' => 'undef', 'ns_veth' => 'b_vrouter', 'other_networks' => 'undef'},
  prefix             => 'false',
  primitive_class    => 'ocf',
  primitive_provider => 'fuel',
  primitive_type     => 'ns_IPaddr2',
  use_handler        => 'true',
}

pacemaker_wrappers::service { 'vip__vrouter_pub':
  ensure             => 'present',
  create_primitive   => 'true',
  handler_root_path  => '/usr/local/bin',
  metadata           => {'failure-timeout' => '60', 'migration-threshold' => '3', 'resource-stickiness' => '1'},
  name               => 'vip__vrouter_pub',
  ocf_root_path      => '/usr/lib/ocf',
  operations         => {'monitor' => {'interval' => '5', 'timeout' => '20'}, 'start' => {'timeout' => '30'}, 'stop' => {'timeout' => '30'}},
  parameters         => {'base_veth' => 'v_vrouter_pub', 'bridge' => 'br-ex', 'cidr_netmask' => '24', 'gateway' => '10.122.11.1', 'gateway_metric' => '0', 'iflabel' => 'ka', 'ip' => '10.122.11.2', 'iptables_comment' => 'undef', 'ns' => 'vrouter', 'ns_iptables_start_rules' => 'iptables -t nat -A POSTROUTING -o b_vrouter_pub -j MASQUERADE', 'ns_iptables_stop_rules' => 'iptables -t nat -D POSTROUTING -o b_vrouter_pub -j MASQUERADE', 'ns_veth' => 'b_vrouter_pub', 'other_networks' => 'undef'},
  prefix             => 'false',
  primitive_class    => 'ocf',
  primitive_provider => 'fuel',
  primitive_type     => 'ns_IPaddr2',
  use_handler        => 'true',
}

service { 'vip__management':
  ensure   => 'running',
  enable   => 'true',
  name     => 'vip__management',
  provider => 'pacemaker',
}

service { 'vip__public':
  ensure   => 'running',
  enable   => 'true',
  name     => 'vip__public',
  provider => 'pacemaker',
}

service { 'vip__vrouter':
  ensure   => 'running',
  before   => 'Cs_rsc_colocation[vip__vrouter-with-vip__vrouter_pub]',
  enable   => 'true',
  name     => 'vip__vrouter',
  provider => 'pacemaker',
}

service { 'vip__vrouter_pub':
  ensure   => 'running',
  before   => ['Service[vip__vrouter]', 'Cs_rsc_colocation[vip__vrouter-with-vip__vrouter_pub]'],
  enable   => 'true',
  name     => 'vip__vrouter_pub',
  provider => 'pacemaker',
}

stage { 'main':
  name => 'main',
}

