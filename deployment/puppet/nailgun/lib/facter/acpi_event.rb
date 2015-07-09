require 'facter'

Facter.add('acpi_event') do
  setcode do
    if File.exist?('/proc/acpi/event')
      'true'
    else
      'false'
    end
  end
end
