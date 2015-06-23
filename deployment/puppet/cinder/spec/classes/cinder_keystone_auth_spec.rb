require 'spec_helper'

describe 'cinder::keystone::auth' do

  let :req_params do
    {:password => 'pw'}
  end

  describe 'with only required params' do

    let :params do
      req_params
    end

    it 'should contain auth info' do

      is_expected.to contain_keystone_user('cinder').with(
        :ensure   => 'present',
        :password => 'pw',
        :email    => 'cinder@localhost',
        :tenant   => 'services'
      )
      is_expected.to contain_keystone_user_role('cinder@services').with(
        :ensure  => 'present',
        :roles   => ['admin']
      )
      is_expected.to contain_keystone_service('cinder').with(
        :ensure      => 'present',
        :type        => 'volume',
        :description => 'Cinder Service'
      )
      is_expected.to contain_keystone_service('cinderv2').with(
        :ensure      => 'present',
        :type        => 'volumev2',
        :description => 'Cinder Service v2'
      )

    end
    it { is_expected.to contain_keystone_endpoint('RegionOne/cinder').with(
      :ensure       => 'present',
      :public_url   => 'http://127.0.0.1:8776/v1/%(tenant_id)s',
      :admin_url    => 'http://127.0.0.1:8776/v1/%(tenant_id)s',
      :internal_url => 'http://127.0.0.1:8776/v1/%(tenant_id)s'
    ) }
    it { is_expected.to contain_keystone_endpoint('RegionOne/cinderv2').with(
      :ensure       => 'present',
      :public_url   => 'http://127.0.0.1:8776/v2/%(tenant_id)s',
      :admin_url    => 'http://127.0.0.1:8776/v2/%(tenant_id)s',
      :internal_url => 'http://127.0.0.1:8776/v2/%(tenant_id)s'
    ) }

  end

  context 'when overriding endpoint params' do
     let :params do
       req_params.merge(
        :public_address    => '10.0.42.1',
        :admin_address     => '10.0.42.2',
        :internal_address  => '10.0.42.3',
        :region            => 'RegionThree',
        :port              => '4242',
        :admin_protocol    => 'https',
        :internal_protocol => 'https',
        :public_protocol   => 'https',
        :volume_version    => 'v42'
      )
     end

    it { is_expected.to contain_keystone_endpoint('RegionThree/cinder').with(
      :ensure       => 'present',
      :public_url   => 'https://10.0.42.1:4242/v42/%(tenant_id)s',
      :admin_url    => 'https://10.0.42.2:4242/v42/%(tenant_id)s',
      :internal_url => 'https://10.0.42.3:4242/v42/%(tenant_id)s'
    )}

    it { is_expected.to contain_keystone_endpoint('RegionThree/cinderv2').with(
      :ensure       => 'present',
      :public_url   => 'https://10.0.42.1:4242/v2/%(tenant_id)s',
      :admin_url    => 'https://10.0.42.2:4242/v2/%(tenant_id)s',
      :internal_url => 'https://10.0.42.3:4242/v2/%(tenant_id)s'
    )}
  end


  describe 'when endpoint is_expected.to not be configured' do
    let :params do
      req_params.merge(
        :configure_endpoint    => false,
        :configure_endpoint_v2 => false
      )
    end
    it { is_expected.to_not contain_keystone_endpoint('RegionOne/cinder') }
    it { is_expected.to_not contain_keystone_endpoint('RegionOne/cinderv2') }
  end

  describe 'when user is_expected.to not be configured' do
    let :params do
      req_params.merge(
        :configure_user => false
      )
    end

    it { is_expected.to_not contain_keystone_user('cinder') }

    it { is_expected.to contain_keystone_user_role('cinder@services') }

    it { is_expected.to contain_keystone_service('cinder').with(
        :ensure      => 'present',
        :type        => 'volume',
        :description => 'Cinder Service'
    ) }

  end

  describe 'when user and user role is_expected.to not be configured' do
    let :params do
      req_params.merge(
        :configure_user      => false,
        :configure_user_role => false
      )
    end

    it { is_expected.to_not contain_keystone_user('cinder') }

    it { is_expected.to_not contain_keystone_user_role('cinder@services') }

    it { is_expected.to contain_keystone_service('cinder').with(
        :ensure      => 'present',
        :type        => 'volume',
        :description => 'Cinder Service'
    ) }

  end

  describe 'when overriding service names' do

    let :params do
      req_params.merge(
        :service_name    => 'cinder_service',
        :service_name_v2 => 'cinder_service_v2',
      )
    end

    it { should contain_keystone_user('cinder') }
    it { should contain_keystone_user_role('cinder@services') }
    it { should contain_keystone_service('cinder_service') }
    it { should contain_keystone_service('cinder_service_v2') }
    it { should contain_keystone_endpoint('RegionOne/cinder_service') }
    it { should contain_keystone_endpoint('RegionOne/cinder_service_v2') }

  end

end
