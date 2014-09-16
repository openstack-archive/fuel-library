# Eventually this functions should be revised and removed.
# Such data structure forming should be done by nailgun.
Puppet::Parser::Functions::newfunction(
:vmware_index,
:type => :rvalue,
:doc => <<-EOS
Split string that contains array of vSphere clusters and enumerate them
EOS
) do |args|
  unless args.size > 0
    raise Puppet::ParseError, "You should give an array of clusters!"
  end

  cluster_names = args[0]
  index_name = args[1] || 'index'

  clusters_hash = {}
  cluster_names.split(',').each_with_index do |name, index|
    cluster = {
      index_name => index.to_s,
    }
    clusters_hash[name] = cluster
  end
  clusters_hash
end
