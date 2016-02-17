require 'json'

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
  unless argv.size == 1
      raise(Puppet::ParseError, "prepare_cgroups_hash(...): Wrong number of arguments.")
  end

  result = []
  cgroups.each do |service, settings|
    hash_settings = JSON.parse(settings['value'])
    hash_settings.each do |group, options|
      options.each do |option, value|
        result << { service => { group => { option => value }}}
      end
    end
  end

  result
end

# vim: set ts=2 sw=2 et :
