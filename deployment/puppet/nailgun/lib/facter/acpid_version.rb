require 'facter'

Facter.add('acpid_version') do
  setcode do
    version = Facter::Util::Resolution.exec('acpid -v 2>/dev/null')
    version.split('-')[1][0] unless version.nil?
  end
end
