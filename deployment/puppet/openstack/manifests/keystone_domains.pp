define openstack::keystone_domains ($domain_driver) {
  $contents = "[identity]\ndriver = ${domain_driver}\n"
  file { "/etc/keystone/domains/keystone.${title}.conf":
    ensure  => 'file',
    content => $contents,
    require => File['/etc/keystone/domains'],
  }
  file {'/etc/keystone/domains':
    ensure  => directory,
  }
}
