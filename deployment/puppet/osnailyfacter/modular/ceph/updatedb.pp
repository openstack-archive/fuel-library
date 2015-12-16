notice('MODULAR: ceph/updatedb.pp')

$storage_hash = hiera('storage', {})

exec {"Ensure /var/lib/ceph in the updatedb PRUNEPATH":
path    => [ '/usr/bin', '/bin' ],
command => "sed -i -Ee 's|(PRUNEPATHS *= *\"[^\"]*)|\\1 /var/lib/ceph|' /etc/updatedb.conf",
unless  => "test ! -f /etc/updatedb.conf || grep 'PRUNEPATHS *= *.*/var/lib/ceph.*' /etc/updatedb.conf",
}
