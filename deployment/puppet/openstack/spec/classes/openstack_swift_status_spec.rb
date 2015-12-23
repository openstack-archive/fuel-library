require 'spec_helper'

describe 'openstack::swift::status' do

  let(:default_params) do
    {
      :address     => '0.0.0.0',
      :only_from   => '127.0.0.1',
      :port        => '49001',
      :endpoint    => 'http://127.0.0.1:8080',
      :scan_target => '127.0.0.1:5000',
      :con_timeout => '5',
    }
  end

  let :params do
    { }
  end

  shared_examples_for 'swift status configuration' do

    context 'with default params' do
      it 'contains xinetd::service' do
        group = case facts[:osfamily]
          when 'RedHat' then 'nobody'
          when 'Debian' then 'nogroup'
          else'nobody'
        end

        server_args = "#{default_params[:endpoint]} #{default_params[:scan_target]} #{default_params[:con_timeout]}"

        is_expected.to contain_xinetd__service('swiftcheck').with(
          {
            'bind'        => default_params[:address],
            'port'        => default_params[:port],
            'only_from'   => default_params[:only_from],
            'cps'         => '512 10',
            'per_source'  => 'UNLIMITED',
            'server'      => '/usr/bin/swiftcheck',
            'server_args' => server_args,
            'user'        => 'nobody',
            'group'       => group,
            'flags'       => 'IPv4',
          }
        ).that_requires('Augeas[swiftcheck]')
      end

      it 'configures (modifies) the /etc/services' do
        port = default_params[:port]
        is_expected.to contain_augeas('swiftcheck').with(
          'context' => '/files/etc/services',
          'changes' => [
            "set /files/etc/services/service-name[port = '#{port}']/port #{port}",
            "set /files/etc/services/service-name[port = '#{port}'] swiftcheck",
            "set /files/etc/services/service-name[port = '#{port}']/protocol tcp",
            "set /files/etc/services/service-name[port = '#{port}']/#comment 'Swift Health Check'",
          ],
        )
      end
    end

    context 'with overriding class parameters' do
      before do
        params.merge!(
          :address     => '100.41.52.5',
          :only_from   => '100.70.123.1',
          :port        => '49009',
          :endpoint    => 'http://193.1.6.88:8080',
          :scan_target => '193.44.2.66:5000',
          :con_timeout => '3',
        )
      end

      it 'contains xinetd::service' do
        server_args = "#{params[:endpoint]} #{params[:scan_target]} #{params[:con_timeout]}"

        is_expected.to contain_xinetd__service('swiftcheck').with(
          {
            'bind'        => params[:address],
            'port'        => params[:port],
            'only_from'   => params[:only_from],
            'cps'         => '512 10',
            'per_source'  => 'UNLIMITED',
            'server'      => '/usr/bin/swiftcheck',
            'server_args' => server_args,
            'user'        => 'nobody',
            'flags'       => 'IPv4',
          }
        )
      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      {
        :osfamily => 'Debian',
        :operatingsystem => 'Debian',
        :hostname => 'hostname.example.com',
      }
    end

    it_configures 'swift status configuration'
  end

  context 'on RedHat platforms' do
    let :facts do
      {
        :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
        :hostname => 'hostname.example.com',
      }
    end

    it_configures 'swift status configuration'
  end

end

