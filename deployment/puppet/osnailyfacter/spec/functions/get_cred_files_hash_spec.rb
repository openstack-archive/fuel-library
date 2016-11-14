require 'spec_helper'

describe 'get_cred_files_hash' do

  let (:common_cred_params) do
    {
     'admin_user'          => 'admin_user',
     'admin_password'      => 'admin_password',
     'admin_tenant'        => 'admin_tenant',
     'region_name'         => 'region',
     'auth_url'            => 'auth_url',
     'murano_repo_url'     => 'murano_repo_url',
     'murano_glare_plugin' => 'murano_glare_plugin'
    }
  end

  it 'should exist' do
    is_expected.not_to be_nil
  end

  context 'handle wrong values' do
    it 'should throw an error on invalid arguments number' do
      is_expected.to run.with_params(1, 2, 3).and_raise_error(ArgumentError)
    end

    it 'should raise an error if first invalid argument type is specified' do
      is_expected.to run.with_params('foo', {}).and_raise_error(Puppet::ParseError)
    end

    it 'should raise an error if second invalid argument type is specified' do
      is_expected.to run.with_params({}, 'foo').and_raise_error(Puppet::ParseError)
    end
  end

  context 'different home directories names' do
    let (:cred_users) do
      {
       '/root/openrc'           => 'root',
       '/home/fuel/openrc'      => 'fuel',
       '/home/fueladmin/openrc' => 'fueladmin'
      }
    end

    let (:result) do
      {
       '/root/openrc'           => common_cred_params.clone.update({"owner" => 'root',
                                                                    "group" => 'root'}),
       '/home/fuel/openrc'      => common_cred_params.clone.update({"owner" => 'fuel',
                                                                    "group" => 'fuel'}),
       '/home/fueladmin/openrc' => common_cred_params.clone.update({"owner" => 'fueladmin',
                                                                    "group" => 'fueladmin'})
      }
    end

    it 'should work with different home directories names' do
      is_expected.to run.with_params(cred_users, common_cred_params).and_return(result)
    end
  end

  context 'same home directories names' do
    let (:cred_users) do
      {
       '/root/openrc' => 'root',
       '/root/openrc' => 'root'
      }
    end

    let (:result) do
      {
       '/root/openrc' => common_cred_params.clone.update({"owner" => 'root',
                                                          "group" => 'root'})
      }
    end

    it 'should work with same home directories names' do
      is_expected.to run.with_params(cred_users, common_cred_params).and_return(result)
    end
  end

end
