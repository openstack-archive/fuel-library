# Class: puppetdb::master::puppetdb_conf
#
# This class manages the puppetdb.conf file for the puppet master.
#
# Parameters:
#   ['server']          - The dns name or ip of the puppetdb server (defaults to localhost)
#   ['port']            - The port that the puppetdb server is running on (defaults to 8081)
#   ['puppet_confdir']  - The config directory of puppet (defaults to /etc/puppet)
#
# Actions:
# - Configures the required puppetdb settings for the puppet master by managing
#   the puppetdb.conf file.
#
# Requires:
# - Inifile
#
# Sample Usage:
#   class { 'puppetdb::master::puppetdb_conf':
#       server => 'my.puppetdb.server'
#   }
#
#
# TODO: port this to use params
#
class puppetdb::master::puppetdb_conf(
  $server         = 'localhost',
  $port           = '8081',
  $puppet_confdir = '/etc/puppet',
) {

  Ini_setting {
    ensure  => present,
    section => 'main',
    path    => "${puppet_confdir}/puppetdb.conf",
  }

  ini_setting {'puppetdbserver':
    setting => 'server',
    value   => $server,
  }

  ini_setting {'puppetdbport':
    setting => 'port',
    value   => $port,
  }
}
