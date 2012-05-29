require 'spec_helper'

describe 'keystone::client::authtoken' do

  let :facts do
    { :concat_basedir => '/var/lib/puppet/concat' }
  end

  let :title do
    '/tmp/foo'
  end

  let :pre_condition do
'
class { "concat::setup": }
concat { "/tmp/foo": }
'
  end

  let :fragment_path do
   '/var/lib/puppet/concat/_tmp_foo/fragments/80__tmp_foo_authtoken'
  end

  it { should include_class('keystone::python') }

  describe 'with default options' do
    it 'should use defaults to compile fragment template' do
# TODO why is this path wrong???
      verify_contents(subject, fragment_path,
        [
          '[filter:authtoken]',
          'paste.filter_factory = keystone.middleware.auth_token:filter_factory',
          'auth_host = 127.0.0.1',
          'auth_port = 3557',
          'auth_protocol = https',
          'auth_uri = https://127.0.0.1:3557',
          'admin_tenant_name = openstack',
          'admin_user = admin',
          'admin_password = ChangeMe',
          'delay_auth_decision = 0'
        ]
      )
    end
  end
  describe 'when overriding default parameters' do
    describe 'when overriding order' do
      let :params do
        { 'order' => '99'}
      end
      it { should contain_file('/var/lib/puppet/concat/_tmp_foo/fragments/99__tmp_foo_authtoken') }
    end
    describe 'when overriding host info' do
      let :params do
        {
          'auth_host'           => '10.0.0.1',
          'auth_port'           => '1234',
          'auth_protocol'       => 'http',
          'delay_auth_decision' => '1'
        }
      end
      it 'should override auth values' do
        verify_contents(subject, fragment_path,
          [
            'auth_host = 10.0.0.1',
            'auth_port = 1234',
            'auth_protocol = http',
            'auth_uri = http://10.0.0.1:1234',
            'delay_auth_decision = 1'
          ]
        )
      end
    end
    describe 'when overriding admin info' do
      let :params do
        {
          'admin_tenant_name'=> 'foo',
          'admin_user'       => 'bar',
          'admin_password'   => 'baz'
        }
      end
      it 'should override admin values' do
        verify_contents(subject, fragment_path,
          [
            'admin_tenant_name = foo',
            'admin_user = bar',
            'admin_password = baz'
          ]
        )
      end
    end
    describe 'when setting admin token' do
      let :params do
        {:admin_token => 'foo'}
      end
      it { should contain_file(fragment_path).with_content(/admin_token = foo/) }
      it 'should not contain admin options in the config' do
        content = param_value(subject, 'file', fragment_path, 'content')
        content.should_not =~ /admin_tenant_name/
        content.should_not =~ /admin_user/
        content.should_not =~ /admin_password/
      end
    end
  end

end
