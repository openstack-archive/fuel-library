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

Puppet::Parser::Functions::newfunction(:prepare_cgroups_hash, :type => :rvalue, :arity => 1, :doc => <<-EOS
    This function get hash contains service and its cgroups settings(in JSON format) and serialize it.

    ex: prepare_cgroups_hash(hiera('cgroups'))

    Following input:
    cinder-api: {"blkio":{"blkio.weight":500}}

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
  raise(Puppet::ParseError, "prepare_cgroups_hash(...): Wrong type of argument. Hash is expected.") unless argv[0].is_a?(Hash)

  cgroups = argv[0]

  serialized_data = []

  begin
    cgroups.each do |service, settings|
      hash_settings = JSON.parse(settings) rescue raise("'#{service}': JSON parsing  error of value field : #{e.message}")
      hash_settings.each do |group, options|
        raise("'#{service}': group '#{group}'options is not a HASH instance") unless options.is_a?(Hash)
        options.each do |option, value|
          value = CgroupsSettings.handle_value(group, value) rescue raise("'#{service}': group '#{group}': option '#{option}' has wrong value")
          serialized_data << { service => { group => { option => value }}}
        end
      end
    end
  rescue => e
    Puppet.warning "prepare_cgroups_hash: Cgroups was not configured! #{e.message}"
  end
  serialized_data
end

# vim: set ts=2 sw=2 et :
