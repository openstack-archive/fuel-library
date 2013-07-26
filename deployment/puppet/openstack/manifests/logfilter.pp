# Class for advanced log viewing & filtering UI.
# Provides configuration for custom Fuel case logs parsing
# Deploys Logstash with Elasticsearch and Kibana WEB UI
# cluster name would be fuel, logs type - "custom"
#
# Assumes rsyslog is already installed

class openstack::logfilter (
 $logstash_node = 'localhost',
 $logstash_port = '55514',
 $elasticsearch_node = 'localhost',
 # elasticsearch API port is 9200, communication ports is [9300-9400]
 $kibana_host = '0.0.0.0',
 $kibana_port = '5601',
 $cluster_name = 'fuel_001',
) {

 $elasticsearch_node_real = "${elasticsearch_node}:9200"
 # Deploy elasticsearch
 class { "::elasticsearch":
   service_settings   => { 'ES_USER' => 'elasticsearch', 'ES_GROUP' => 'elasticsearch' },
 } ->
 # Install paramedic plugin (cluster status)
 # FIXME ZipException[error in opening zip file]. Thus skipped.
 #exec { "Cluster status plugin":
 #  path               => '/usr/share/java/elasticsearch/bin',
 #  command            => 'plugin -install karmi/elasticsearch-paramedic',
 #  refreshonly        => true,
 #  returns            => 0,
 #} ->

 # Deploy logstash
 class { "::logstash":
   java_install       => true,
   jarfile            =>  '/usr/share/java/logstash.jar',
   logstash_user      => 'logstash',
   logstash_group     => 'logstash',
   port               => $logstash_port,
 } ->

 # Deploy kibana package and service, and register it at chkconfig
 package { 'kibana': } ->
 exec { 'register_kibana_chkconfig':
   path               => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
   command            => 'chkconfig --add /etc/init.d/kibana',
   returns            => 0,
 } ->
 service { 'kibana':
   ensure             => running,
   enable             => true,
   hasrestart         => true,
   hasstatus          => true,
 }

 # Configs and notifications
 file { '/usr/local/kibana/KibanaConfig.rb':
   owner              => 'root',
   group              => 'root',
   mode               => '0644',
   require            => Package['kibana'],
   content            => template("${module_name}/KibanaConfig.rb.erb"),
 } ~>
 Service<| title == 'kibana' |>

 file { '/etc/elasticsearch/elasticsearch.yml':
   owner              => 'elasticsearch',
   group              => 'elasticsearch',
   mode               => '0644',
   require            => Package['elasticsearch'],
   content            => template("${module_name}/elasticsearch.yml.erb"),
 } ~>
 Service<| title == 'elasticsearch' |>

 file { '/etc/logstash/agent/config/logstash.conf':
   owner              => 'logstash',
   group              => 'logstash',
   mode               => '0644',
   require            => Package['logstash'],
   content            => template("${module_name}/logstash.conf.erb"),
 } ~>
 Service<| title == 'logstash-agent' |>

}
