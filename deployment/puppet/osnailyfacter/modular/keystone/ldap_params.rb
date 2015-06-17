#!/usr/bin/ruby

ldap_manifest = File.join File.dirname(__FILE__), '../../../keystone/manifests/ldap.pp'
fail 'No manifest!' unless File.file? ldap_manifest

parameters = []
File.read(ldap_manifest).split("\n").each do |line|
  parameters << $1 if line =~ %r(\s*\$(\w+)\s+=\s+)
end

max_length = parameters.max_by { |p| p.length}.length

parameters.each do |p|
  puts "    #{p.ljust max_length} => structure($ldap_hash, '#{p}'),"
end

