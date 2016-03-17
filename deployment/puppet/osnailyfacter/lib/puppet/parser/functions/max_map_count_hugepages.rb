module Puppet::Parser::Functions
  newfunction(:max_map_count_hugepages,
              :type => :rvalue,
              :arity => 1,
              :doc => <<-'ENDOFDOC'

@desc Calculate vm.max_map_count from hugepages data

@params hugepages's array
  [
    { 'count' => 512, 'numa_id' => 0, 'size' => 2048 },
    { 'count' => 8, 'numa_id' => 1, 'size' => 1048576 }
  ]

@return mapped hash of sysfs opts
  66570

@example max_map_count_hugepages(hiera('hugepages'))

ENDOFDOC
  ) do |args|

    hugepages_config = args.flatten
    sum = 65530

    hugepages_config.each do |hpg|
      raise(
        Puppet::ParseError,
        "max_map_count_hugepages(): expected a hash with 'count' key, got #{hpg}"
      ) unless hpg.is_a? Hash and hpg['count']
      sum += hpg['count']*2
    end

    sum
  end
end
