# Eventually this functions should be revised and removed.
# Such data structure forming should be done by nailgun
Puppet::Parser::Functions::newfunction(
:parse_vcenter_settings,
:type => :rvalue,
:doc => <<-EOS
Convert array of computes of vCenter settings to hash
EOS
) do |args|
  unless args.size > 0
    raise Puppet::ParseError, "You should give an array of computes!"
  end
  settings = [args[0]].flatten
  settings_hash = Hash[(0...settings.size).zip settings]
end

