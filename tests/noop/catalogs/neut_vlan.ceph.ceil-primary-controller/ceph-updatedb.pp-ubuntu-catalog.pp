class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

exec { 'Ensure /var/lib/ceph in the updatedb PRUNEPATH':
  command => 'sed -i -Ee 's|(PRUNEPATHS *= *"[^"]*)|\1 /var/lib/ceph|' /etc/updatedb.conf',
  path    => ['/usr/bin', '/bin'],
  unless  => 'test ! -f /etc/updatedb.conf || grep 'PRUNEPATHS *= *.*/var/lib/ceph.*' /etc/updatedb.conf',
}

stage { 'main':
  name => 'main',
}

