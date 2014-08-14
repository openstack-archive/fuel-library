require 'facter'

# Requires sysstat package on Ubuntu and CentOS
# Fact iops totals tps values from iostat

Facter.add('iops') do
  confine :kernel => :linux
  str = Facter::Util::Resolution.exec("iostat | grep -v 'dm-'" \
                                      " | awk '{print $2}'")
  iops = 0
  str.split("\n").each do |iops_val|
    iops = iops + iops_val.to_f
  end
  setcode { iops }
end
