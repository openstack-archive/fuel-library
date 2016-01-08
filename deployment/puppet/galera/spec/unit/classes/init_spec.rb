require 'spec_helper.rb'
require 'shared-examples'

describe 'galera', :type => :class do
  context 'Defaults on CentOS' do
    let(:facts) { Facts.centos_facts }
    it_behaves_like 'galera-init'
  end
  context 'Defaults on Ubuntu' do
    let(:facts) { Facts.ubuntu_facts }
    it_behaves_like 'galera-init'
  end

  context 'Percona on CentOS' do
    let(:facts) { Facts.centos_facts }
    p = {
      :use_percona          => true,
      :use_percona_packages => false
    }
    # we only test compile and packages because this configuration should
    # result in a puppet error indicating no support
    it_behaves_like 'compile', p
    it_behaves_like 'test-packages', p
  end
  context 'Percona on Ubuntu' do
    let(:facts) { Facts.ubuntu_facts }
    p = {
      :use_percona          => true,
      :use_percona_packages => false
    }
    it_behaves_like 'galera-init', p

    # these are extra things that should be expected on Ubuntu to work around
    # the package installation on Ubuntu
    let(:params) { p }
    it {
      should contain_exec('rm-99tmp')
    }
  end

  context 'Percona Packages on CentOS' do
    let(:facts) { Facts.centos_facts }
    p = {
      :use_percona          => true,
      :use_percona_packages => true
    }
    it_behaves_like 'galera-init', p
  end
  context 'Percona Packages on Ubuntu' do
    let(:facts) { Facts.ubuntu_facts }
    p = {
      :use_percona          => true,
      :use_percona_packages => true
    }
    it_behaves_like 'galera-init', p

    # these are extra things that should be expected on Ubuntu to work around
    # the package installation on Ubuntu
    let(:params) { p }
    it {
      should contain_exec('rm-99tmp')
    }
  end

  context 'Primary Controller on CentOS' do
    let(:facts) { Facts.centos_facts }
    p = { :primary_controller => true }
    it_behaves_like 'galera-init', p
  end
  context 'Primary Controller on Ubuntu' do
    let(:facts) { Facts.ubuntu_facts }
    p = { :primary_controller => true }
    it_behaves_like 'galera-init', p
  end

  context 'wsrep_sst_method mysqldump on CentOS' do
    let(:facts) { Facts.centos_facts }
    p = { :wsrep_sst_method => 'undef' }
    it_behaves_like 'galera-init', p
  end
  context 'wsrep_sst_method mysqldump on Ubuntu' do
    let(:facts) { Facts.ubuntu_facts }
    p = { :wsrep_sst_method => 'mysqldump' }
    it_behaves_like 'galera-init', p
  end
end
# vim: set ts=2 sw=2 et :
