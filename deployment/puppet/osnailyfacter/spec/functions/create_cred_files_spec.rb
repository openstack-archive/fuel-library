require 'spec_helper'

describe 'create_cred_files' do

  let (:cred_users) do
    {'/root/openrc'    => 'root',
     '/home/fuel'      => 'fuel',
     '/home/fueladmin' => 'fueladmin'}
  end

  let (:common_cred_params) do
    {'admin_user'          => 'admin_user',
     'admin_password'      => 'admin_password',
     'admin_tenant'        => 'admin_tenant',
     'region_name'         => 'region',
     'auth_url'            => 'auth_url',
     'murano_repo_url'     => 'murano_repo_url',
     'murano_glare_plugin' => 'murano_glare_plugin'}
  end

  let (:parameters) do
    {'/root/openrc'    => common_cred_params.update({"owner" => 'root',
                                                     "group" => 'root'}),
     '/home/fuel'      => common_cred_params.update({"owner" => 'fuel',
                                                     "group" => 'fuel'}),
     '/home/fueladmin' => common_cred_params.update({"owner" => 'fueladmin',
                                                     "group" => 'fueladmin'})
    }
  end

  it 'should exist' do
    is_expected.not_to be_nil
  end

  it 'should throw an error on invalid arguments number' do
    is_expected.to run.with_params(1, 2, 3).and_raise_error(ArgumentError)
  end

  it 'should raise an error if first invalid argument type is specified' do
    is_expected.to run.with_params('foo', {}).and_raise_error(Puppet::ParseError)
  end

  it 'should raise an error if second invalid argument type is specified' do
    is_expected.to run.with_params({}, 'foo').and_raise_error(Puppet::ParseError)
  end

  before(:each) do
    scope.stubs(:function_create_resources)
    scope.stubs(:call_function).with('get_network_role_property').with(['osnailyfacter::credentials_file', parameters])
  end

end
