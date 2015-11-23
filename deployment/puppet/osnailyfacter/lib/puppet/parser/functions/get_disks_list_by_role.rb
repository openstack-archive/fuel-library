module Puppet::Parser::Functions
  newfunction(:get_disks_list_by_role, :type => :rvalue, :doc => <<-EOS
Return a list of disks (node roles are keys) that have the given node role.
example:
  get_disks_list_by_role($node_volumes, 'cinder')
EOS
  ) do |args|
    errmsg = "get_disks_list_by_role($node_volumes, 'cinder')"
    disks_metadata, role = args
    raise(Puppet::ParseError, "#{errmsg}: 1st argument should be an array") if !disks_metadata.is_a?(Array)
    raise(Puppet::ParseError, "#{errmsg}: 2nd argument should be node role") if !role.is_a?(String)
    disks = Array.new
    disks_metadata.each do |disk|
      if not disk['volumes'].nil? and not disk['volumes'].empty?
        disk['volumes'].each do |volume|
          if not volume['vg'].nil? and volume['vg'] == role and not volume['size'].nil? and volume['size'] != 0
            disks << '/dev/' + disk['name']
            break
          end
        end
      end
    end
    return disks
  end
end

# vim: set ts=2 sw=2 et :
