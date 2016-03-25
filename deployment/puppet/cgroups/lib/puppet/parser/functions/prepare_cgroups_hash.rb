require 'json'

module CgroupsSettings
  require 'facter'
  # value is valid if value has integer type or
  # matches with pattern: %percent, min_value, max_value
  def self.handle_value(option, value)
    # transform value in megabytes to bytes for limits of memory
    return handle_memory(value) if option.to_s.end_with? "_in_bytes"
    # keep it as it is for others
    return value if value.is_a?(Integer)
  end

  def self.handle_memory(value)
    return mb_to_bytes(value) if value.is_a?(Integer)
    if value.is_a?(String) and matched_v = value.match(/%(\d+),\s*(\d+),\s*(\d+)/)
      percent, min, max = matched_v[1..-1].map(&:to_i)
      total_memory = Facter.value(:memorysize_mb)
      res = (total_memory.to_f / 100.0) * percent.to_f
      return mb_to_bytes([min, max, res].sort[1]).to_i
    end
  end

  def self.mb_to_bytes(value)
    return value * 1024 * 1024
  end
end

Puppet::Parser::Functions::newfunction(:prepare_cgroups_hash, :type => :rvalue, :arity => 1, :doc => <<-EOS
    This function get hash contains service and its cgroups settings(in JSON format) and serialize it.

    ex: prepare_cgroups_hash(hiera('cgroups'))

    Following input:
    {
      'metadata' => {
        'always_editable' => true,
        'group' => 'general',
        'label' => 'Cgroups',
        'weight' => 50
      },
      cinder-api: {"blkio":{"blkio.weight":500}}
    }

    will be transformed to:
      [{"cinder-api"=>{"blkio"=>{"blkio.weight"=>500}}}]

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

  # wipe out UI metadata
  cgroups = argv[0].tap { |el| el.delete('metadata') }

  serialized_data = {}

  cgroups.each do |service, settings|
    hash_settings = JSON.parse(settings) rescue raise("'#{service}': JSON parsing  error for : #{settings}")
    hash_settings.each do |group, options|
      raise("'#{service}': group '#{group}' options is not a HASH instance") unless options.is_a?(Hash)
      options.each do |option, value|
        options[option] = CgroupsSettings.handle_value(option, value)
        raise("'#{service}': group '#{group}': option '#{option}' has wrong value") if options[option].nil?
      end
    end
    serialized_data[service] = hash_settings unless hash_settings.empty?
  end
  serialized_data
end

# vim: set ts=2 sw=2 et :
