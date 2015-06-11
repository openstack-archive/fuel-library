require 'spec_helper'

describe 'openstacklib::db::postgresql' do
  password_hash = 'AA1420F182E88B9E5F874F6FBE7459291E8F4601'
  title = 'nova'
  let (:title) { title }

  let :required_params do
    { :password_hash => password_hash }
  end

  context 'on a RedHat osfamily' do
    let :facts do
      {
        :postgres_default_version => '8.4',
        :osfamily => 'RedHat'
      }
    end

    context 'with only required parameters' do
      let :params do
        required_params
      end

      it { is_expected.to contain_postgresql__server__db(title).with(
        :user     => title,
        :password => password_hash
      )}
    end

    context 'when overriding encoding' do
      let :params do
        { :encoding => 'latin1' }.merge(required_params)
      end
      it { is_expected.to contain_postgresql__server__db(title).with_encoding(params[:encoding]) }
    end

    context 'when omitting the required parameter password_hash' do
      let :params do
        required_params.delete(:password_hash)
      end

      it { expect { is_expected.to raise_error(Puppet::Error) } }
    end

    context 'when notifying other resources' do
      let :pre_condition do
        'exec { "nova-db-sync": }'
      end
      let :params do
        { :notify => 'Exec[nova-db-sync]'}.merge(required_params)
      end

      it {is_expected.to contain_exec('nova-db-sync').that_subscribes_to("Openstacklib::Db::Postgresql[#{title}]") }
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

      it { is_expected.to contain_service('keystone').that_requires("Openstacklib::Db::Postgresql[keystone]") }
    end

  end

  context 'on a Debian osfamily' do
    let :facts do
      {
        :osfamily => 'Debian'
      }
    end

    context 'with only required parameters' do
      let :params do
        required_params
      end

      it { is_expected.to contain_postgresql__server__db(title).with(
        :user     => title,
        :password => password_hash
      )}
    end

    context 'when overriding encoding' do
      let :params do
        { :encoding => 'latin1' }.merge(required_params)
      end
      it { is_expected.to contain_postgresql__server__db(title).with_encoding(params[:encoding]) }
    end

    context 'when omitting the required parameter password_hash' do
      let :params do
        required_params.delete(:password_hash)
      end

      it { expect { is_expected.to raise_error(Puppet::Error) } }
    end

    context 'when notifying other resources' do
      let :pre_condition do
        'exec { "nova-db-sync": }'
      end
      let :params do
        { :notify => 'Exec[nova-db-sync]'}.merge(required_params)
      end

      it {is_expected.to contain_exec('nova-db-sync').that_subscribes_to("Openstacklib::Db::Postgresql[#{title}]") }
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

      it { is_expected.to contain_service('keystone').that_requires("Openstacklib::Db::Postgresql[keystone]") }
    end

  end

end
