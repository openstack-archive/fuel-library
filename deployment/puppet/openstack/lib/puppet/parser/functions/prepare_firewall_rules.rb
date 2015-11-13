module Puppet::Parser::Functions
  newfunction(:prepare_firewall_rules, :type => :rvalue, :doc => <<-EOS
    Creates a hash of firewall rules from an array of specified source_nets.
    EOS
  ) do |args|
    rule_basename = args[1]
    action        = args[2]
    chain         = args[3]
    port          = args[6]
    proto         = args[7]

    fw_rules = {}
    args[0].each do |source_net|
      name = "#{rule_basename} for #{source_net}"
      fw_rules[name] = {}
      # Add params only if nonempty
      fw_rules[name]['action'] = action unless [nil, ''].include?(action)
      fw_rules[name]['chain'] = chain unless [nil, ''].include?(chain)
      fw_rules[name]['port'] = port unless [nil, ''].include?(port)
      fw_rules[name]['proto'] = proto unless [nil, ''].include?(proto)
      fw_rules[name]['source'] = source_net
    end
    return fw_rules
  end
end

