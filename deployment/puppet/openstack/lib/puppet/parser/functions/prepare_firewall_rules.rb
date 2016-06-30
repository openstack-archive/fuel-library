module Puppet::Parser::Functions
  newfunction(:prepare_firewall_rules, :type => :rvalue, :doc => <<-EOS
Creates a hash of firewall rules from an array of specified source_nets.

Example:

prepare_firewall_rules(['10.20.0.0/24','10.20.0.1']','020 ssh', 'accept',
                       'INPUT', '22','tcp') returns
{
  '020 ssh from 10.0.0.0/24' => {'action' => 'accept',
                                 'chain'  => 'INPUT',
                                 'port'   => '22',
                                 'proto'  => 'tcp',
                                 'source' => '10.0.0.0/24'},
  '020 ssh from 10.0.1.0/24' => {'action' => 'accept',
                                 'chain'  => 'INPUT',
                                 'port'   => '22',
                                 'proto'  => 'tcp',
                                 'source' => '10.0.1.0/24'}
}
    EOS
  ) do |args|

    raise ArgumentError, ("prepare_firewall_rules(): wrong number of arguments (#{args.length}; must be 6)") if args.length != 6

    rule_basename = args[1]
    action        = args[2]
    chain         = args[3]
    port          = args[4]
    proto         = args[5]

    raise ArgumentError, 'prepare_firewall_rules(): rule_basename is not a string' if !rule_basename.is_a?(String)
    raise ArgumentError, 'prepare_firewall_rules(): source_net is not an array of strings' if args[0].any? { |v| !v.is_a?(String) }

    fw_rules = {}
    args[0].each do |source_net|


      name = "#{rule_basename} from #{source_net}"
      fw_rules[name] = {}
      # Add params only if nonempty
      fw_rules[name]['action'] = action unless [nil, ''].include?(action)
      fw_rules[name]['chain'] = chain unless [nil, ''].include?(chain)
      fw_rules[name]['dport'] = port unless [nil, ''].include?(port)
      fw_rules[name]['proto'] = proto unless [nil, ''].include?(proto)
      fw_rules[name]['source'] = source_net
    end
    return fw_rules
  end
end

