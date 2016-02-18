require 'puppet/parser/functions'

Puppet::Parser::Functions.newfunction(:generate_cgclassify,
                                      :type => :statement,
                                      :arity => -2,
                                      :doc => <<-'ENDOFDOC'

Takes a cgroup's hash and a list of default attributes:
  generate_cgclassify(hiera_hash(cgroups), {'ensure' => 'present'})

ENDOFDOC
) do |args|

  cgroups_config, defaults = args
  defaults ||= { :ensure => :present }

  resources = Hash.new { |_h, _k| _h[_k] = {:cgroup => []} }

  cgroups_config.each do |service, cgroups|
    cgroups.each_key do |ctrl|
      resources[service][:cgroup] << "#{ctrl}:/#{service}"
    end
  end

  function_create_resources(['cgclassify', resources, defaults])

end
