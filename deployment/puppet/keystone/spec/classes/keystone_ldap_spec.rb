require 'spec_helper'

describe 'keystone::ldap' do
  describe 'with basic params' do
    let :params do 
      {
        :url => 'ldap://foo',
        :user => 'cn=foo,dc=example,dc=com',
        :password => 'abcdefg',
        :suffix => 'dc=example,dc=com',
        :query_scope => 'sub',
        :page_size => '50',
        :user_tree_dn => 'cn=users,dc=example,dc=com',
        :user_filter => '(memberOf=cn=openstack,cn=groups,cn=accounts,dc=example,dc=com)',
        :user_objectclass => 'inetUser',
        :user_id_attribute => 'uid',
        :user_name_attribute => 'cn',
        :user_mail_attribute => 'mail',
        :user_enabled_attribute => 'UserAccountControl',
        :user_enabled_mask => '2',
        :user_enabled_default => '512',
        :user_attribute_ignore => '',
        :user_default_project_id_attribute => 'defaultProject',
        :user_allow_create => 'False',
        :user_allow_update => 'False',
        :user_allow_delete => 'False',
        :user_pass_attribute => 'krbPassword',
        :user_enabled_emulation => 'True',
        :user_enabled_emulation_dn => 'cn=openstack-enabled,cn=groups,cn=accounts,dc=example,dc=com',
        :user_additional_attribute_mapping => 'description:name, gecos:name',
        :tenant_tree_dn => 'ou=projects,ou=openstack,dc=example,dc=com',
        :tenant_filter => '',
        :tenant_objectclass => 'organizationalUnit',
        :tenant_id_attribute => 'ou',
        :tenant_member_attribute => 'member',
        :tenant_desc_attribute => 'description',
        :tenant_name_attribute => 'ou', 
        :tenant_enabled_attribute => 'enabled',
        :tenant_domain_id_attribute => 'businessCategory',
        :tenant_attribute_ignore => '',
        :tenant_allow_create => 'True',
        :tenant_allow_update => 'True',
        :tenant_allow_delete => 'True',
        :tenant_enabled_emulation => 'False',
        :tenant_enabled_emulation_dn => 'True',
        :tenant_additional_attribute_mapping => 'cn=enabled,ou=openstack,dc=example,dc=com',
        :role_tree_dn => 'ou=roles,ou=openstack,dc=example,dc=com',
        :role_filter => '',
        :role_objectclass => 'organizationalRole',
        :role_id_attribute => 'cn',
        :role_name_attribute => 'ou',
        :role_member_attribute => 'roleOccupant',
        :role_attribute_ignore => 'description',
        :role_allow_create => 'True',
        :role_allow_update => 'True',
        :role_allow_delete => 'True',
        :role_additional_attribute_mapping => '',
        :group_tree_dn => 'ou=groups,ou=openstack,dc=example,dc=com',
        :group_filter => 'cn=enabled-groups,cn=groups,cn=accounts,dc=example,dc=com',
        :group_objectclass => 'organizationalRole',
        :group_id_attribute => 'cn',
        :group_name_attribute => 'cn',
        :group_member_attribute => 'roleOccupant',
        :group_desc_attribute => 'description',
        :group_attribute_ignore => '',
        :group_allow_create => 'False',
        :group_allow_update => 'False',
        :group_allow_delete => 'False',
        :group_additional_attribute_mapping => '',
        :use_tls => 'False',
        :tls_cacertdir => '/etc/ssl/certs/',
        :tls_cacertfile => '/etc/ssl/certs/ca-certificates.crt',
        :tls_req_cert => 'demand',
        :identity_driver => 'keystone.identity.backends.ldap.Identity',
        :assignment_driver => 'keystone.assignment.backends.ldap.Assignment',
      }
    end
    it { should contain_package('python-ldap') }
    it 'should have basic params' do
      should contain_keystone_config('ldap/url').with_value('ldap://foo')
      should contain_keystone_config('ldap/user').with_value('cn=foo,dc=example,dc=com')
      should contain_keystone_config('ldap/password').with_value('abcdefg').with_secret(true)
      should contain_keystone_config('ldap/suffix').with_value('dc=example,dc=com')
      should contain_keystone_config('ldap/query_scope').with_value('sub')
      should contain_keystone_config('ldap/page_size').with_value('50')

      should contain_keystone_config('ldap/user_tree_dn').with_value('cn=users,dc=example,dc=com')
      should contain_keystone_config('ldap/user_filter').with_value('(memberOf=cn=openstack,cn=groups,cn=accounts,dc=example,dc=com)')
      should contain_keystone_config('ldap/user_objectclass').with_value('inetUser')
      should contain_keystone_config('ldap/user_id_attribute').with_value('uid')
      should contain_keystone_config('ldap/user_name_attribute').with_value('cn')
      should contain_keystone_config('ldap/user_mail_attribute').with_value('mail')
      should contain_keystone_config('ldap/user_enabled_attribute').with_value('UserAccountControl')
      should contain_keystone_config('ldap/user_enabled_mask').with_value('2')
      should contain_keystone_config('ldap/user_enabled_default').with_value('512')
      should contain_keystone_config('ldap/user_attribute_ignore').with_value('')
      should contain_keystone_config('ldap/user_default_project_id_attribute').with_value('defaultProject')
      should contain_keystone_config('ldap/user_tree_dn').with_value('cn=users,dc=example,dc=com')
      should contain_keystone_config('ldap/user_allow_create').with_value('False')
      should contain_keystone_config('ldap/user_allow_update').with_value('False')
      should contain_keystone_config('ldap/user_allow_delete').with_value('False')
      should contain_keystone_config('ldap/user_pass_attribute').with_value('krbPassword')
      should contain_keystone_config('ldap/user_enabled_emulation').with_value('True')
      should contain_keystone_config('ldap/user_enabled_emulation_dn').with_value('cn=openstack-enabled,cn=groups,cn=accounts,dc=example,dc=com')
      should contain_keystone_config('ldap/user_additional_attribute_mapping').with_value('description:name, gecos:name')

      should contain_keystone_config('ldap/tenant_tree_dn').with_value('ou=projects,ou=openstack,dc=example,dc=com')
      should contain_keystone_config('ldap/tenant_filter').with_value('')
      should contain_keystone_config('ldap/tenant_objectclass').with_value('organizationalUnit')
      should contain_keystone_config('ldap/tenant_id_attribute').with_value('ou')
      should contain_keystone_config('ldap/tenant_member_attribute').with_value('member')
      should contain_keystone_config('ldap/tenant_desc_attribute').with_value('description')
      should contain_keystone_config('ldap/tenant_name_attribute').with_value('ou')
      should contain_keystone_config('ldap/tenant_enabled_attribute').with_value('enabled')
      should contain_keystone_config('ldap/tenant_domain_id_attribute').with_value('businessCategory')
      should contain_keystone_config('ldap/tenant_attribute_ignore').with_value('')
      should contain_keystone_config('ldap/tenant_allow_create').with_value('True')
      should contain_keystone_config('ldap/tenant_allow_update').with_value('True')
      should contain_keystone_config('ldap/tenant_allow_delete').with_value('True')
      should contain_keystone_config('ldap/tenant_enabled_emulation').with_value('False')
      should contain_keystone_config('ldap/tenant_enabled_emulation_dn').with_value('True')
      should contain_keystone_config('ldap/tenant_additional_attribute_mapping').with_value('cn=enabled,ou=openstack,dc=example,dc=com')
      should contain_keystone_config('ldap/role_tree_dn').with_value('ou=roles,ou=openstack,dc=example,dc=com')
      should contain_keystone_config('ldap/role_filter').with_value('')
      should contain_keystone_config('ldap/role_objectclass').with_value('organizationalRole')
      should contain_keystone_config('ldap/role_id_attribute').with_value('cn')
      should contain_keystone_config('ldap/role_name_attribute').with_value('ou')
      should contain_keystone_config('ldap/role_member_attribute').with_value('roleOccupant')
      should contain_keystone_config('ldap/role_attribute_ignore').with_value('description')
      should contain_keystone_config('ldap/role_allow_create').with_value('True')
      should contain_keystone_config('ldap/role_allow_update').with_value('True')
      should contain_keystone_config('ldap/role_allow_delete').with_value('True')
      should contain_keystone_config('ldap/role_additional_attribute_mapping').with_value('')

      should contain_keystone_config('ldap/group_tree_dn').with_value('ou=groups,ou=openstack,dc=example,dc=com')
      should contain_keystone_config('ldap/group_filter').with_value('cn=enabled-groups,cn=groups,cn=accounts,dc=example,dc=com')
      should contain_keystone_config('ldap/group_objectclass').with_value('organizationalRole')
      should contain_keystone_config('ldap/group_id_attribute').with_value('cn')
      should contain_keystone_config('ldap/group_member_attribute').with_value('roleOccupant')
      should contain_keystone_config('ldap/group_desc_attribute').with_value('description')
      should contain_keystone_config('ldap/group_name_attribute').with_value('cn')
      should contain_keystone_config('ldap/group_attribute_ignore').with_value('')
      should contain_keystone_config('ldap/group_allow_create').with_value('False')
      should contain_keystone_config('ldap/group_allow_update').with_value('False')
      should contain_keystone_config('ldap/group_allow_delete').with_value('False')
      should contain_keystone_config('ldap/group_additional_attribute_mapping').with_value('')
      should contain_keystone_config('ldap/use_tls').with_value('False')
      should contain_keystone_config('ldap/tls_cacertdir').with_value('/etc/ssl/certs/')
      should contain_keystone_config('ldap/tls_cacertfile').with_value('/etc/ssl/certs/ca-certificates.crt')
      should contain_keystone_config('ldap/tls_req_cert').with_value('demand')
      should contain_keystone_config('identity/driver').with_value('keystone.identity.backends.ldap.Identity')
      should contain_keystone_config('assignment/driver').with_value('keystone.assignment.backends.ldap.Assignment')
    end
  end
end

