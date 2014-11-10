# Fact: pacemaker_hostname
# Return name of the node used by Pacemaker
Facter.add(:crm_node) do
  setcode do
    Facter::Util::Resolution.exec('crm_node -n')
  end
end
