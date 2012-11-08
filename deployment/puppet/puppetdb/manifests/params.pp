# Class: puppetdb::params
#
#   The puppetdb configuration settings.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class puppetdb::params {
  # TODO: need to condition this based on whether we are a PE install or not

  $ssl_listen_address    = $::clientcert
  $ssl_listen_port       = '8081'

  $database          = 'postgres'

  # The remaining database settings are not used for an embedded database
  $database_host          = 'localhost'
  $database_port          = '5432'
  $database_name          = 'puppetdb'
  $database_username      = 'puppetdb'
  $database_password      = 'puppetdb'

  $puppetdb_version       = 'present'

  # TODO: figure out a way to make this not platform-specific
  $manage_redhat_firewall = true

  $gc_interval            = '60'
  $confdir                = '/etc/puppetdb/conf.d'

  case $::osfamily {
    'RedHat': {
      $firewall_supported       = true
      $persist_firewall_command = '/sbin/iptables-save > /etc/sysconfig/iptables'
    }

    'Debian': {
      $firewall_supported       = false
      # TODO: not exactly sure yet what the right thing to do for Debian/Ubuntu is.
      #$persist_firewall_command = '/sbin/iptables-save > /etc/iptables/rules.v4'
    }
    default: {
      fail("${module_name} supports osfamily's RedHat and Debian. Your osfamily is recognized as ${::osfamily}")
    }
  }

  # TODO: need to condition this for PE
  $puppet_service_name  = 'puppetmaster'
}
