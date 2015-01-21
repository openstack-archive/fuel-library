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

      should contain_keystone_user('cinder').with(
        :ensure   => 'present',
        :password => 'pw',
        :email    => 'cinder@localhost',
        :tenant   => 'services'
      )
      should contain_keystone_user_role('cinder@services').with(
        :ensure  => 'present',
        :roles   => 'admin'
      )
      should contain_keystone_service('cinder').with(
        :ensure      => 'present',
        :type        => 'volume',
        :description => 'Cinder Service'
      )
      should contain_keystone_service('cinderv2').with(
        :ensure      => 'present',
        :type        => 'volumev2',
        :description => 'Cinder Service v2'
      )

    end
    it { should contain_keystone_endpoint('RegionOne/cinder').with(
      :ensure       => 'present',
      :public_url   => 'http://127.0.0.1:8776/v1/%(tenant_id)s',
      :admin_url    => 'http://127.0.0.1:8776/v1/%(tenant_id)s',
      :internal_url => 'http://127.0.0.1:8776/v1/%(tenant_id)s'
    ) }
    it { should contain_keystone_endpoint('RegionOne/cinderv2').with(
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

    it { should contain_keystone_endpoint('RegionThree/cinder').with(
      :ensure       => 'present',
      :public_url   => 'https://10.0.42.1:4242/v42/%(tenant_id)s',
      :admin_url    => 'https://10.0.42.2:4242/v42/%(tenant_id)s',
      :internal_url => 'https://10.0.42.3:4242/v42/%(tenant_id)s'
    )}

    it { should contain_keystone_endpoint('RegionThree/cinderv2').with(
      :ensure       => 'present',
      :public_url   => 'https://10.0.42.1:4242/v2/%(tenant_id)s',
      :admin_url    => 'https://10.0.42.2:4242/v2/%(tenant_id)s',
      :internal_url => 'https://10.0.42.3:4242/v2/%(tenant_id)s'
    )}
  end


  describe 'when endpoint should not be configured' do
    let :params do
      req_params.merge(
        :configure_endpoint    => false,
        :configure_endpoint_v2 => false
      )
    end
    it { should_not contain_keystone_endpoint('RegionOne/cinder') }
    it { should_not contain_keystone_endpoint('RegionOne/cinderv2') }
  end

  describe 'when user should not be configured' do
    let :params do
      req_params.merge(
        :configure_user => false
      )
    end

    it { should_not contain_keystone_user('cinder') }

    it { should contain_keystone_user_role('cinder@services') }

    it { should contain_keystone_service('cinder').with(
        :ensure      => 'present',
        :type        => 'volume',
        :description => 'Cinder Service'
    ) }

  end

  describe 'when user and user role should not be configured' do
    let :params do
      req_params.merge(
        :configure_user      => false,
        :configure_user_role => false
      )
    end

    it { should_not contain_keystone_user('cinder') }

    it { should_not contain_keystone_user_role('cinder@services') }

    it { should contain_keystone_service('cinder').with(
        :ensure      => 'present',
        :type        => 'volume',
        :description => 'Cinder Service'
    ) }

  end

end
