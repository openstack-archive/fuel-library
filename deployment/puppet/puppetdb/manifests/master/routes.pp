# Class: puppetdb::master::routes
#
# This class configures the puppet master to use puppetdb as the facts terminus.
#
# WARNING: the current implementation simply overwrites your routes.yaml file;
#  if you have an existing routes.yaml file that you are using for other purposes,
#  you should *not* use this.
#
# Parameters:
#   ['puppet_confdir']  - The puppet config directory (defaults to /etc/puppet)
#
# Actions:
# - Configures the puppet master to use puppetdb as a facts terminus by
#   overwriting routes.yaml
#
# Sample Usage:
#   class { 'puppetdb::master::routes':
#       puppet_confdir => '/etc/puppet'
#   }
#
#
# TODO: port this to use params
#
class puppetdb::master::routes(
  $puppet_confdir = '/etc/puppet',
) {

  # TODO: this will overwrite any existing routes.yaml;
  #  to handle this properly we should just be ensuring
  #  that the proper settings exist, but to do that we'd need
  #  to parse the yaml file and rewrite it, dealing with indentation issues etc.
  #  I don't think there is currently a puppet module or an augeas lens for this.
  file { "${puppet_confdir}/routes.yaml":
    ensure => file,
    source => 'puppet:///modules/puppetdb/routes.yaml',
  }
}
