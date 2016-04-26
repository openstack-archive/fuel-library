require 'facter'

Facter.add('acpid_version') do
  setcode do
    version = Facter::Util::Resolution.exec('acpid -v 2>/dev/null')
    version.nil? ? "" : version.split('-')[1][0]
  end
end
