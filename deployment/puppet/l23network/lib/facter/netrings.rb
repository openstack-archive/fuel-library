# Fact: netrings
#
# Purpose:
#   Try to get Facts about the machine's network rings
#

require 'facter/util/ip'

SETTINGS = {
  'maximums' => 'Pre-set maximums',
  'current'  => 'Current hardware settings',
}

rings = Hash.new { |_h, _k| _h[_k] = {} }
mutex = Mutex.new

Facter::Util::IP.get_interfaces.each do |interface|
  Thread.new do
    rings_entries = Facter::Util::Resolution.exec("ethtool -g #{interface} 2>/dev/null")
    Thread.exit unless rings_entries.include? SETTINGS['maximums']

    rings_entries.scan(/(#{SETTINGS['current']}|#{SETTINGS['maximums']}):.*?(RX):\s*(\d+).*?(TX):\s*(\d+)/m).each do |settings|
      header = settings.shift
      mutex.synchronize do
        rings[interface].merge!({SETTINGS.key(header) => Hash[*settings]})
      end
    end
  end
end

Facter.add(:netrings) do
  confine :kernel => 'Linux'
  setcode do
    rings
  end
end

