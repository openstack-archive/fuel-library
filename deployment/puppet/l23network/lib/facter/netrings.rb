# Fact: netrings
#
# Purpose:
#   Try to get Facts about the machine's network rings
#

require 'facter/util/ip'

class NetRings
  def initialize
    @SETTINGS = {
      'maximums' => 'Pre-set maximums',
      'current'  => 'Current hardware settings',
    }
    @rings = Hash.new { |_h, _k| _h[_k] = {} }
    @mutex = Mutex.new
    @working_threads = []

    interfaces.each do |interface|
      @working_threads << Thread.new do
        @rings_entries = Facter::Util::Resolution.exec("ethtool -g #{interface} 2>/dev/null")
        Thread.exit unless @rings_entries.include? @SETTINGS['maximums']
        @rings_entries.scan(/(#{@SETTINGS['current']}|#{@SETTINGS['maximums']}):.*?(RX):\s*(\d+).*?(TX):\s*(\d+)/m).each do |settings|
          header = settings.shift
          @mutex.synchronize do
            @rings[interface].merge!({@SETTINGS.key(header) => Hash[*settings]})
          end
        end
      end
    end
  end

  def interfaces
    @interfaces ||= Facter::Util::IP.get_interfaces
  end

  def rings
    @working_threads.each do |t|
      # emulate .waitall()
      t.join()
    end
    @rings
  end

end

Facter.add(:netrings) do
  confine :kernel => 'Linux'

  setcode do
    NetRings.new().rings
  end
end

