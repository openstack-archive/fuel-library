# Fact: l3_fqdn_hostname
#
# Purpose: Return FQDN or hostname if FQDN undefined
#
Facter.add(:l3_fqdn_hostname) do
  setcode do
    rv = Facter.value(:fqdn) || Facter.value(:hostname)
  end
end
