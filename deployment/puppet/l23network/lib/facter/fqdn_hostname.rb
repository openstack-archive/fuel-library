# Fact: l3_fqdn_hostname
#
# Purpose: Return FQDN or hostname if FQDN undefined
#
Facter.add(:l3_fqdn_hostname) do
  hostname_simple = Facter.value(:hostname)
  hostname_fqdn = Facter.value(:fqdn)
  setcode do
    rv = hostname_fqdn || hostname_simple
  end
end
