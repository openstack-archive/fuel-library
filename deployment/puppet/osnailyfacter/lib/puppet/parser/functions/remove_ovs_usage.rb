require 'yaml'

Puppet::Parser::Functions::newfunction( :remove_ovs_usage,
                                        :type => :rvalue, :doc => <<-EOS
    This function get network_scheme and returns mangled
    network scheme without ovs-based elements.
    EOS
  ) do |argv|

    def bridge_name_max_len
      15
    end

    if argv.size != 1
      raise(
        Puppet::ParseError,
        "remove_ovs_usage(): Wrong number of arguments. Should be two."
      )
    end
    if !argv[0].is_a?(Hash)
      raise(
        Puppet::ParseError,
        "remove_ovs_usage(): Wrong network_scheme. Should be non-empty Hash."
      )
    end
    if argv[0]['version'].to_s.to_f < 1.1
      raise(
        Puppet::ParseError,
        "remove_ovs_usage(): You network_scheme hash has wrong format.\nThis parser can work with v1.1 format, please convert you config."
      )
    end

    network_scheme = argv[0]
    rv = {
      'use_ovs' => false
    }
    overrides = []

    network_scheme['transformations'].each do |tr|
      if tr['provider'] == 'ovs'
        if tr['action'] == 'add-patch'
          overrides << {
            'action'   => 'override',
            'override' => "patch-#{tr['bridges'][0]}:#{tr['bridges'][1]}",
            'provider' => 'lnx'
          }
        else
          overrides << {
            'action'   => 'override',
            'override' => tr['name'],
            'provider' => 'lnx'
          }
        end
      end
    end

    if ! overrides.empty?
      rv['network_scheme'] = {
        'transformations' => overrides
      }
    end

    return rv.to_yaml() + "\n"
end
# vim: set ts=2 sw=2 et :