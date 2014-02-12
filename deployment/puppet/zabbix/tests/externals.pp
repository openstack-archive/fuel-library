# == Node: default
#
# node for testing zabbix::externals
#
# === Example Usage
#
#   rake spec_prep
#   puppet apply --noop --modulepath spec/fixtures/modules/ \
#   tests/externals.pp --trace
#
node default {
  class { 'zabbix::externals':
    ensure => 'present',
    api    => 'present'
  }
}
