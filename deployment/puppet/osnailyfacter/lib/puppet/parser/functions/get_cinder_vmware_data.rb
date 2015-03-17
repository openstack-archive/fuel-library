module Puppet::Parser::Functions
  newfunction(:get_cinder_vmware_data, :type => :rvalue,
:doc => <<-EOS
Transform data to suitable form for cinder-vmware:
1. Rebuild array of hashes to hash of hashes with availability_zone_name as a key
2. Add debug value.
3. Delete useless keys.
EOS
  ) do |args|
    raise(Puppet::ParseError, 'Empty array provided!') if args.size < 1
    computes = args[0]
    debug = args[1] || "false"
    computes.each {|h| h.store("debug", debug)}
    computes.each {|h| h.delete("datastore_regex")}
    computes.each {|h| h.delete("vc_cluster")}
    computes.each {|h| h.delete("service_name")}
    Hash[computes.collect {|h| [h["availability_zone_name"], h]}]
  end
end
