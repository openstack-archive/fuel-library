require 'spec_helper'

describe 'openstacklib::db::mysql' do

  let :pre_condition do
    'include mysql::server'
  end

  let (:title) { 'nova' }

  let :required_params do
    { :password_hash => 'AA1420F182E88B9E5F874F6FBE7459291E8F4601' }
  end

  shared_examples 'openstacklib::db::mysql examples' do

    context 'with only required parameters' do
      let :params do
        required_params
      end

      it { is_expected.to contain_mysql_database(title).with(
        :charset => 'utf8',
        :collate => 'utf8_general_ci'
      )}
      it { is_expected.to contain_openstacklib__db__mysql__host_access("#{title}_127.0.0.1").with(
        :user       => title,
        :database   => title,
        :privileges => 'ALL'
      )}
    end

    context 'with overriding dbname parameter' do
      let :params do
        { :dbname => 'foobar' }.merge(required_params)
      end

      it { is_expected.to contain_mysql_database(params[:dbname]).with(
        :charset => 'utf8',
        :collate => 'utf8_general_ci'
      )}
      it { is_expected.to contain_openstacklib__db__mysql__host_access("#{params[:dbname]}_127.0.0.1").with(
        :user       => title,
        :database   => params[:dbname],
        :privileges => 'ALL'
      )}
    end

    context 'with overriding user parameter' do
      let :params do
        { :user => 'foobar' }.merge(required_params)
      end

      it { is_expected.to contain_mysql_database(title).with(
        :charset => 'utf8',
        :collate => 'utf8_general_ci'
      )}
      it { is_expected.to contain_openstacklib__db__mysql__host_access("#{title}_127.0.0.1").with(
        :user       => params[:user],
        :database   => title,
        :privileges => 'ALL',
      )}
    end

    context 'when overriding charset parameter' do
      let :params do
        { :charset => 'latin1' }.merge(required_params)
      end

      it { is_expected.to contain_mysql_database(title).with_charset(params[:charset]) }
    end

    context 'when omitting the required parameter password_hash' do
      let :params do
        required_params.delete(:password_hash)
      end
      it { expect { is_expected.to raise_error(Puppet::Error) } }
    end

    context 'when notifying other resources' do
      let :pre_condition do
        'exec {"nova-db-sync":}'
      end
      let :params do
        { :notify => 'Exec[nova-db-sync]'}.merge(required_params)
      end

      it { is_expected.to contain_exec('nova-db-sync').that_subscribes_to("Openstacklib::Db::Mysql[#{title}]") }
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

      it { is_expected.to contain_service('keystone').that_requires("Openstacklib::Db::Mysql[keystone]") }
    end

    context "overriding allowed_hosts parameter with array value" do
      let :params do
        { :allowed_hosts  => ['127.0.0.1','%'] }.merge(required_params)
      end

      it {is_expected.to contain_openstacklib__db__mysql__host_access("#{title}_127.0.0.1").with(
        :user          => title,
        :password_hash => params[:password_hash],
        :database      => title
      )}
      it {is_expected.to contain_openstacklib__db__mysql__host_access("#{title}_%").with(
        :user          => title,
        :password_hash => params[:password_hash],
        :database      => title
      )}
    end

    context "overriding allowed_hosts parameter with string value" do
      let :params do
        { :allowed_hosts => '192.168.1.1' }.merge(required_params)
      end

      it {is_expected.to contain_openstacklib__db__mysql__host_access("#{title}_192.168.1.1").with(
        :user          => title,
        :password_hash => params[:password_hash],
        :database      => title
      )}
    end

    context "overriding allowed_hosts parameter equals to host param " do
      let :params do
        { :allowed_hosts => '127.0.0.1' }.merge(required_params)
      end

      it {is_expected.to contain_openstacklib__db__mysql__host_access("#{title}_127.0.0.1").with(
        :user          => title,
        :password_hash => params[:password_hash],
        :database      => title
      )}
    end

  end

  context 'on a Debian osfamily' do
    let :facts do
      { :osfamily => "Debian" }
    end

    include_examples 'openstacklib::db::mysql examples'
  end

  context 'on a RedHat osfamily' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    include_examples 'openstacklib::db::mysql examples'
  end
end
