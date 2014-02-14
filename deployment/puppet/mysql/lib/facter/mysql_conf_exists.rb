# Fact: mysql_conf_exists
#
# Purpose: Return true if /etc/mysql/my.cnf exists
#
if FileTest.exists?("/etc/mysql/my.cnf")
  Facter.add(:mysql_conf_exists) do
    setcode do
      true
    end
  end
end
