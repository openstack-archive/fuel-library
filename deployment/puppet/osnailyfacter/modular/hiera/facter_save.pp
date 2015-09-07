file { [ '/etc', '/etc/facter', '/etc/facter/facts.d' ] :
  ensure => 'directory'
}

file { '/etc/facter/facts.d/cache.yaml' :
  content => inline_template('<% facts = scope.to_hash.reject do |fact, value| -%>
<% next true unless fact.is_a? String and value.is_a? String -%>
<% exclude_variable = [ "astute_settings_yaml", "puppet_vardir", "cacert", "cacrl", "cakey", "certname", "hostcert", "hostprivkey", "localcacert", "_timestamp", "clientcert", "clientversion", "clientnoop", "environment", "title", "name", "module_name" ] -%>
<% next true if exclude_variable.include? fact -%>
<% end -%>
<%= YAML.dump facts %>
'),
}
