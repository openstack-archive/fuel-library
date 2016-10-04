require 'facter'
require 'hiera'

Facter.add('roles') do
  hiera_config = lambda do
    %w(
    /etc/puppet/hiera.yaml
    /etc/hiera.yaml
    ).find do |file|
      File.readable? file
    end
  end

  hiera_object = lambda do |config|
    Hiera.new(config: config)
  end

  process_roles = lambda do |roles|
    roles.map! do |role|
      role.gsub /^primary-/, ''
    end
    roles.sort!
    roles.join '_'
  end

  lookup_roles = lambda do |hiera|
    hiera.lookup 'roles', [], {}, nil, :priority
  end

  setcode do
    config = hiera_config.call
    break unless config
    hiera = hiera_object.call config
    break unless hiera
    roles = lookup_roles.call hiera
    break unless roles.is_a? Array
    process_roles.call roles
  end
end
