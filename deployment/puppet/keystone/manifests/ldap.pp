#
# This class implements a config fragment for
# the ldap specific backend for keystone.
#
# TODO finish implementing this
#
# == Dependencies
# == Examples
# == Authors
#
#   Dan Bode dan@puppetlabs.com
#
# == Copyright
#
# Copyright 2012 Puppetlabs Inc, unless otherwise noted.
#
class keystone::ldap {
  keystone::config { 'ldap':
    order => '01',
  }
}
