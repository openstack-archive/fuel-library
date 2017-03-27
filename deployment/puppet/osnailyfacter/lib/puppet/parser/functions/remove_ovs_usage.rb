require 'yaml'

Puppet::Parser::Functions::newfunction( :remove_ovs_usage,
                                        :type => :rvalue, :arity => 1, :doc => <<-EOS
    This function get network_scheme and returns mangled
    network scheme without ovs-based elements.
    EOS
  ) do |argv|

    raise(
      Puppet::ParseError,
      "remove_ovs_usage(): Wrong network_scheme. Should be non-empty Hash."
    ) unless argv[0].is_a?(Hash)

    raise(
      Puppet::ParseError,
      "remove_ovs_usage(): You network_scheme hash has wrong format.\nThis parser can work with v1.1 format, please convert you config."
    ) if argv[0]['version'].to_s.to_f < 1.1

    transformations = argv[0]['transformations']
    rv = {
      'use_ovs' => false
    }
    overrides = []

    transformations.each do |tr|
      # get all dependent ovs providers
      if tr['provider'] =~ /ovs/
        if tr['action'] == 'add-patch'
          overrides << {
            'action'   => 'override',
            'override' => "patch-#{tr['bridges'][0]}:#{tr['bridges'][1]}",
            'provider' => 'lnx'
          }
        else
          override_lnx = {
            'action'   => 'override',
            'override' => tr['name'],
            'provider' => 'lnx'
          }

          # handle vxlan mode
          if tr['provider'] == 'dpdkovs'
            bridge = transformations.select { |t| tr['bridge'] == t['name'] }
            bridge_vlan_id = bridge[0]['vendor_specific']['vlan_id']
            override_lnx.merge!({'name' => "#{tr['name']}.#{bridge_vlan_id}"}) if bridge_vlan_id
          end

          overrides << override_lnx
        end
      end
    end

    unless overrides.empty?
      rv['network_scheme'] = {
        'transformations' => overrides
      }
    end

    return rv.to_yaml() + "\n"
end
# vim: set ts=2 sw=2 et :
