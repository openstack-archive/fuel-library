require 'spec_helper'
describe 'swift::storage::object' do

  let :facts do
    {
      :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian'
    }
  end

  let :pre_condition do
    "class { 'ssh::server::install': }
     class { 'swift': swift_hash_suffix => 'foo' }
     class { 'swift::storage': storage_local_net_ip => '10.0.0.1' }"
  end

  let :default_params do
    {:package_ensure => 'present'}
  end

  [{},
   {:package_ensure => 'latest'}
  ].each do |param_set|
    describe "when #{param_set == {} ? "using default" : "specifying"} class parameters" do
      let :param_hash do
        default_params.merge(param_set)
      end
      let :params do
        param_set
      end
      it { should contain_swift__storage__generic('object').with_package_ensure(param_hash[:package_ensure]) }
    end
  end
end
