module Puppet::Parser::Functions
  newfunction(:map_cgclassify_opts,
              :type => :statement,
              :arity => 1,
              :doc => <<-'ENDOFDOC'

   @desc Single cgclassify options out from cgroups data

   @params cgroup's hash
     {
       'service-x' => {
        'memory' => {
          'memory.soft_limit_in_bytes' => 500,
         },
        'cpu' => {
          'cpu.shares' => 60,
         },
       },
       'service-z' => {
         'memory' => {
           'memory.soft_limit_in_bytes' => 500,
           'memory.limit_in_bytes' => 100,
         }
       }
     }

   @return mapped hash of cgclassify opts
     {
       'service-x' => ['memory:/service-x', 'cpu:/service-x'],
       'service-z' => ['memory:/service-z']
     }

   @example map_cgclassify_opts(hiera_hash(cgroups))

    ENDOFDOC
  ) do |args|

    raise(
      Puppet::ParseError,
      "map_cgclassify_opts(): expected a hash, got #{args[0]} type #{args[0].class}"
    ) unless args[0].is_a? Hash

    cgroups_config = args[0]

    resources = Hash.new { |_h, _k| _h[_k] = {:cgroup => []} }

    begin
      cgroups_config.each do |service, cgroups|
        cgroups.each_key do |ctrl|
          resources[service][:cgroup] << "#{ctrl}:/#{service}"
        end
      end
    rescue => e
      Puppet.debug "Couldn't map cgroups config: #{cgroups_config}"
      return {}
    end

    resources
  end
end
