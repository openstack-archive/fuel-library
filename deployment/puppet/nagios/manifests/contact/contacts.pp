define nagios::contact::contacts (
$alias = false,
$email = false,
$group = false,
) {

  $t_email = $email ? {
    false   => 'root@localhost',
    default => $email,
  }

  nagios_contact { $name:
    ensure        => present,
    alias         => $alias,
    email         => $t_email,
    contactgroups => $group,
    use           => 'generic-contact',
    target        => "/etc/${nagios::params::masterdir}/${nagios::master::master_proj_name}/contacts.cfg",
  }
}
