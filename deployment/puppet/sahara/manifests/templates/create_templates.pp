class sahara::templates::create_templates (
  $auth_uri         = 'http://127.0.0.1:5000/v2.0/',
  $auth_user        = 'sahara',
  $auth_tenant      = 'services',
  $auth_password    = 'sahara',
  $use_neutron      = false,
) inherits sahara::params {

  Sahara_node_group_template {
    ensure => present,
    auth_url => $auth_uri,
    auth_username => $auth_user,
    auth_password => $auth_password,
    auth_tenant_name => $auth_tenant,
    neutron => $use_neutron,
    debug => true,
    require => Service['sahara'],
  }

  Sahara_cluster_template {
    ensure => present,
    auth_url => $auth_uri,
    auth_username => $auth_user,
    auth_password => $auth_password,
    auth_tenant_name => $auth_tenant,
    neutron => $use_neutron,
    debug => true,
    require => Service['sahara'],
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
    hadoop_version => '2.4.1',
    auto_security_group => true,
  }

  sahara_node_group_template { 'vanilla-2-worker' :
    description => 'The worker node contains components that can be scaled by running more nodes. Each node includes everything required for data storage and processing.',
    plugin_name => 'vanilla',
    flavor_id => 'm1.medium',
    node_processes => ['datanode', 'nodemanager'],
    hadoop_version => '2.4.1',
    auto_security_group => true,
  }

  sahara_cluster_template { 'vanilla-2' :
    description => 'The upstream Apache Hadoop 2.4.1 cluster with master and 3 worker nodes. The master node contains all management Hadoop processes. Workers contain Hadoop processes for data storage and processing.',
    plugin_name => 'vanilla',
    node_groups => [
      {'name' => 'vanilla-2-master', 'count' => 1},
      {'name' => 'vanilla-2-worker', 'count' => 3}
    ],
    hadoop_version => '2.4.1',
  }

  sahara_node_group_template { 'cdh-5-master' :
    description => 'The master node contains all management Hadoop components like NameNode, HistoryServer and ResourceManager. It also includes Oozie server required to run Hadoop jobs.',
    plugin_name => 'cdh',
    flavor_id => 'm1.large',
    node_processes => [
        "NAMENODE",
        "SECONDARYNAMENODE",
        "RESOURCEMANAGER",
        "JOBHISTORY",
        "OOZIE_SERVER"
    ],
    hadoop_version => '5',
    auto_security_group => true,
  }

  sahara_node_group_template { 'cdh-5-manager' :
    description => 'The manager node is dedicated to Cloudera Manager management console that provides UI to manage Hadoop cluster.',
    plugin_name => 'cdh',
    flavor_id => 'm1.large',
    node_processes => [
        "MANAGER"
    ],
    hadoop_version => '5',
    auto_security_group => true,
  }

  sahara_node_group_template { 'cdh-5-worker' :
    description => 'The worker node contains components that can be scaled by running more nodes. Each node includes everything required for data storage and processing.',
    plugin_name => 'cdh',
    flavor_id => 'm1.medium',
    node_processes => [
        "DATANODE",
        "NODEMANAGER"
    ],
    hadoop_version => '5',
    auto_security_group => true,
  }

  sahara_cluster_template { 'cdh-5' :
    description => 'The Cloudera distribution of Apache Hadoop (CDH) 5.2.0 cluster with manager, master and 3 worker nodes. The manager node is dedicated to Cloudera Manager management console. The master node contains all management Hadoop processes. Workers contain Hadoop processes for data storage and processing.',
    plugin_name => 'cdh',
    node_groups => [
      {'name' => 'cdh-5-master', 'count' => 1},
      {'name' => 'cdh-5-manager', 'count' => 1},
      {'name' => 'cdh-5-worker', 'count' => 3}
    ],
    hadoop_version => '5',
  }

  sahara_node_group_template { 'hdp-2-master' :
    description => 'The master node contains all management Hadoop components like NameNode, HistoryServer and ResourceManager. It also includes Oozie server required to run Hadoop jobs.',
    plugin_name => 'hdp',
    flavor_id => 'm1.large',
    node_processes => [
        "NAMENODE",
        "SECONDARY_NAMENODE",
        "ZOOKEEPER_SERVER",
        "ZOOKEEPER_CLIENT",
        "HISTORYSERVER",
        "RESOURCEMANAGER",
        "OOZIE_SERVER"
    ],
    hadoop_version => '2.0.6',
    auto_security_group => true,
  }

  sahara_node_group_template { 'hdp-2-manager' :
    description => 'The manager node is dedicated to Ambari 1.4.1 management console that provides UI to manage Hadoop cluster. The node also includes third party monitoring systems: Ganglia 3.5.0 and Nagios 3.5.0.',
    plugin_name => 'hdp',
    flavor_id => 'm1.large',
    node_processes => [
        "AMBARI_SERVER",
        "GANGLIA_SERVER",
        "NAGIOS_SERVER"
    ],
    hadoop_version => '2.0.6',
    auto_security_group => true,
  }

  sahara_node_group_template { 'hdp-2-worker' :
    description => 'The worker node contains components that can be scaled by running more nodes. Each node includes everything required for data storage and processing.',
    plugin_name => 'hdp',
    flavor_id => 'm1.medium',
    node_processes => [
        "DATANODE",
        "HDFS_CLIENT",
        "ZOOKEEPER_CLIENT",
        "PIG",
        "MAPREDUCE2_CLIENT",
        "YARN_CLIENT",
        "NODEMANAGER",
        "OOZIE_CLIENT"
    ],
    hadoop_version => '2.0.6',
    auto_security_group => true,
  }

  sahara_cluster_template { 'hdp-2' :
    description => 'Hortonworks Data Platform (HDP) 2.0.6 cluster with manager, master and 3 worker nodes. The manager node is dedicated to Ambari 1.4.1 management console. The master node contains all management Hadoop processes. Workers contain Hadoop processes for data storage and processing.',
    plugin_name => 'hdp',
    node_groups => [
      {'name' => 'hdp-2-master', 'count' => 1},
      {'name' => 'hdp-2-manager', 'count' => 1},
      {'name' => 'hdp-2-worker', 'count' => 3}
    ],
    hadoop_version => '2.0.6',
  }

  sahara_node_group_template { 'hdp-2-2-master' :
    description => 'The master node contains all management Hadoop components like Ambari, NameNode, HistoryServer and ResourceManager. It also includes Oozie server required to run Hadoop jobs.',
    plugin_name => 'hdp',
    flavor_id => 'm1.large',
    node_processes => [
        "NAMENODE",
        "SECONDARY_NAMENODE",
        "ZOOKEEPER_SERVER",
        "AMBARI_SERVER",
        "HIVE_SERVER",
        "HIVE_METASTORE",
        "MYSQL_SERVER",
        "WEBHCAT_SERVER",
        "TEZ_CLIENT",
        "HISTORYSERVER",
        "RESOURCEMANAGER",
        "OOZIE_SERVER",
        "NAGIOS_SERVER",
        "GANGLIA_SERVER"
    ],
    hadoop_version => '2.2.0',
    auto_security_group => true,
  }

  sahara_node_group_template { 'hdp-2-2-worker' :
    description => 'The worker node contains components that can be scaled by running more nodes. Each node includes everything required for data storage and processing.',
    plugin_name => 'hdp',
    flavor_id => 'm1.medium',
    node_processes => [
        "DATANODE",
        "HDFS_CLIENT",
        "ZOOKEEPER_CLIENT",
        "HIVE_CLIENT",
        "PIG",
        "TEZ_CLIENT",
        "MAPREDUCE2_CLIENT",
        "YARN_CLIENT",
        "NODEMANAGER",
        "OOZIE_CLIENT"
    ],
    hadoop_version => '2.2.0',
    auto_security_group => true,
  }

  sahara_cluster_template { 'hdp-2-2' :
    description => 'Hortonworks Data Platform (HDP) 2.2.0 cluster with manager, master and 4 worker nodes. The master node contains all management Hadoop processes. Workers contain Hadoop processes for data storage and processing.',
    plugin_name => 'hdp',
    node_groups => [
      {'name' => 'hdp-2-2-master', 'count' => 1},
      {'name' => 'hdp-2-2-worker', 'count' => 4}
    ],
    hadoop_version => '2.2.0',
  }

}
