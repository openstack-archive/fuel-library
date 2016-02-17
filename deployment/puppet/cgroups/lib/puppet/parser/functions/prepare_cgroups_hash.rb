require 'json'

module CgroupsSettings
  require 'facter'
  # value is valid if value has integer type or
  # matches with pattern: %percent, min_value, max_value
  def self.handle_value(group, value)
    return value if value.is_a?(Numeric)
    if group == 'memory' and value.match(/%(\d+), (\d+), (\d+)/)
       percent, min, max = value.scan(/%(\d+), (\d+), (\d+)/).flatten().map { |i| i.to_i() }
       total_memory = Facter.value(:memorysize_mb)
       raise ArgumentError if min > max or percent > 100 or total_memory < min
       res = (total_memory.to_f() / 100.0) * percent.to_f()
       return [min, max, res].sort[1]
    end
    raise ArgumentError
  end
end

Puppet::Parser::Functions::newfunction(:prepare_cgroups_hash, :type => :rvalue, :doc => <<-EOS
    This function get cgroups hiera fact and serialize it.

    ex: prepare_cgroups_hash(hiera('cgroups'))

    Following input:
    cinder-api:
      label: cinder-api
      type:  text
      value: {"blkio":{"blkio.weight":500}}

    will be transformed to:
      [{"cinder-api"=>{"blkio"=>{"blkio.weight"=>5}}}]

    Pattern for value field:
      {
        group1 => {
          param1 => value1,
          param2 => value2
        },
        group2 => {
          param3 => value3,
          param4 => value4
        }
      }

    EOS
  ) do |argv|
  raise(Puppet::ParseError, "prepare_cgroups_hash(...): Wrong number of arguments.") unless argv.size == 1
  raise(Puppet::ParseError, "prepare_cgroups_hash(...): Wrong type of argument. Hash is expected.") unless argv[0].is_a?(Hash)

  cgroups = argv[0]

  result = []

  begin 
    cgroups.each do |service, settings|
      hash_settings = JSON.parse(settings['value']) rescue raise("'#{service}': JSON parsing  error of value field : #{e.message}")
      raise ("'#{service}': JSON field is not a HASH instance") unless hash_settings.is_a?(Hash)
      hash_settings.each do |group, options|
        raise("'#{service}': group '#{group}' is not a HASH instance") unless options.is_a?(Hash)
        options.each do |option, value|
          value = CgroupsSettings.handle_value(group, value) #rescue raise("'#{service}': group '#{group}': option '#{option}' has wrong value")
          result << { service => { group => { option => value }}}
        end
      end
    end
  rescue => e
    Puppet.warning "prepare_cgroups_hash: Cgroups was not configured! #{e.message}"
  end
  result
end

# vim: set ts=2 sw=2 et :
