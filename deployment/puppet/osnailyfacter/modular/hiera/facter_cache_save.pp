File {
  ensure => 'present',
  owner  => 'root',
  group  => 'root',
  mode   => '0644',
}

file { [ '/etc', '/etc/facter', '/etc/facter/facts.d' ] :
  ensure => 'directory',
  mode   => '0755',
}

$facter_cache_file = '/etc/facter/cache.yaml'
$facter_exclude_var = 'FACTER_NO_CACHE'
$facter_cache_script = '/etc/facter/facts.d/cache.rb'

file { $facter_cache_file :
  content => inline_template('<% facts = scope.to_hash.reject do |fact, value| -%>
<% next true unless fact.is_a? String and value.is_a? String -%>
<% exclude_variable = [ "astute_settings_yaml", "puppet_vardir", "cacert", "cacrl", "cakey", "certname", "hostcert", "hostprivkey", "localcacert", "_timestamp", "clientcert", "clientversion", "clientnoop", "environment", "title", "name", "module_name", "facter_cache_file", "facter_exclude_var", "facter_cache_script", "uptime" ] -%>
<% next true if exclude_variable.include? fact -%>
<% end -%>
<%= YAML.dump facts %>
'),
}

file { $facter_cache_script :
  content => template('osnailyfacter/facter_cache.rb.erb'),
  mode    => '0755',
}
