# Fact to get a HW uuid info from dmidecode.
# Return empty uuid if not found.

require 'facter/util/resolution'

Facter.add(:uuid_dmi) do
  setcode do
    r = nil
    cmd = 'dmidecode'
    out = Facter::Util::Resolution.exec("#{cmd} 2>&1")
    out.each_line do |line|
      r = line.scan(%r{\S+}) if line =~ %r{^\s*UUID:}
      break unless r.nil?
    end
    result=r[1].to_s rescue "00000000-0000-0000-0000-000000000000"
  end
  result
end
