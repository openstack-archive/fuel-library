Facter.add('acpi_event') do
  setcode do
    File.exist?('/proc/acpi/event')
  end
end
