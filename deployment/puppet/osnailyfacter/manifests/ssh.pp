# == Class: osnailyfacter::ssh
#
# Configures ssh server
#
# === Parameters
#
# [*ciphers*]
#   Specifies the ciphers allowed for protocol version 2
#
# [*macs*]
#   Specifies the available MAC (message authentication code) algorithms
#
# [*protocol_ver*]
#   SSH protocol version to use. Defaults to 2
#
# [*ports*]
#   Ports for SSH service to listen to. If more than one it shjould be an array
#   Defaults to 22
#
# [*log_lvl*]
#   SSH daemon log level. Defaults to VERBOSE
#

class osnailyfacter::ssh(
  $ciphers = 'aes256-ctr,aes256-cbc,aes192-ctr,aes192-cbc,aes128-ctr,aes128-cbc',
  $macs = 'hmac-sha2-512,hmac-sha2-256,hmac-sha1',
  $protocol_ver = '2',
  $ports = '22',
  $log_lvl = 'VERBOSE'
  ){

  class { 'ssh::server':
    storeconfigs_enabled => false,
    options              => {
      'Protocol'           => $protocol_ver,
      'Ciphers'            => $ciphers,
      'MACs'               => $macs,
      'Port'               => $ports,
      'LogLevel'           => $log_lvl,
      'AllowTcpForwarding' => 'no',
      'X11Forwarding'      => 'no',
      'UsePAM'             => 'yes',
      'UseDNS'             => 'no'
    }
  }
}