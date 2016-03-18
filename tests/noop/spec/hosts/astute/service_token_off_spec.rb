# RUN: neut_vlan.ceph.ceil-primary-controller.overridden_ssl ubuntu
# RUN: neut_vlan.ceph.controller-ephemeral-ceph ubuntu
# RUN: neut_vlan.ironic.controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl ubuntu

require 'spec_helper'
require 'shared-examples'
manifest = 'astute/service_token_off.pp'

describe manifest do
  shared_examples 'catalog' do

    keystone_params  = Noop.hiera_structure 'keystone'

    if keystone_params['service_token_off']
      it 'should contain apache/mod_wsgi keystone service' do
        case facts[:osfamily]
          when 'Debian'
            service_name = 'apache2'
          when 'RedHat'
            service_name = 'httpd'
        end

        is_expected.to contain_service('httpd').with(
          :ensure     => 'running',
          :name       => service_name,
          :hasrestart => 'true',
          :restart    => 'sleep 30 && apachectl graceful || apachectl restart'
        )
      end

      it 'should remove admin_token option' do
        is_expected.to contain_keystone_config('DEFAULT/admin_token').with_ensure('absent')
      end

      it 'should contain class to remove AdminTokenAuthMiddleware from pipelines' do
        is_expected.to contain_class('keystone::disable_admin_token_auth')
      end
    end

  end
  test_ubuntu_and_centos manifest
end
