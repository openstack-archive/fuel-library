# Fact: mysql_log_file_size_real
#
# Purpose: Return size (M) of ib_logfile0, if exists
#
require 'facter'
Facter.add(:mysql_log_file_size_real) do
  setcode do
    f = '/var/lib/mysql/ib_logfile0'
    if File.exists?(f)
      (File.size(f).to_f / 1048576).round.to_s + 'M' rescue '0'
    else
      '0'
    end
  end
end
