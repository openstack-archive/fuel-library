require 'spec_helper'
require File.join(File.dirname(__FILE__), '../lib/base')
require File.join(File.dirname(__FILE__), '../lib/service')

class ServiceTest
  include Base
  include Service
end

describe ServiceTest do

  let(:redhat_ps) do
    <<-eos
100 1 /usr/bin/python nova-api.py
101 100 /usr/bin/python nova-api.py
102 100 /usr/bin/python nova-api.py
103 100 /usr/bin/python nova-api.py
106 1 /usr/bin/python neutron.py
107 106 /usr/sbin/dnsmasq
108 1 /usr/sbin/httpd
109 1 /usr/bin/python keystone.py
    eos
  end

  let(:debian_pstree) do
    {
        100 => {
            :children => [101, 102, 103],
            :ppid => 1,
            :cmd => "/usr/bin/python nova-api.py",
            :pid => 100
        },
        1 => {
            :children => [100, 106, 108, 109]
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
        100 => {
            :children => [101, 102, 103],
            :ppid => 1,
            :cmd => "/usr/bin/python nova-api.py",
            :pid => 100
        },
        1 => {
            :children => [100, 106, 108, 109]
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

  let(:debian_ps) do
    <<-eos
100 1 /usr/bin/python nova-api.py
101 100 /usr/bin/python nova-api.py
102 100 /usr/bin/python nova-api.py
103 100 /usr/bin/python nova-api.py
106 1 /usr/bin/python neutron.py
107 106 /usr/sbin/dnsmasq
108 1 /usr/sbin/apache2
109 1 /usr/bin/python keystone.py
    eos
  end

  let(:debian_services) do
    <<-eos
 [ ? ]  ntpd
 [ ? ]  neutron
 [ - ]  cinder-volume
 [ - ]  nginx
 [ - ]  smbd
 [ + ]  sshd
 [ + ]  nova-api
 [ + ]  apache2
 [ + ]  keystone
    eos
  end

  let(:redhat_services) do
    <<-eos
ntpd is stopped
neutron is stopped
sshd (pid  50) is running...
openstack-cinder-volume is stopped
openstack-nova-api (pid  100) is running...
nginx is stopped
smbd is stopped
httpd.event (pid  108) is running...
keystone (pid  109) is running...
    eos
  end

  let(:debian_services_list) do
    {
        "apache2" => {:running=>true, :enabled=>true},
        "cinder-volume" => {:running=>false, :enabled=>false},
        "keystone" => {:running=>true, :enabled=>true},
        "neutron" => {:running=>false, :enabled=>false},
        "nginx" => {:running=>false, :enabled=>false},
        "nova-api" => {:running=>true, :enabled=>true},
        "ntpd" => {:running=>false, :enabled=>false},
        "smbd" => {:running=>false, :enabled=>false},
        "sshd" => {:running=>true, :enabled=>true},
    }
  end

  let(:redhat_services_list) do
    {
        "httpd" => {:running=>true, :enabled=>true},
        "neutron" => {:running=>false, :enabled=>false},
        "nginx" => {:running=>true, :enabled=>true},
        "ntpd" => {:running=>false, :enabled=>false},
        "openstack-cinder-volume" => {:running=>false, :enabled=>false},
        "openstack-keystone" => {:running=>true, :enabled=>true},
        "openstack-nova-api" => {:running=>true, :enabled=>true},
        "smbd" => {:running=>false, :enabled=>false},
        "sshd" => {:running=>true, :enabled=>true},
    }
  end

  let(:services_regexp) do
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
      @class.stubs(:services).returns debian_services
      debian_services_list.each do |service_name, status|
        @class.stubs(:service_is_enabled?).with(service_name).returns status[:enabled]
        @class.stubs(:service_is_running?).with(service_name).returns status[:running]
      end
    end

    it 'should find all services' do
      expect(@class.services_list_with_renew).to eq debian_services_list
    end

    it 'should find services by regexp' do
      @class.services_list_with_renew
      expect(@class.services_by_regexp(/nginx/).keys).to eq(['nginx'])
    end

    it 'should start correct services' do
      @class.expects(:run).with 'service cinder-volume start'
      @class.expects(:run).with 'service neutron start'
      @class.services_list_with_renew
      @class.start_services_by_regexp services_regexp
    end

    it 'should stop correct services' do
      @class.expects(:run).with 'service nova-api stop'
      @class.expects(:run).with 'service apache2 stop'
      @class.expects(:run).with 'service keystone stop'
      @class.services_list_with_renew
      @class.stop_services_by_regexp services_regexp
    end
  end

  context 'On RedHat system' do
    before(:each) do
      @class.stubs(:ps).returns(redhat_ps)
      @class.stubs(:osfamily).returns 'RedHat'
      @class.stubs(:services).returns redhat_services
      redhat_services_list.each do |service_name, status|
        @class.stubs(:service_is_enabled?).with(service_name).returns status[:enabled]
        @class.stubs(:service_is_running?).with(service_name).returns status[:running]
      end
    end

    it 'should find services' do
      expect(@class.services_list_with_renew).to eq redhat_services_list
    end

    it 'should find services by regexp' do
      @class.services_list_with_renew
      expect(@class.services_by_regexp(/nginx/).keys).to eq(['nginx'])
    end

    it 'should start correct services' do
      @class.expects(:run).with 'service openstack-cinder-volume start'
      @class.expects(:run).with 'service neutron start'
      @class.services_list_with_renew
      @class.start_services_by_regexp services_regexp
    end

    it 'should stop correct services' do
      @class.expects(:run).with 'service openstack-nova-api stop'
      @class.expects(:run).with 'service httpd stop'
      @class.expects(:run).with 'service openstack-keystone stop'
      @class.services_list_with_renew
      @class.stop_services_by_regexp services_regexp
    end
  end

end
