require 'facter'

# This file is created and managed by Astute
astute_settings_path = '/etc/astute.yaml'

Facter.add('astute_settings_yaml') do
  setcode do
    if File.readable? astute_settings_path
      File.read astute_settings_path
    else
      nil
    end
  end
end