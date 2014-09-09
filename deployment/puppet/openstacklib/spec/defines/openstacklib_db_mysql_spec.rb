require 'spec_helper'

describe 'openstacklib::db::mysql' do

  let :pre_condition do
    'include mysql::server'
  end

  password_hash = 'AA1420F182E88B9E5F874F6FBE7459291E8F4601'
  let :required_params do
    { :password_hash => password_hash }
  end

  title = 'nova'
  let (:title) { title }
  context 'on a Debian osfamily' do
    let :facts do
      { :osfamily => "Debian" }
    end

    context 'with only required parameters' do
      let :params do
        required_params
      end

      it { should contain_mysql_database(title).with(
        :charset => 'utf8',
        :collate => 'utf8_unicode_ci'
      )}
      it { should contain_mysql_user("#{title}@127.0.0.1").with(
        :password_hash => password_hash
      )}
      it { should contain_mysql_grant("#{title}@127.0.0.1/#{title}.*").with(
        :user       => "#{title}@127.0.0.1",
        :privileges => 'ALL',
        :table      => "#{title}.*"
      )}
    end

    context 'when overriding charset' do
      let :params do
        { :charset => 'latin1' }.merge(required_params)
      end

      it { should contain_mysql_database(title).with_charset(params[:charset]) }
    end

    context 'when omitting the required parameter password_hash' do
      let :params do
        required_params.delete(:password_hash)
      end
      it { expect { should raise_error(Puppet::Error) } }
    end

    context 'when notifying other resources' do
      let :pre_condition do
        'exec {"nova-db-sync":}'
      end
      let :params do
        { :notify => 'Exec[nova-db-sync]'}.merge(required_params)
      end

      it { should contain_exec('nova-db-sync').that_subscribes_to("Openstacklib::Db::Mysql[#{title}]") }
    end

    context 'when required for other openstack services' do
      let :pre_condition do
        'service {"keystone":}'
      end
      let :title do
        'keystone'
      end
      let :params do
        { :before => 'Service[keystone]'}.merge(required_params)
      end

      it { should contain_service('keystone').that_requires("Openstacklib::Db::Mysql[keystone]") }
    end

    context "overriding allowed_hosts param to array" do
      let :params do
        { :allowed_hosts  => ['127.0.0.1','%'] }.merge(required_params)
      end

      it {should_not contain_openstacklib__db__mysql__host_access("#{title}_127.0.0.1").with(
        :user          => title,
        :password_hash => password_hash,
        :database      => title
      )}
      it {should contain_openstacklib__db__mysql__host_access("#{title}_%").with(
        :user          => title,
        :password_hash => password_hash,
        :database      => title
      )}
    end

    context "overriding allowed_hosts param to string" do
      let :params do
        {
          :password_hash => password_hash,
          :allowed_hosts => '192.168.1.1'
        }
      end

      it {should contain_openstacklib__db__mysql__host_access("#{title}_192.168.1.1").with(
        :user          => title,
        :password_hash => password_hash,
        :database      => title
      )}
    end

    context "overriding allowed_hosts param equals to host param " do
      let :params do
        {
          :password_hash => password_hash,
          :allowed_hosts => '127.0.0.1'
        }
      end

      it {should_not contain_openstacklib__db__mysql__host_access("#{title}_127.0.0.1").with(
        :user          => title,
        :password_hash => password_hash,
        :database      => title
      )}
    end
  end

  context 'on a RedHat osfamily' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    context 'with only required parameters' do
      let :params do
        required_params
      end

      it { should contain_mysql_database(title).with(
        :charset => 'utf8',
        :collate => 'utf8_unicode_ci'
      )}
      it { should contain_mysql_user("#{title}@127.0.0.1").with(
        :password_hash => password_hash
      )}
      it { should contain_mysql_grant("#{title}@127.0.0.1/#{title}.*").with(
        :user       => "#{title}@127.0.0.1",
        :privileges => 'ALL',
        :table      => "#{title}.*"
      )}
    end

    context 'when overriding charset' do
      let :params do
        { :charset => 'latin1' }.merge(required_params)
      end

      it { should contain_mysql_database(title).with_charset(params[:charset]) }
    end

    context 'when omitting the required parameter password' do
      let :params do
        required_params.delete(:password)
      end
      it { expect { should raise_error(Puppet::Error) } }
    end

    context 'when notifying other resources' do
      let(:pre_condition) { 'exec {"nova-db-sync":}' }
      let(:params) { { :notify => 'Exec[nova-db-sync]'}.merge(required_params) }

      it { should contain_exec('nova-db-sync').that_subscribes_to("Openstacklib::Db::Mysql[#{title}]") }
    end

    context 'when required for other openstack services' do
      let(:pre_condition) { 'service {"keystone":}' }
      let(:title) { 'keystone' }
      let(:params) { { :before => 'Service[keystone]'}.merge(required_params) }

      it { should contain_service('keystone').that_requires("Openstacklib::Db::Mysql[keystone]") }
    end

    context "overriding allowed_hosts param to array" do
      let :params do
        { :allowed_hosts  => ['127.0.0.1','%'] }.merge(required_params)
      end

      it {should_not contain_openstacklib__db__mysql__host_access("#{title}_127.0.0.1").with(
        :user          => title,
        :password_hash => password_hash,
        :database      => title
      )}
      it {should contain_openstacklib__db__mysql__host_access("#{title}_%").with(
        :user          => title,
        :password_hash => password_hash,
        :database      => title
      )}
    end

    context "overriding allowed_hosts param to string" do
      let :params do
        {
          :password_hash  => password_hash,
          :allowed_hosts  => '192.168.1.1'
        }
      end

      it {should contain_openstacklib__db__mysql__host_access("#{title}_192.168.1.1").with(
        :user          => title,
        :password_hash => password_hash,
        :database      => title
      )}
    end

    context "overriding allowed_hosts param equals to host param " do
      let :params do
        {
          :password_hash => password_hash,
          :allowed_hosts => '127.0.0.1'
        }
      end

      it {should_not contain_openstacklib__db__mysql__host_access("#{title}_127.0.0.1").with(
        :user          => title,
        :password_hash => password_hash,
        :database      => title
      )}
    end
  end
end
