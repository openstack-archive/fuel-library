require 'facter'

Facter.add('acpi_event') do
  setcode do
    File.exists? '/proc/acpi/event'
  end
end
