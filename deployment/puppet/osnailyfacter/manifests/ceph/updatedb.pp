class osnailyfacter::ceph::updatedb {

  notice('MODULAR: ceph/updatedb.pp')

  $storage_hash = hiera_hash('storage', {})

  if ($storage_hash['volumes_ceph'] or
    $storage_hash['images_ceph'] or
    $storage_hash['objects_ceph']
  ) {
    $use_ceph = true
  } else {
    $use_ceph = false
  }

  if $use_ceph {

    exec {'Ensure /var/lib/ceph in the updatedb PRUNEPATH':
      path    => [ '/usr/bin', '/bin' ],
      command => "sed -i -Ee 's|(PRUNEPATHS *= *\"[^\"]*)|\\1 /var/lib/ceph|' /etc/updatedb.conf",
      unless  => "test ! -f /etc/updatedb.conf || grep 'PRUNEPATHS *= *.*/var/lib/ceph.*' /etc/updatedb.conf",
    }
  }

}
