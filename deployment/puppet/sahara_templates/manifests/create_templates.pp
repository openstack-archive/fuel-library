class sahara_templates::create_templates (
  $auth_uri         = 'http://127.0.0.1:5000/v2.0/',
  $auth_user        = 'sahara',
  $auth_tenant      = 'services',
  $auth_password    = 'sahara',
  $use_neutron      = false,
  $internal_net     = 'admin_internal_net',
) inherits sahara::params {

  Sahara_node_group_template {
    ensure => present,
    auth_url => $auth_uri,
    auth_username => $auth_user,
    auth_password => $auth_password,
    auth_tenant_name => $auth_tenant,
    neutron => $use_neutron,
    debug => true,
    require => Service['sahara-api'],
  }

  Sahara_cluster_template {
    ensure => present,
    auth_url => $auth_uri,
    auth_username => $auth_user,
    auth_password => $auth_password,
    auth_tenant_name => $auth_tenant,
    neutron => $use_neutron,
    neutron_management_network => $internal_net,
    debug => true,
    require => Service['sahara-api'],
  }

  Sahara_node_group_template<||> -> Sahara_cluster_template<||>

  sahara_node_group_template { 'vanilla-2-master' :
    description => 'The master node contains all management Hadoop components like NameNode, HistoryServer and ResourceManager. It also includes Oozie server required to run Hadoop jobs.',
    plugin_name => 'vanilla',
    flavor_id => 'm1.medium',
    node_processes => [
        "namenode",
        "resourcemanager",
        "oozie",
        "historyserver"
    ],
    hadoop_version => '2.7.1',
    auto_security_group => true,
  }

  sahara_node_group_template { 'vanilla-2-worker' :
    description => 'The worker node contains components that can be scaled by running more nodes. Each node includes everything required for data storage and processing.',
    plugin_name => 'vanilla',
    flavor_id => 'm1.medium',
    node_processes => ['datanode', 'nodemanager'],
    hadoop_version => '2.7.1',
    auto_security_group => true,
  }

  sahara_cluster_template { 'vanilla-2' :
    description => 'The upstream Apache Hadoop 2.6.0 cluster with master and 3 worker nodes. The master node contains all management Hadoop processes. Workers contain Hadoop processes for data storage and processing.',
    plugin_name => 'vanilla',
    node_groups => [
      {'name' => 'vanilla-2-master', 'count' => 1},
      {'name' => 'vanilla-2-worker', 'count' => 3}
    ],
    hadoop_version => '2.7.1',
  }

  sahara_node_group_template { 'cdh-5-master' :
    description => 'The master node contains all management Hadoop components like NameNode, HistoryServer and ResourceManager. It also includes Oozie server required to run Hadoop jobs.',
    plugin_name => 'cdh',
    flavor_id => 'm1.large',
    node_processes => [
        "HDFS_NAMENODE",
        "HDFS_SECONDARYNAMENODE",
        "YARN_RESOURCEMANAGER",
        "YARN_JOBHISTORY",
        "OOZIE_SERVER"
    ],
    hadoop_version => '5.4.0',
    auto_security_group => true,
  }

  sahara_node_group_template { 'cdh-5-manager' :
    description => 'The manager node is dedicated to Cloudera Manager management console that provides UI to manage Hadoop cluster.',
    plugin_name => 'cdh',
    flavor_id => 'm1.large',
    node_processes => [
        "CLOUDERA_MANAGER"
    ],
    hadoop_version => '5.4.0',
    auto_security_group => true,
  }

  sahara_node_group_template { 'cdh-5-worker' :
    description => 'The worker node contains components that can be scaled by running more nodes. Each node includes everything required for data storage and processing.',
    plugin_name => 'cdh',
    flavor_id => 'm1.medium',
    node_processes => [
        "HDFS_DATANODE",
        "YARN_NODEMANAGER"
    ],
    hadoop_version => '5.4.0',
    auto_security_group => true,
  }

  sahara_cluster_template { 'cdh-5' :
    description => 'The Cloudera distribution of Apache Hadoop (CDH) 5.4.0 cluster with manager, master and 3 worker nodes. The manager node is dedicated to Cloudera Manager management console. The master node contains all management Hadoop processes. Workers contain Hadoop processes for data storage and processing.',
    plugin_name => 'cdh',
    node_groups => [
      {'name' => 'cdh-5-master', 'count' => 1},
      {'name' => 'cdh-5-manager', 'count' => 1},
      {'name' => 'cdh-5-worker', 'count' => 3}
    ],
    hadoop_version => '5.4.0',
  }

  sahara_node_group_template { 'hdp-2-3-master' :
    description => 'The master node contains all management Hadoop components like Ambari, NameNode, HistoryServer and ResourceManager. It also includes Oozie server required to run Hadoop jobs.',
    plugin_name => 'ambari',
    flavor_id => 'm1.large',
    node_processes => [
        "NameNode",
        "SecondaryNameNode",
        "ZooKeeper",
        "Ambari",
        "YARN Timeline Server",
        "MapReduce History Server",
        "ResourceManager",
        "Oozie"
    ],
    hadoop_version => '2.3',
    auto_security_group => true,
  }

  sahara_node_group_template { 'hdp-2-3-worker' :
    description => 'The worker node contains components that can be scaled by running more nodes. Each node includes everything required for data storage and processing.',
    plugin_name => 'ambari',
    flavor_id => 'm1.medium',
    node_processes => [
        "DataNode",
        "NodeManager",
    ],
    hadoop_version => '2.3',
    auto_security_group => true,
  }

  sahara_cluster_template { 'hdp-2-3' :
    description => 'Hortonworks Data Platform (HDP) 2.3 cluster with manager, master and 4 worker nodes. The master node contains all management Hadoop processes. Workers contain Hadoop processes for data storage and processing.',
    plugin_name => 'ambari',
    node_groups => [
      {'name' => 'hdp-2-3-master', 'count' => 1},
      {'name' => 'hdp-2-3-worker', 'count' => 4}
    ],
    hadoop_version => '2.3',
  }

}
