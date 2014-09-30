#
# Implements ldap configuration for keystone.
#
# == Dependencies
# == Examples
# == Authors
#
#   Dan Bode dan@puppetlabs.com
#   Matt Fischer matt.fischer@twcable.com
#
# == Copyright
#
# Copyright 2012 Puppetlabs Inc, unless otherwise noted.
#
class keystone::ldap(
  $url                                 = undef,
  $user                                = undef,
  $password                            = undef,
  $suffix                              = undef,
  $query_scope                         = undef,
  $page_size                           = undef,
  $user_tree_dn                        = undef,
  $user_filter                         = undef,
  $user_objectclass                    = undef,
  $user_id_attribute                   = undef,
  $user_name_attribute                 = undef,
  $user_mail_attribute                 = undef,
  $user_enabled_attribute              = undef,
  $user_enabled_mask                   = undef,
  $user_enabled_default                = undef,
  $user_attribute_ignore               = undef,
  $user_default_project_id_attribute   = undef,
  $user_allow_create                   = undef,
  $user_allow_update                   = undef,
  $user_allow_delete                   = undef,
  $user_pass_attribute                 = undef,
  $user_enabled_emulation              = undef,
  $user_enabled_emulation_dn           = undef,
  $user_additional_attribute_mapping   = undef,
  $tenant_tree_dn                      = undef,
  $tenant_filter                       = undef,
  $tenant_objectclass                  = undef,
  $tenant_id_attribute                 = undef,
  $tenant_member_attribute             = undef,
  $tenant_desc_attribute               = undef,
  $tenant_name_attribute               = undef,
  $tenant_enabled_attribute            = undef,
  $tenant_domain_id_attribute          = undef,
  $tenant_attribute_ignore             = undef,
  $tenant_allow_create                 = undef,
  $tenant_allow_update                 = undef,
  $tenant_allow_delete                 = undef,
  $tenant_enabled_emulation            = undef,
  $tenant_enabled_emulation_dn         = undef,
  $tenant_additional_attribute_mapping = undef,
  $role_tree_dn                        = undef,
  $role_filter                         = undef,
  $role_objectclass                    = undef,
  $role_id_attribute                   = undef,
  $role_name_attribute                 = undef,
  $role_member_attribute               = undef,
  $role_attribute_ignore               = undef,
  $role_allow_create                   = undef,
  $role_allow_update                   = undef,
  $role_allow_delete                   = undef,
  $role_additional_attribute_mapping   = undef,
  $group_tree_dn                       = undef,
  $group_filter                        = undef,
  $group_objectclass                   = undef,
  $group_id_attribute                  = undef,
  $group_name_attribute                = undef,
  $group_member_attribute              = undef,
  $group_desc_attribute                = undef,
  $group_attribute_ignore              = undef,
  $group_allow_create                  = undef,
  $group_allow_update                  = undef,
  $group_allow_delete                  = undef,
  $group_additional_attribute_mapping  = undef,
  $tenant_tree_dn                      = undef,
  $role_tree_dn                        = undef,
  $use_tls                             = undef,
  $tls_cacertdir                       = undef,
  $tls_cacertfile                      = undef,
  $tls_req_cert                        = undef,
  $identity_driver                     = undef,
  $assignment_driver                   = undef,
) {

  package { 'python-ldap':
      ensure => present,
  }

  # check for some common driver name mistakes
  if ($assignment_driver != undef) {
      if ! ($assignment_driver =~ /^keystone.assignment.backends.*Assignment$/) {
          fail('assigment driver should be of the form \'keystone.assignment.backends.*Assignment\'')
      }
  }

  if ($identity_driver != undef) {
      if ! ($identity_driver =~ /^keystone.identity.backends.*Identity$/) {
          fail('identity driver should be of the form \'keystone.identity.backends.*Identity\'')
      }
  }

  if ($tls_cacertdir != undef) {
    file { $tls_cacertdir:
      ensure => directory
    }
  }

  keystone_config {
    'ldap/url':                                 value => $url;
    'ldap/user':                                value => $user;
    'ldap/password':                            value => $password, secret => true;
    'ldap/suffix':                              value => $suffix;
    'ldap/query_scope':                         value => $query_scope;
    'ldap/page_size':                           value => $page_size;
    'ldap/user_tree_dn':                        value => $user_tree_dn;
    'ldap/user_filter':                         value => $user_filter;
    'ldap/user_objectclass':                    value => $user_objectclass;
    'ldap/user_id_attribute':                   value => $user_id_attribute;
    'ldap/user_name_attribute':                 value => $user_name_attribute;
    'ldap/user_mail_attribute':                 value => $user_mail_attribute;
    'ldap/user_enabled_attribute':              value => $user_enabled_attribute;
    'ldap/user_enabled_mask':                   value => $user_enabled_mask;
    'ldap/user_enabled_default':                value => $user_enabled_default;
    'ldap/user_attribute_ignore':               value => $user_attribute_ignore;
    'ldap/user_default_project_id_attribute':   value => $user_default_project_id_attribute;
    'ldap/user_allow_create':                   value => $user_allow_create;
    'ldap/user_allow_update':                   value => $user_allow_update;
    'ldap/user_allow_delete':                   value => $user_allow_delete;
    'ldap/user_pass_attribute':                 value => $user_pass_attribute;
    'ldap/user_enabled_emulation':              value => $user_enabled_emulation;
    'ldap/user_enabled_emulation_dn':           value => $user_enabled_emulation_dn;
    'ldap/user_additional_attribute_mapping':   value => $user_additional_attribute_mapping;
    'ldap/tenant_tree_dn':                      value => $tenant_tree_dn;
    'ldap/tenant_filter':                       value => $tenant_filter;
    'ldap/tenant_objectclass':                  value => $tenant_objectclass;
    'ldap/tenant_id_attribute':                 value => $tenant_id_attribute;
    'ldap/tenant_member_attribute':             value => $tenant_member_attribute;
    'ldap/tenant_desc_attribute':               value => $tenant_desc_attribute;
    'ldap/tenant_name_attribute':               value => $tenant_name_attribute;
    'ldap/tenant_enabled_attribute':            value => $tenant_enabled_attribute;
    'ldap/tenant_attribute_ignore':             value => $tenant_attribute_ignore;
    'ldap/tenant_domain_id_attribute':          value => $tenant_domain_id_attribute;
    'ldap/tenant_allow_create':                 value => $tenant_allow_create;
    'ldap/tenant_allow_update':                 value => $tenant_allow_update;
    'ldap/tenant_allow_delete':                 value => $tenant_allow_delete;
    'ldap/tenant_enabled_emulation':            value => $tenant_enabled_emulation;
    'ldap/tenant_enabled_emulation_dn':         value => $tenant_enabled_emulation_dn;
    'ldap/tenant_additional_attribute_mapping': value => $tenant_additional_attribute_mapping;
    'ldap/role_tree_dn':                        value => $role_tree_dn;
    'ldap/role_filter':                         value => $role_filter;
    'ldap/role_objectclass':                    value => $role_objectclass;
    'ldap/role_id_attribute':                   value => $role_id_attribute;
    'ldap/role_name_attribute':                 value => $role_name_attribute;
    'ldap/role_member_attribute':               value => $role_member_attribute;
    'ldap/role_attribute_ignore':               value => $role_attribute_ignore;
    'ldap/role_allow_create':                   value => $role_allow_create;
    'ldap/role_allow_update':                   value => $role_allow_update;
    'ldap/role_allow_delete':                   value => $role_allow_delete;
    'ldap/role_additional_attribute_mapping':   value => $role_additional_attribute_mapping;
    'ldap/group_tree_dn':                       value => $group_tree_dn;
    'ldap/group_filter':                        value => $group_filter;
    'ldap/group_objectclass':                   value => $group_objectclass;
    'ldap/group_id_attribute':                  value => $group_id_attribute;
    'ldap/group_name_attribute':                value => $group_name_attribute;
    'ldap/group_member_attribute':              value => $group_member_attribute;
    'ldap/group_desc_attribute':                value => $group_desc_attribute;
    'ldap/group_attribute_ignore':              value => $group_attribute_ignore;
    'ldap/group_allow_create':                  value => $group_allow_create;
    'ldap/group_allow_update':                  value => $group_allow_update;
    'ldap/group_allow_delete':                  value => $group_allow_delete;
    'ldap/group_additional_attribute_mapping':  value => $group_additional_attribute_mapping;
    'ldap/use_tls':                             value => $use_tls;
    'ldap/tls_cacertdir':                       value => $tls_cacertdir;
    'ldap/tls_cacertfile':                      value => $tls_cacertfile;
    'ldap/tls_req_cert':                        value => $tls_req_cert;
    'identity/driver':                          value => $identity_driver;
    'assignment/driver':                        value => $assignment_driver;
  }
}
