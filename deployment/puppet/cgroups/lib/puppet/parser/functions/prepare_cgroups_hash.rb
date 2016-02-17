require 'facter'
require 'json'

module CgroupsSettings
end

Puppet::Parser::Functions::newfunction(:prepare_cgroups_hash, :type => :rvalue, :doc => <<-EOS
    This function get cgroups hiera fact
    and serialize it.

    ex: prepare_cgroups_hash(hiera('ipaddr'))

    Following input:
    cinder-api:
      label: cinder-api
      type:  text
      value: {"blkio":{"blkio.weight":500}}

    will be transformed to:
      [{"cinder-api"=>{"blkio"=>{"blkio.weight"=>5}}}]

    EOS
  ) do |argv|
  raise(Puppet::ParseError, "prepare_cgroups_hash(...): Wrong number of arguments.") unless argv.size == 1
  raise(Puppet::ParseError, "prepare_cgroups_hash(...): Wrong type of argument. Hash is expected.") unless argv[0].is_a?(Hash)

  cgroups = argv[0]
  total_memorysize_mb = Facter.value(:memorysize_mb)

  result = []
  cgroups.each do |service, settings|
    hash_settings = JSON.parse(settings['value'])
    next unless hash_settings.is_a?(Hash)
    hash_settings.each do |group, options|
      next unless options.is_a?(Hash)
      options.each do |option, value|
        result << { service => { group => { option => value }}}
      end
    end
  end

  result
end

# vim: set ts=2 sw=2 et :
