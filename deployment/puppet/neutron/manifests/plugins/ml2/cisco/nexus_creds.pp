#
# Configure the Mech Driver for cisco neutron plugin
# More info available here:
# https://wiki.openstack.org/wiki/Neutron/ML2/MechCiscoNexus
#
#
# neutron::plugins::ml2::cisco::nexus_creds used by
# neutron::plugins::ml2::cisco::nexus
#

define neutron::plugins::ml2::cisco::nexus_creds(
  $username,
  $password,
  $servers,
  $ip_address,
  $ssh_port
) {

  file {'/var/lib/neutron/.ssh':
    ensure  => directory,
    owner   => 'neutron',
    require => Package['neutron-server']
  }

  exec {'nexus_creds':
    unless  => "/bin/cat /var/lib/neutron/.ssh/known_hosts | /bin/grep ${username}",
    command => "/usr/bin/ssh-keyscan -t rsa ${ip_address} >> /var/lib/neutron/.ssh/known_hosts",
    user    => 'neutron',
    require => [Package['neutron-server'], File['/var/lib/neutron/.ssh']]
  }
}
