# By default keystone supports only one default domain, this is not enough when
# readonly ldap is used. Service like heat uses temporary users for internal
# needs. In this case we have to use temporary writable storage - mysql.  This
# will add support for multi domain when LDAP is used.

define openstack::keystone_domains ($domain_driver) {
  $contents = "[identity]\ndriver = ${domain_driver}\n"

  if !defined(File['etc/keystone/domains']) {
    file {'/etc/keystone/domains':
      ensure => directory,
    }
  }

  file { "/etc/keystone/domains/keystone.${title}.conf":
    ensure  => file,
    content => $contents
  }

}
