# Fact: wsrep_conf_exists
#
# Purpose: Return true if /etc/mysql/conf.d/wsrep.cnf exists
#
if FileTest.exists?("/etc/mysql/conf.d/wsrep.cnf")
  Facter.add(:wsrep_conf_exists) do
    setcode do
      true
    end
  end
end
