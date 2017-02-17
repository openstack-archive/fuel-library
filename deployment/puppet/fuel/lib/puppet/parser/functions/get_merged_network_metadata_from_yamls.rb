module Puppet::Parser::Functions
  newfunction(:get_merged_network_metadata_from_yamls, :type => :rvalue, :doc => <<-'ENDHEREDOC') do |args|
Load a provision data from a set of YAML files for a set of cluster
located in /var/lib/fuel/configs/{CLUSTER_ID}/provision.yaml

  ENDHEREDOC
    require 'yaml'
    merged_data = {}
    Dir["/var/lib/fuel/configs/*/provision.yaml"].each do |f|
      begin
        data = YAML::load_file(f) || {}
      rescue Exception => e
        warning("Found file #{f} but could not parse it")
        data = {}
      end
      merged_data.merge!(data['network_metadata']['nodes'])
    end
    merged_data
  end
end
