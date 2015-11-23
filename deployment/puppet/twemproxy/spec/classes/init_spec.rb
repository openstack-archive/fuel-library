require 'spec_helper'

describe 'twemproxy' do

  let :facts do
    {
      # I hate doing such shit
      :concat_basedir => '/tmp'
    }
  end

  let(:default_params) { {:clients_array => [
                                     '10.10.10.10:11211:1',
                                     '10.10.10.20:11211:1',
                                    ],
               } }

  context 'with defaults for all parameters' do

    let :params do
      default_params
    end

    it "should inherit tewmproxy::params somehow" do
      should contain_class('twemproxy::params')
    end

    it "shoud compile with minimum of additional parameters" do
      should contain_class('twemproxy').with(
        'clients_array' => [
                            '10.10.10.10:11211:1',
                            '10.10.10.20:11211:1',
                           ],
      )
    end

    it "should call tewmproxy::install and install package twemproxy" do
      should contain_class('twemproxy::install')
      should contain_package('twemproxy').with(
        'ensure' => 'present',
      )
    end

    it "should call tewmproxy::config with configuration file" do
      should contain_class('twemproxy::config')
      should contain_file('/etc/default/twemproxy')
    end

    it "should call tewmproxy::service and enable it" do
      should contain_class('twemproxy::service')
      should contain_service('twemproxy').with(
        'ensure' => 'running',
        'enable' => true,
        'name'   => 'twemproxy',
      )
    end
  end


  context 'with non-standard parameters for package manage' do
    let :params do
      default_params.merge({
        :package_manage => false,
      })
    end

    it 'should not manage package if package_manage is false' do
      should contain_class('twemproxy::install')
      should_not contain_package('twemproxy').with(
        'ensure' => 'present',
      )
    end

    it 'should not manage package configuration if package_manage is false' do
      should contain_class('twemproxy::config')
    end

    let :params do
      default_params.merge({
        :package_manage => true,
        :package_name   => 'new_twemproxy',
        :package_ensure => 'absent',
      })
    end

    it 'should manage package with non-standard name' do
      should contain_class('twemproxy::install')
      should contain_package('new_twemproxy').with(
        'ensure' => 'absent',
      )
      should_not contain_package('twemproxy')
    end
  end


  context 'with non-standard parameters for service manage' do
    let :params do
      default_params.merge({
        :service_manage => false,
      })
    end

    it 'should not manage service if service_manage is false' do
      should contain_class('twemproxy::service')
      should_not contain_service('twemproxy').with(
        'ensure' => 'running',
      )
    end

    let :params do
      default_params.merge({
        :service_manage => true,
        :service_name   => 'new_twemproxy',
        :service_ensure => 'stopped',
      })
    end

    it 'should manage service with non-standard name' do
      should contain_class('twemproxy::service')
      should contain_service('new_twemproxy').with(
        'ensure' => 'stopped',
      )
      should_not contain_service('twemproxy')
    end
  end

end
