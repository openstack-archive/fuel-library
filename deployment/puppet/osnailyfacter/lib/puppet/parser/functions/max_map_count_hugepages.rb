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

    raise(
      Puppet::ParseError,
      "max_map_count_hugepages(): expected an array, got #{args[0]} type #{args[0].class}"
    ) unless args[0].is_a? Array

    sum = 65530
    hugepages_config = args[0]

    hugepages_config.each do |hpg|
      raise(
        Puppet::ParseError,
        "max_map_count_hugepages(): required all options"
      ) unless hpg['count']
      sum += hpg['count']*2
    end

    sum
  end
end
