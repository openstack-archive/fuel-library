# Fact to get a HW uuid info from dmidecode.
# Return empty uuid if not found.

require 'facter/util/resolution'

Facter.add(:uuid_dmi) do
  setcode do
    r = `dmidecode 2>/dev/null | grep UUID`
    r.match(/\S{8}-\S{4}-\S{4}-\S{4}-\S{12}/)[0].
      downcase rescue `uuidgen`.chomp
  end
end
