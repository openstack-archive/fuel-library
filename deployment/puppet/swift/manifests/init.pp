# Install and configure base swift components
# == Parameters
# [*swift_hash_suffix*] string of text to be used
# as a salt when hashing to determine mappings in the ring.
# This file should be the same on every node in the cluster!
#
# [*swift_ssh_key*] NOT YET IMPLEMENTED
#

class swift(
  $swift_hash_suffix,
#  $swift_ssh_key,
  $package_ensure = 'present'
) {

  # maybe I should just install ssh?
  Class['ssh::server::install'] -> Class['swift']

  package { 'swift':
    ensure => $package_ensure,
  }

  File { owner => 'swift', group => 'swift', require => Package['swift'] }

  file { '/home/swift':
    ensure  => directory,
    mode    => 0700,
  }

  file { '/etc/swift':
    ensure => directory,
    mode   => 2770,
  }

  file { '/var/run/swift':
    ensure => directory,
  }

  file { '/etc/swift/swift.conf':
    ensure  => present,
    mode    => 0660,
    content => template('swift/swift.conf.erb'),
  }

#  if ($swift_ssh_key) {
#    if $swift_ssh_key !~ /^(ssh-...) +([^ ]*) *([^ \n]*)/ {
#      err("Can't parse swift_ssh_key")
#      notify { "Can't parse public key file $name on the keymaster: skipping ensure => $e
#nsure": }
#    } else {
#      $keytype = $1
#      $modulus = $2
#      $comment = $3
#      ssh_authorized_key { $comment:
#        ensure  => "present",
#        user    => "swift",
#        type    => $keytype,
#        key     => $modulus,
#        options => $options ? { "" => undef, default => $options },
#        require => File["/home/swift"]
#      }
#    }
#  }
# does swift need an ssh key?
# they are adding one in the openstack modules

#
# I do not understand how to configure the rings
# or why rings would be configured on the proxy?

}
