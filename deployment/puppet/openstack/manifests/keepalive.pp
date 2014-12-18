#
# Configure TCP keepalive for host OS and ensure the changes are permanent
# (see https://bugs.launchpad.net/oslo.messaging/+bug/856764/comments/19)
# This means that the keepalive routines wait for <tcpka_time> secs before
# sending the first keepalive probe, and then resend it every <tcpka_intvl>
# seconds. If no ACK response is received for <tcpka_probes> try, the
# connection is marked as broken.
# Note: The defaults are 7200, 75, 9 respectively and provide a *very* poor
# logic for dead connections tracking and failover as well
#
# Examples:
# class { 'openstack::keepalive':
#   stage        => 'netconfig',
#   tcpka_time   => '120',
#   tcpka_intvl  => '20',
#   tcpka_probes => '3',
# }
#
class openstack::keepalive (
  $tcpka_time   = '7200',
  $tcpka_intvl  = '75',
  $tcpka_probes = '9',
  $tcp_retries2 = '15',
) {
  sysctl::value { 'net.ipv4.tcp_keepalive_time':   value => $tcpka_time }
  sysctl::value { 'net.ipv4.tcp_keepalive_intvl':  value => $tcpka_intvl }
  sysctl::value { 'net.ipv4.tcp_keepalive_probes': value => $tcpka_probes }
  sysctl::value { 'net.ipv4.tcp_retries2':         value => $tcp_retries2 }
}
