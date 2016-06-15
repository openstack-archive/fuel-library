class openstack_tasks::sahara::create_templates (
  $floating_net = 'admin_floating_net',
) {

  Sahara_node_group_template {
    ensure => present,
    floating_ip_pool => $floating_net,
    require => Service['sahara-api'],
  }

  Sahara_cluster_template {
    ensure => present,
    require => Service['sahara-api'],
  }

  Sahara_node_group_template<||> -> Sahara_cluster_template<||>

  sahara_node_group_template { 'vanilla-2-master' :
    description => 'The master node contains all management Hadoop components like NameNode, HistoryServer and ResourceManager. It also includes Oozie server required to run Hadoop jobs.',
    plugin => 'vanilla',
    flavor => 'm1.medium',
    node_processes => [ "namenode", "resourcemanager", "oozie", "historyserver" ],
    plugin_version => '2.7.1',
    auto_security_group => true,
  }

  sahara_node_group_template { 'vanilla-2-worker' :
    description => 'The worker node contains components that can be scaled by running more nodes. Each node includes everything required for data storage and processing.',
    plugin => 'vanilla',
    flavor => 'm1.medium',
    node_processes => ['datanode', 'nodemanager'],
    plugin_version => '2.7.1',
    auto_security_group => true,
  }

  sahara_cluster_template { 'vanilla-2' :
    description => 'The upstream Apache Hadoop 2.6.0 cluster with master and 3 worker nodes. The master node contains all management Hadoop processes. Workers contain Hadoop processes for data storage and processing.',
    node_groups => [ 'vanilla-2-master:1', 'vanilla-2-worker:3' ],
  }

  sahara_node_group_template { 'cdh-5-master' :
    description => 'The master node contains all management Hadoop components like NameNode, HistoryServer and ResourceManager. It also includes Oozie server required to run Hadoop jobs.',
    plugin => 'cdh',
    flavor => 'm1.large',
    node_processes => [
      "HDFS_NAMENODE",
      "HDFS_SECONDARYNAMENODE",
      "YARN_RESOURCEMANAGER",
      "YARN_JOBHISTORY",
      "OOZIE_SERVER"
    ],
    plugin_version => '5.5.0',
    auto_security_group => true,
  }

  sahara_node_group_template { 'cdh-5-manager' :
    description => 'The manager node is dedicated to Cloudera Manager management console that provides UI to manage Hadoop cluster.',
    plugin => 'cdh',
    flavor => 'm1.large',
    node_processes => [ "CLOUDERA_MANAGER" ],
    plugin_version => '5.5.0',
    auto_security_group => true,
  }

  sahara_node_group_template { 'cdh-5-worker' :
    description => 'The worker node contains components that can be scaled by running more nodes. Each node includes everything required for data storage and processing.',
    plugin => 'cdh',
    flavor => 'm1.medium',
    node_processes => [ "HDFS_DATANODE", "YARN_NODEMANAGER" ],
    plugin_version => '5.5.0',
    auto_security_group => true,
  }

  sahara_cluster_template { 'cdh-5' :
    description => 'The Cloudera distribution of Apache Hadoop (CDH) 5.4.0 cluster with manager, master and 3 worker nodes. The manager node is dedicated to Cloudera Manager management console. The master node contains all management Hadoop processes. Workers contain Hadoop processes for data storage and processing.',
    node_groups => ['cdh-5-master:1', 'cdh-5-manager:1', 'cdh-5-worker:3' ],
  }

  sahara_node_group_template { 'hdp-2-3-master' :
    description => 'The master node contains all management Hadoop components like Ambari, NameNode, HistoryServer and ResourceManager. It also includes Oozie server required to run Hadoop jobs.',
    plugin => 'ambari',
    flavor => 'm1.large',
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
    plugin_version => '2.3',
    auto_security_group => true,
  }

  sahara_node_group_template { 'hdp-2-3-worker' :
    description => 'The worker node contains components that can be scaled by running more nodes. Each node includes everything required for data storage and processing.',
    plugin => 'ambari',
    flavor => 'm1.medium',
    node_processes => [ "DataNode", "NodeManager" ],
    plugin_version => '2.3',
    auto_security_group => true,
  }

  sahara_cluster_template { 'hdp-2-3' :
    description => 'Hortonworks Data Platform (HDP) 2.3 cluster with manager, master and 4 worker nodes. The master node contains all management Hadoop processes. Workers contain Hadoop processes for data storage and processing.',
    node_groups => [ 'hdp-2-3-master:1', 'hdp-2-3-worker:4' ],
  }

}
