require 'facter'

# This file is created and managed by Astute

Facter.add('astute_settings_yaml') do
  setcode do
    astute_settings_path = '/etc/astute.yaml'
    if File.readable? astute_settings_path
      File.read astute_settings_path
    else
      nil
    end
  end
end
