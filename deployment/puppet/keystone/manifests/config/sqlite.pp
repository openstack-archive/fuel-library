#
# Manages configuration section for sqlite backend.
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
class keystone::config::sqlite(
  $idle_timeout = 200
) {
  keystone::config { 'sql':
    content => inline_template('
[sql]
connection = sqlite:////var/lib/keystone/keystone.db
idle_timeout = <%= idle_timeout %>
'),
    order => '02',
  }
}
