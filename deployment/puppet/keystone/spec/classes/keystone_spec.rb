require 'spec_helper'

describe 'keystone' do

  let :concat_file do
    {
      :type  => 'File',
      :title => '/var/lib/puppet/concat/_etc_keystone_keystone.conf/fragments.concat.out'
    }
  end

  let :default_params do
    {
      'package_ensure'  => 'present',
      'bind_host'        => '0.0.0.0',
      'public_port'     => '5000',
      'admin_port'      => '35357',
      'admin_token'     => 'service_token',
      'compute_port'    => '3000',
      'log_verbose'     => 'False',
      'log_debug'       => 'False',
      'use_syslog'      => 'False',
      'catalog_type'    => 'template'
    }
  end

  [{},
   {
      'package_ensure'  => 'latest',
      'bind_host'        => '127.0.0.1',
      'public_port'     => '5001',
      'admin_port'      => '35358',
      'admin_token'     => 'service_token_override',
      'compute_port'    => '3001',
      'log_verbose'     => 'True',
      'log_debug'       => 'True',
      'catalog_type'    => 'sql'
    }
  ].each do |param_set|

    describe "when #{param_set == {} ? "using default" : "specifying"} class parameters" do
      let :param_hash do
        default_params.merge(param_set)
      end

      let :params do
        param_set
      end

      it { should contain_class('keystone::params') }

      it { should contain_class('concat::setup') }

      it { should contain_package('keystone').with(
        'ensure' => param_hash['package_ensure'],
        'notify' => 'Exec[keystone-manage db_sync]'
      ) }

      it { should contain_group('keystone').with(
          'ensure' => 'present',
          'system' => 'true'
      ) }
      it { should contain_user('keystone').with(
        'ensure' => 'present',
        'gid'    => 'keystone',
        'system' => 'true'
      ) }

      it { should contain_file('/etc/keystone').with(
        'ensure'     => 'directory',
        'owner'      => 'keystone',
        'group'      => 'keystone',
        'mode'       => '0755',
        'require'    => 'Package[keystone]'
      ) }

      it { should contain_concat('/etc/keystone/keystone.conf').with(
        'owner'   => 'keystone',
        'group'   => 'keystone',
        'require' => 'Package[keystone]',
        'notify'  => ['Service[keystone]', 'Exec[keystone-manage db_sync]']
      )}

      it { should contain_service('keystone').with(
        'ensure'     => 'running',
        'enable'     => 'true',
        'hasstatus'  => 'true',
        'hasrestart' => 'true',
        'subscribe'  => 'Exec[keystone-manage db_sync]'
      ) }

      it { should contain_exec('keystone-manage db_sync').with_refreshonly('true') }

      it 'should correctly configure catalog based on catalog_type'

      it 'should create the expected DEFAULT configuration' do
#require 'ruby-debug';debugger
        verify_contents(
          subject,
          '/var/lib/puppet/concat/_etc_keystone_keystone.conf/fragments/00_kestone-DEFAULT',
          [
            "bind_host     = #{param_hash['bind_host']}",
            "public_port   = #{param_hash['public_port']}",
            "admin_port    = #{param_hash['admin_port']}",
            "admin_token   = #{param_hash['admin_token']}",
            "compute_port  = #{param_hash['compute_port']}",
            "verbose       = #{param_hash['log_verbose']}",
            "debug         = #{param_hash['log_debug']}",
            "log_file      = /var/log/keystone/keystone.log",
            "use_syslog    = #{param_hash['use_syslog']}"
          ]
        )
      end
      it 'should create the expected identity section' do
        verify_contents(
          subject,
          '/var/lib/puppet/concat/_etc_keystone_keystone.conf/fragments/03_kestone-identity',
          [
            "[identity]",
            "driver = keystone.identity.backends.sql.Identity"
          ]
        )
      end
      it { should create_file(
        '/var/lib/puppet/concat/_etc_keystone_keystone.conf/fragments/99_kestone-footer') }
    end
  end
end
