module Puppet::Parser::Functions
  newfunction(:get_disks_list_by_role, :type => :rvalue, :doc => <<-EOS
Return a list of disks (node roles are keys) that have the given node role.
example:
  get_disks_list_by_role($disks_hash, 'cinder-block-device')
EOS
  ) do |args|
    errmsg = "get_disks_list_by_role($disks_hash, 'cinder-block-device')"
    disks_metadata, role = args
    raise(Puppet::ParseError, "#{errmsg}: 1st argument should be a hash") if !disks_metadata.is_a?(Hash)
    raise(Puppet::ParseError, "#{errmsg}: 1st argument should be a valid disk_metadata hash") if !disks_metadata.has_key?('disk') and !disks_metadata.has_key?('volumes')
    raise(Puppet::ParseError, "#{errmsg}: 2nd argument should be node role") if !roles.is_a?(String)
    disks = []
    disks_metadata.each do |disk|
      if not disk[:volumes].nil? and not disk[:volumes].empty?
        disk[:volumes].each do |volume|
          if not volume[:vg].nil? and volume[:vg] == role and volume[:size].nil? and volume[:size] != 0
            disks << disk[:disk]
            break
          end
        end
      end
    end
    return disks
  end
end

# vim: set ts=2 sw=2 et :
