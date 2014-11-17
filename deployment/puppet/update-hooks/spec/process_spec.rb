require 'spec_helper'
require File.join(File.dirname(__FILE__), '../lib/base')
require File.join(File.dirname(__FILE__), '../lib/process')

class ProcessTest
  include Base
  include Process
end

describe ProcessTest do

  let(:redhat_ps) do
    <<-eos
100 1 /usr/bin/python nova-api.py
101 100 /usr/bin/python nova-api.py
102 100 /usr/bin/python nova-api.py
103 100 /usr/bin/python nova-api.py
104 1 /usr/bin/python cinder-volume.py
105 104 /usr/sbin/tgtd
106 1 /usr/bin/python neutron.py
107 106 /usr/sbin/dnsmasq
108 1 /usr/sbin/httpd
109 1 /usr/bin/python keystone.py
    eos
  end

  let(:debian_ps) do
    <<-eos
100 1 /usr/bin/python nova-api.py
101 100 /usr/bin/python nova-api.py
102 100 /usr/bin/python nova-api.py
103 100 /usr/bin/python nova-api.py
104 1 /usr/bin/python cinder-volume.py
105 104 /usr/sbin/tgtd
106 1 /usr/bin/python neutron.py
107 106 /usr/sbin/dnsmasq
108 1 /usr/sbin/apache2
109 1 /usr/bin/python keystone.py
    eos
  end

  let(:debian_pstree) do
    {
        104 => {
            :children => [105],
            :ppid => 1,
            :cmd => "/usr/bin/python cinder-volume.py",
            :pid => 104
        },
        105 => {
            :children => [],
            :ppid => 104,
            :cmd => "/usr/sbin/tgtd",
            :pid => 105
        },
        100 => {
            :children => [101, 102, 103],
            :ppid => 1,
            :cmd => "/usr/bin/python nova-api.py",
            :pid => 100
        },
        1 => {
            :children => [100, 104, 106, 108, 109]
        },
        106 => {
            :children => [107],
            :ppid => 1,
            :cmd => "/usr/bin/python neutron.py",
            :pid => 106
        },
        101 => {
            :children => [],
            :ppid => 100,
            :cmd => "/usr/bin/python nova-api.py",
            :pid => 101
        },
        107 => {
            :children => [],
            :ppid => 106,
            :cmd => "/usr/sbin/dnsmasq",
            :pid => 107
        },
        102 => {
            :children => [],
            :ppid => 100,
            :cmd => "/usr/bin/python nova-api.py",
            :pid => 102
        },
        108 => {
            :children => [],
            :ppid => 1,
            :cmd => "/usr/sbin/apache2",
            :pid => 108
        },
        103 => {
            :children => [],
            :ppid => 100,
            :cmd => "/usr/bin/python nova-api.py",
            :pid => 103
        },
        109 => {
            :children => [],
            :ppid => 1,
            :cmd => "/usr/bin/python keystone.py",
            :pid => 109
        }
    }
  end

  let(:redhat_pstree) do
    {
        104 => {
            :children => [105],
            :ppid => 1,
            :cmd => "/usr/bin/python cinder-volume.py",
            :pid => 104
        },
        105 => {
            :children => [],
            :ppid => 104,
            :cmd => "/usr/sbin/tgtd",
            :pid => 105
        },
        100 => {
            :children => [101, 102, 103],
            :ppid => 1,
            :cmd => "/usr/bin/python nova-api.py",
            :pid => 100
        },
        1 => {
            :children => [100, 104, 106, 108, 109]
        },
        106 => {
            :children => [107],
            :ppid => 1,
            :cmd => "/usr/bin/python neutron.py",
            :pid => 106
        },
        101 => {
            :children => [],
            :ppid => 100,
            :cmd => "/usr/bin/python nova-api.py",
            :pid => 101
        },
        107 => {
            :children => [],
            :ppid => 106,
            :cmd => "/usr/sbin/dnsmasq",
            :pid => 107
        },
        102 => {
            :children => [],
            :ppid => 100,
            :cmd => "/usr/bin/python nova-api.py",
            :pid => 102
        },
        108 => {
            :children => [],
            :ppid => 1,
            :cmd => "/usr/sbin/httpd",
            :pid => 108
        },
        103 => {
            :children => [],
            :ppid => 100,
            :cmd => "/usr/bin/python nova-api.py",
            :pid => 103
        },
        109 => {
            :children => [],
            :ppid => 1,
            :cmd => "/usr/bin/python keystone.py",
            :pid => 109
        }
    }
  end

  let(:process_regexp) do
    %r{nova|cinder|glance|keystone|neutron|sahara|murano|ceilometer|heat|swift|apache2|httpd}
  end

###################################################################

  before(:each) do
    @class = subject
    @class.stubs(:dry_run).returns true
    @class.stubs(:log).returns true
  end

  context 'On Debian system' do
    before(:each) do
      @class.stubs(:ps).returns(debian_ps)
      @class.stubs(:osfamily).returns 'Debian'
    end

    it 'should correctly parse ps output' do
      @class.process_tree_with_renew
      expect(@class.process_tree).to eq debian_pstree
    end

    it 'should find processes by regexp' do
      @class.process_tree_with_renew
      dnsmasq = {107 => {
          :children => [],
          :ppid => 106,
          :cmd => '/usr/sbin/dnsmasq',
          :pid => 107
      }}
      expect(@class.pids_by_regexp /dnsmasq/).to eq dnsmasq
    end

    it 'should kill correct processes' do
      @class.expects(:run).with 'kill -9 100 101 102 103 104 105 106 107 108 109'
      @class.process_tree_with_renew
      @class.kill_pids_by_regexp process_regexp
    end
  end

  context 'On RedHat system' do
    before(:each) do
      @class.stubs(:ps).returns(redhat_ps)
      @class.stubs(:osfamily).returns 'RedHat'
    end

    it 'should correctly parse ps output' do
      @class.process_tree_with_renew
      expect(@class.process_tree).to eq redhat_pstree
    end

    it 'should find processes by regexp' do
      @class.process_tree_with_renew
      dnsmasq = {107 => {
          :children => [],
          :ppid => 106,
          :cmd => '/usr/sbin/dnsmasq',
          :pid => 107
      }}
      expect(@class.pids_by_regexp /dnsmasq/).to eq dnsmasq
    end

    it 'should kill correct processes' do
      @class.expects(:run).with 'kill -9 100 101 102 103 104 105 106 107 108 109'
      @class.process_tree_with_renew
      @class.kill_pids_by_regexp process_regexp
    end
  end

end