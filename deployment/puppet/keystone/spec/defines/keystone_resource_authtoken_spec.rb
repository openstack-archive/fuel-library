require 'spec_helper'

describe 'keystone::resource::authtoken' do

  let (:title) { 'keystone_config' }

  let :required_params do
    { :username     => 'keystone',
      :password     => 'secret',
      :auth_url     => 'http://127.0.0.1:35357/',
      :project_name => 'services' }
  end

  shared_examples 'shared examples' do

    context 'with only required parameters' do
      let :params do
        required_params
      end

      it { is_expected.to contain_keystone_config('keystone_authtoken/username').with(
        :value  => 'keystone',
      )}

      it { is_expected.to contain_keystone_config('keystone_authtoken/user_id').with(
        :ensure => 'absent',
      )}

      it { is_expected.to contain_keystone_config('keystone_authtoken/password').with(
        :value  => 'secret',
        :secret => true,
      )}

      it { is_expected.to contain_keystone_config('keystone_authtoken/auth_plugin').with(
        :value  => 'password',
      )}

      it { is_expected.to contain_keystone_config('keystone_authtoken/auth_url').with(
        :value  => 'http://127.0.0.1:35357/',
      )}

      it { is_expected.to contain_keystone_config('keystone_authtoken/project_name').with(
        :value  => 'services',
      )}

      it { is_expected.to contain_keystone_config('keystone_authtoken/project_id').with(
        :ensure => 'absent',
      )}

      it { is_expected.to contain_keystone_config('keystone_authtoken/user_domain_name').with(
        :ensure => 'absent',
      )}

      it { is_expected.to contain_keystone_config('keystone_authtoken/project_domain_name').with(
        :ensure => 'absent',
      )}

      it { is_expected.to contain_keystone_config('keystone_authtoken/user_domain_id').with(
        :ensure => 'absent',
      )}

      it { is_expected.to contain_keystone_config('keystone_authtoken/project_domain_id').with(
        :ensure => 'absent',
      )}

      it { is_expected.to contain_keystone_config('keystone_authtoken/domain_name').with(
        :ensure => 'absent',
      )}

      it { is_expected.to contain_keystone_config('keystone_authtoken/domain_id').with(
        :ensure => 'absent',
      )}

      it { is_expected.to contain_keystone_config('keystone_authtoken/trust_id').with(
        :ensure => 'absent',
      )}

      it { is_expected.to contain_keystone_config('keystone_authtoken/cacert').with(
        :ensure => 'absent',
      )}

      it { is_expected.to contain_keystone_config('keystone_authtoken/cert').with(
        :ensure => 'absent',
      )}

      it { is_expected.to contain_keystone_config('keystone_authtoken/key').with(
        :ensure => 'absent',
      )}

      it { is_expected.to contain_keystone_config('keystone_authtoken/insecure').with(
        :value => 'false',
      )}

    end

    context 'when omitting a required parameter password' do
      let :params do
        required_params.delete(:password)
      end
      it { expect { is_expected.to raise_error(Puppet::Error) } }
    end

    context 'when specifying auth_url' do
      let :params do
        required_params.merge({:auth_url => 'https://host:11111/v3/'})
      end
      it { is_expected.to contain_keystone_config('keystone_authtoken/auth_url').with(
        :value  => 'https://host:11111/v3/',
      )}

    end

    context 'when specifying project and scope_domain' do
      let :params do
        required_params.merge({:domain_name => 'domain'})
      end
      it { expect { is_expected.to raise_error(Puppet::Error, 'Cannot specify both a project (project_name or project_id) and a domain (domain_name or domain_id)') } }
    end

    context 'when specifying neither project nor domain' do
      let :params do
        required_params.delete(:project_name)
      end
      it { expect { is_expected.to raise_error(Puppet::Error, 'Must specify either a project (project_name or project_id, for a project scoped token) or a domain (domain_name or domain_id, for a domain scoped token)') } }
    end

    context 'when specifying domain in name' do
      let :params do
        required_params.merge({
          :username            => 'keystone::userdomain',
          :project_name        => 'services::projdomain',
          :default_domain_name => 'shouldnotuse'
        })
      end
      it { is_expected.to contain_keystone_config('keystone_authtoken/user_domain_name').with(
        :value => 'userdomain',
      )}

      it { is_expected.to contain_keystone_config('keystone_authtoken/project_domain_name').with(
        :value => 'projdomain',
      )}

    end

    context 'when specifying domain in parameters' do
      let :params do
        required_params.merge({
          :username            => 'keystone::userdomain',
          :user_domain_name    => 'realuserdomain',
          :project_name        => 'services::projdomain',
          :project_domain_name => 'realprojectdomain',
          :default_domain_name => 'shouldnotuse'
        })
      end
      it { is_expected.to contain_keystone_config('keystone_authtoken/user_domain_name').with(
        :value => 'realuserdomain',
      )}

      it { is_expected.to contain_keystone_config('keystone_authtoken/project_domain_name').with(
        :value => 'realprojectdomain',
      )}

    end

    context 'when specifying only default domain' do
      let :params do
        required_params.merge({
          :default_domain_name => 'defaultdomain'
        })
      end
      it { is_expected.to contain_keystone_config('keystone_authtoken/user_domain_name').with(
        :value => 'defaultdomain',
      )}

      it { is_expected.to contain_keystone_config('keystone_authtoken/project_domain_name').with(
        :value => 'defaultdomain',
      )}

    end

  end

  context 'on a Debian osfamily' do
    let :facts do
      { :osfamily => "Debian" }
    end

    include_examples 'shared examples'
  end

  context 'on a RedHat osfamily' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    include_examples 'shared examples'
  end
end
