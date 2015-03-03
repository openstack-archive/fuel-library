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
# [*password_auth*]
#   Use password authentication. Defaults to no
#

class osnailyfacter::ssh(
  $ciphers = 'aes256-ctr,aes192-ctr,aes128-ctr,arcfour256,arcfour128',
  $macs = 'hmac-sha2-512,hmac-sha2-256,hmac-ripemd160,hmac-sha1',
  $protocol_ver = '2',
  $ports = '22',
  $log_lvl = 'VERBOSE',
  $password_auth = 'no'
){

  case $::osfamily {
    'redhat': {
      $subsystem = 'sftp /usr/libexec/openssh/sftp-server'
    }
    'debian': {
      $subsystem = 'sftp /usr/lib/openssh/sftp-server'
    }
    default: {
      $subsystem = 'sftp /usr/lib/openssh/sftp-server'
    }
  }

  class { 'ssh::server':
    storeconfigs_enabled => false,
    options              => {
      'Protocol'                        => $protocol_ver,
      'Ciphers'                         => $ciphers,
      'MACs'                            => $macs,
      'Port'                            => $ports,
      'LogLevel'                        => $log_lvl,
      'Subsystem'                       => $subsystem,
      'PasswordAuthentication'          => $password_auth,
      'AllowTcpForwarding'              => 'no',
      'X11Forwarding'                   => 'no',
      'UsePAM'                          => 'yes',
      'UseDNS'                          => 'no',
      'GSSAPIAuthentication'            => 'no',
      'ChallengeResponseAuthentication' => 'no'
    }
  }
}
