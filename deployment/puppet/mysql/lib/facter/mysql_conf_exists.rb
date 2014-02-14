# Fact: mysql_conf_exists
#
# Purpose: Return true if /etc/mysql/my.cnf exists
#
require 'facter'
Facter.add(:mysql_conf_exists) do
  setcode do
    File.exists?("/etc/mysql/my.cnf") or File.exists?("/etc/my.cnf")
  end
end
