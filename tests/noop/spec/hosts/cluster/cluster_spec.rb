require 'spec_helper'
require 'shared-examples'
manifest = 'cluster/cluster.pp'

describe manifest do
  shared_examples 'catalog' do


    it { should contain_class('cluster') }
    it { should contain_pcmk_nodes('pacemaker') }
    it { should contain_service('corosync').that_comes_before('Pcmk_nodes[pacemaker]') }
    it { should contain_service('corosync').with({
         'subscribe' => 'File[/etc/corosync/service.d]',
         'require'   => 'File[/etc/corosync/corosync.conf]',
         })
    }

    it do
      if (facts[:operatingsystem] == 'Ubuntu')
        should contain_file('/etc/corosync/uidgid.d/pacemaker').that_requires('File[/etc/corosync/corosync.conf]')
      elsif
        should_not contain_file('/etc/corosync/uidgid.d/pacemaker')
      end
    end

    it do
      if (facts[:operatingsystem] == 'Ubuntu')
        should contain_file('/etc/corosync/uidgid.d/pacemaker').that_comes_before('Service[corosync]')
      end
    end

  end
  test_ubuntu_and_centos manifest
end

