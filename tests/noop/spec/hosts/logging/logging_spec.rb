require 'spec_helper'
require 'shared-examples'
manifest = 'logging/logging.pp'

describe manifest do
  shared_examples 'catalog' do
    it {
      if facts[:operatingsystem] == 'Ubuntu'
        should contain_file('/var/log').with(
          'owner' => 'root',
          'group' => 'syslog',
          'mode'  => '0775'
        )
      else
        should_not contain_file('/var/log')
      end
    }
    if Noop.hiera('node_role') == 'ironic'
      it 'should contain 70-ironic.conf' do
        should contain_file('/etc/rsyslog.d/70-ironic.conf').with(
          'owner' => 'syslog',
          'group' => 'syslog',
          'mode'  => '0640',
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end

