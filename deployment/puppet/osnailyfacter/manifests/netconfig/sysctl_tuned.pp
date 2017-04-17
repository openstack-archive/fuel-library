#
# Configure kernel parameters at runtime.
# The parameters available are those listed under /proc/sys/.
#
class osnailyfacter::netconfig::sysctl_tuned (
) {

  # delay-aware/state-enabled to keep a pipe at or below a threshold
  sysctl::value { 'net.ipv4.tcp_congestion_control':    value => 'yeah' }
  sysctl::value { 'net.ipv4.tcp_slow_start_after_idle': value => 0 }
  sysctl::value { 'net.ipv4.tcp_fin_timeout':           value => 30 }

  # All nodes with network functions should have net forwarding.
  # Its a requirement for network namespaces to function.
  sysctl::value { 'net.ipv4.ip_forward': value => '1' }

  # All nodes with network functions should have these thresholds
  # to avoid "Neighbour table overflow" problem
  sysctl::value { 'net.ipv4.neigh.default.gc_thresh1': value => '4096' }
  sysctl::value { 'net.ipv4.neigh.default.gc_thresh2': value => '8192' }
  sysctl::value { 'net.ipv4.neigh.default.gc_thresh3': value => '16384' }

}
