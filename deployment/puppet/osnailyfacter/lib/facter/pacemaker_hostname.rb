# Fact: pacemaker_hostname
#
# Purpose: Return name of the node used by Pacemaker
#
Facter.add(:pacemaker_hostname) do
  setcode do
    rv = Facter::Util::Resolution.exec('crm_node -n') rescue ''
  end
end
