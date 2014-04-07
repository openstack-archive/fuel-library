require 'spec_helper'

describe 'keystone::ldap' do

  describe 'with default params' do

    it 'should contain default params' do

      should contain_keystone_config('ldap/url').with_value('ldap://localhost')
      should contain_keystone_config('ldap/user').with_value('dc=Manager,dc=example,dc=com')
      should contain_keystone_config('ldap/password').with_value('None')
      should contain_keystone_config('ldap/suffix').with_value('cn=example,cn=com')
      should contain_keystone_config('ldap/user_tree_dn').with_value('ou=Users,dc=example,dc=com')
      should contain_keystone_config('ldap/tenant_tree_dn').with_value('ou=Roles,dc=example,dc=com')
      should contain_keystone_config('ldap/role_tree_dn').with_value('dc=example,dc=com')
    end

  end

end
