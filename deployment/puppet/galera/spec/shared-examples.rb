# this is a basic example that just checks there are no puppet syntax issues or
# compile errors
shared_examples 'compile' do
  it {
    should compile
  }
end

# this example checks all of the expected items for the galera::init class
shared_examples 'galera-init' do |params|
  params = {} if params.nil?
  it {
    should contain_class('galera')
    should contain_class('galera::params')
    should contain_tweaks__ubuntu_service_override('mysql')
  }
  it_behaves_like 'compile'
  it_behaves_like 'test-packages', params
  it_behaves_like 'test-files', params
  it_behaves_like 'test-services', params
  it_behaves_like 'test-primary-controller', params
  it_behaves_like 'test-backup', params
end

# this example checks for the existance of the expected files for the galera
# class
shared_examples 'test-files' do |params|
  params = {} if params.nil?

  p = {
    :use_percona_packages => false
  }.merge(params)

  let (:params) { p }

  it {
    should contain_file('/etc/my.cnf')
    should contain_file('/etc/mysql')
    should contain_file('/etc/mysql/conf.d')
    should contain_file('/etc/init.d/mysql')
    should contain_file('/etc/mysql/conf.d/wsrep.cnf')
    should contain_file('/tmp/wsrep-init-file')
    if params[:use_percona_packages] and facts[:operatingsystem] == 'Ubuntu'
      should contain_file('/etc/apt/apt.conf.d/99tmp')
    end
  }
end

# this example checks for the definition of the specific packages expected for
# the galera class
shared_examples 'test-packages' do |params|
  params = {} if params.nil?

  p = {
    :wsrep_sst_method     => 'xtrabackup-v2',
    :use_percona          => false,
    :use_percona_packages => false
  }.merge(params)

  let (:params) { p }

  if params[:use_percona]
    if params[:use_percona_packages]
      it_behaves_like 'percona-packages'
    else
      it_behaves_like 'percona-distro-packages'
    end
  else
    it_behaves_like 'mysql-packages'
  end

end

# this example checks for the percona packages
shared_examples 'percona-packages' do |params|
  it {
    case facts[:operatingsystem]
    when 'Ubuntu'
        mysql_server_name    = 'percona-xtradb-cluster-server-5.6'
        mysql_client_name    = 'percona-xtradb-cluster-client-5.6'
        libgalera_package    = 'percona-xtradb-cluster-galera-3.x'
    when 'CentOS'
        mysql_server_name    = 'Percona-XtraDB-Cluster-server-56'
        mysql_client_name    = 'Percona-XtraDB-Cluster-client-56'
        libgalera_package    = 'Percona-XtraDB-Cluster-galera-3'
    end
    should contain_package('MySQL-server').with_name(mysql_server_name)
    should contain_package('mysql-client').with_name(mysql_client_name)
    should contain_package('galera').with_name(libgalera_package)
  }
end

# this example checks for the percona packages
shared_examples 'percona-distro-packages' do |params|
  it {
    case facts[:operatingsystem]
    when 'Ubuntu'
        mysql_server_name    = 'percona-xtradb-cluster-server-5.5'
        mysql_client_name    = 'percona-xtradb-cluster-client-5.5'
        libgalera_package    = 'percona-xtradb-cluster-galera-2.x'
        should contain_package('MySQL-server').with_name(mysql_server_name)
        should contain_package('mysql-client').with_name(mysql_client_name)
        should contain_package('galera').with_name(libgalera_package)
    when 'CentOS'
        should raise_error(Puppet::Error, /Unsupported/)
    end
  }
end

# this example checks for the use of the mysql classes
shared_examples 'mysql-packages' do
  it {
    case facts[:operatingsystem]
    when 'Ubuntu'
        mysql_server_name    = 'mysql-server-wsrep-5.6'
        mysql_client_name    = 'mysql-client-5.6'
        libgalera_package    = 'galera'
        libaio_package       = 'libaio1'
    when 'CentOS'
        mysql_server_name    = 'MySQL-server-wsrep'
        mysql_client_name    = 'MySQL-client-wsrep'
        libgalera_package    = 'galera'
        libaio_package       = 'libaio'
    end
    should contain_package('MySQL-server').with_name(mysql_server_name)
    should contain_package('mysql-client').with_name(mysql_client_name)
    should contain_package('galera').with_name(libgalera_package)
    should contain_package(libaio_package)
  }
end

# this example checks for the expected services for the galera class
shared_examples 'test-services' do |params|
  params = {} if params.nil?

  p = {}.merge(params)

  let (:params) { p }

  it {
    should contain_service('mysql').with({
      'ensure'   => 'running',
      'name'     => 'p_mysql',
      'provider' => 'pacemaker'
    })
  }
end

# this example checks for the cluster resource definitions for a primary
# controller. This should probably not live in the galera class.
shared_examples 'test-primary-controller' do |params|
  params = {} if params.nil?

  p = {
    :primary_controller => false
  }.merge(params)

  let (:params) { p }

  it {
    if params[:primary_controller]
      should contain_cs_resource('p_mysql')
    else
      should_not contain_cs_resource('p_mysql')
    end
  }
end

# this example checks for the catalog items around the backup option
shared_examples 'test-backup' do |params|
  params = {} if params.nil?

  p = {
    :wsrep_sst_method => 'xtrabackup-v2',
  }.merge(params)

  let (:params) { p }

  if p.has_key?(:wsrep_sst_method) and ['xtrabackup', 'xtrabackup-v2'].include?(p[:wsrep_sst_method])
    it {
      should contain_firewall('101 xtrabackup').with_port(4444)
      should contain_package('percona-xtrabackup')
      should contain_file('/etc/mysql/conf.d/wsrep.cnf').with_content(/xtrabackup/)
    }
  else
    it {
      should_not contain_firewall('101 xtrabackup').with_port(4444)
      should_not contain_package('percona-xtrabackup')
      should_not contain_file('/etc/mysql/conf.d/wsrep.cnf').with_content(/xtrabackup/)
    }
  end
end

# vim: set ts=2 sw=2 et :
