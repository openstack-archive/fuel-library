#
# Configure kernel reserved ephimeral ports
# (see https://bugs.launchpad.net/fuel/+bug/1353363)
#
# Specify the ports which are reserved for known 
# third-party applications. These ports will not 
# be used by automatic port assignments (e.g. when 
# calling connect() or bind() with port number 0).
#
# Examples:
# class { 'openstack::reserved_ports': }
#

class openstack::reserved_ports ( $ports = '49000,35357,41055,58882' ) {
  sysctl::value { 'net.ipv4.ip_local_reserved_ports': value => $ports }
}

