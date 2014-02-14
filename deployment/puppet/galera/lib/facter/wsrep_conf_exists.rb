# Fact: wsrep_conf_exists
#
# Purpose: Return true if /etc/mysql/conf.d/wsrep.cnf exists
#
require 'facter'
Facter.add(:wsrep_conf_exists) do
  setcode do
    File.exists?("/etc/mysql/conf.d/wsrep.cnf")
  end
end
