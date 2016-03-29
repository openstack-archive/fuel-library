# Eventually this functions should be revised and removed.
# Such data structure forming should be done by nailgun
Puppet::Parser::Functions::newfunction(
    :parse_vcenter_settings,
    :type => :rvalue,
    :arity => 1,
    :doc => <<-EOS
Convert array of computes of vCenter settings to hash
EOS
) do |args|
  settings = args[0]
  settings = [settings] unless settings.is_a? Array
  settings_hash = {}
  settings.each_with_index do |value, key|
    next unless value.is_a? Hash
    settings_hash.store key.to_s, value
  end
  settings_hash
end
