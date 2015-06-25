define openstack::keystone_domains ($domain_driver) {
  $contents = "[identity]
    driver = ${domain_driver}
    "
  file { "/etc/keystone/domains/keystone.${title}.conf":
    ensure  => 'file',
    content => "$contents",
    require => File["/etc/keystone/domains"],
  }
  file { "/etc/keystone/domains":
    ensure  => 'directory',
  }
}
