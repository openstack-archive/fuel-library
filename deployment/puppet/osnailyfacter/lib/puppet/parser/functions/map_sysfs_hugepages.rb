module Puppet::Parser::Functions
  newfunction(:map_sysfs_hugepages,
              :type => :rvalue,
              :arity => 1,
              :doc => <<-'ENDOFDOC'

    @desc Map sysfs options from hugepages data

    @params hugepages's array
      [
        { 'count' => 512, 'numa_id' => 0, 'size' => 2048 },
        { 'count' => 8, 'numa_id' => 1, 'size' => 1048576 }
      ]

    @return mapped hash of sysfs opts
      {
        'node0/hugepages/hugepages-2048kB' => 512,
        'node1/hugepages/hugepages-1048576kB' => 8,
        'default' => 0
      }

    @example map_sysfs_hugepages(hiera('hugepages'))

    ENDOFDOC
  ) do |args|

    raise(
      Puppet::ParseError,
      "map_sysfs_hugepages(): expected an array, got #{args[0]} type #{args[0].class}"
    ) unless args[0].is_a? Array

    hugepages_config = args[0]
    required_opts = ['count', 'numa_id', 'size']
    sysfs_hugepages = {}

    hugepages_config.each do |hpg|
      raise(
        Puppet::ParseError,
        "map_sysfs_hugepages(): required all options #{required_opts}, got only #{hpg.keys}"
      ) unless required_opts.all? { |opt| hpg.key? opt }

      hpg_path = sprintf(
        'node%u/hugepages/hugepages-%ukB',
        hpg['numa_id'],
        hpg['size']
      )
      sysfs_hugepages[hpg_path] = hpg['count']
    end

    # no allocations by default
    sysfs_hugepages.merge({'default' => 0})
  end
end
