# create a Ceph pool with an associated Cephx user and ACL

define ceph::pool (
  # Cephx user and ACL
  $user = $name,
  $acl  = "mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=${name}'",

  # Unix user and group for the keyring file
  $keyring_owner = $user,
  $keyring_group = $keyring_owner,

  # Pool settings
  $pg_num  = $::ceph::osd_pool_default_pg_num,
  $pgp_num = $::ceph::osd_pool_default_pgp_num,
) {

  exec {"Create ${name} pool":
    command => "ceph osd pool create ${name} ${pg_num} ${pgp_num}",
    unless  => "rados lspools | grep -q '^${name}$'",
  }

  exec {"Create ${user} Cephx user and ACL":
    command => "ceph auth get-or-create client.${user} ${acl}",
    unless  => "ceph auth list | grep -q '^client.${user}$'"
  }

  $keyring = "/etc/ceph/ceph.client.${user}.keyring"

  exec {"Populate ${user} keyring":
    command => "ceph auth get-or-create client.${user} > ${keyring}",
    creates => $keyring,
  }

  file {$keyring:
    ensure => file,
    mode   => '0640',
    owner  => $keyring_owner,
    group  => $keyring_group,
  }

  Exec["Create ${name} pool"] ->
  Exec["Create ${user} Cephx user and ACL"] ->
  Exec["Populate ${user} keyring"] ->
  File[$keyring]
}
