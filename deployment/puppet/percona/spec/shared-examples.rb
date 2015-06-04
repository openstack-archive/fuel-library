shared_examples 'compile' do
  it do
    should compile
  end
end

shared_examples 'test-packages' do |peronca_packages|
  percona_packages = true if percona_packages.nil?
  p = {
    :use_percona_packages => percona_packages
  }
  let (:params) { p }
  if percona_packages
    it_behaves_like 'percona-packages'
  else
    it_behaves_like 'distro-packages'
  end
end

shared_examples 'percona-packages' do
  it do
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
  end
end

shared_examples 'distro-packages' do
  it do
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
  end
end

# vim: set ts=2 sw=2 et :
