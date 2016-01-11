require 'spec_helper'
require File.join File.dirname(__FILE__), '../test_common.rb'

describe TestCommon do
  context TestCommon::Cmd do
    let(:cli_data) do
      <<-eos
+----------------------------------+----------+----------------+----------------------------------+
|                id                |   name   |      type      |           description            |
+----------------------------------+----------+----------------+----------------------------------+
| 5374e5389d364da28c984bc429c3e33a |  cinder  |     volume     |          Cinder Service          |
| af3d223f30da4fe09cec7b857a204ba4 | cinderv2 |    volumev2    |        Cinder Service v2         |
| 0640b5feb76948ee93a33ab4354bb2b8 |  glance  |     image      |     Openstack Image Service      |
| 7923acaf138247269fb3ef12236c5c6a |   heat   | orchestration  | Openstack Orchestration Service  |
| 27be38b78d57489eb54a6b41a630b443 | heat-cfn | cloudformation | Openstack Cloudformation Service |
| b2ea93c019704ed4bbc0c4da8fff425b | keystone |    identity    |    OpenStack Identity Service    |
| f8daa037416549b0a7bbdff67b0501b3 | neutron  |    network     |    Neutron Networking Service    |
| d20f6c9b482642c8b3c92ea5c115f100 |   nova   |    compute     |    Openstack Compute Service     |
| d8882e01181740e1b96b34dbf9b4dd77 | nova_ec2 |      ec2       |           EC2 Service            |
| c9291f7d537141ffb6a560dd42e7d159 |  swift   |  object-store  |  Openstack Object-Store Service  |
| b622a097b88e460ebea284bf04f65be5 | swift_s3 |       s3       |       Openstack S3 Service       |
+----------------------------------+----------+----------------+----------------------------------+
      eos
    end

    let(:cli_data_parsed) do
      [
          {"id"=>"5374e5389d364da28c984bc429c3e33a", "name"=>"cinder", "type"=>"volume"},
          {"id"=>"af3d223f30da4fe09cec7b857a204ba4", "name"=>"cinderv2", "type"=>"volumev2"},
          {"id"=>"0640b5feb76948ee93a33ab4354bb2b8", "name"=>"glance", "type"=>"image"},
          {"id"=>"7923acaf138247269fb3ef12236c5c6a", "name"=>"heat", "type"=>"orchestration"},
          {"id"=>"27be38b78d57489eb54a6b41a630b443", "name"=>"heat-cfn", "type"=>"cloudformation"},
          {"id"=>"b2ea93c019704ed4bbc0c4da8fff425b", "name"=>"keystone", "type"=>"identity"},
          {"id"=>"f8daa037416549b0a7bbdff67b0501b3", "name"=>"neutron", "type"=>"network"},
          {"id"=>"d20f6c9b482642c8b3c92ea5c115f100", "name"=>"nova", "type"=>"compute"},
          {"id"=>"d8882e01181740e1b96b34dbf9b4dd77", "name"=>"nova_ec2", "type"=>"ec2"},
          {"id"=>"c9291f7d537141ffb6a560dd42e7d159", "name"=>"swift", "type"=>"object-store"},
          {"id"=>"b622a097b88e460ebea284bf04f65be5", "name"=>"swift_s3", "type"=>"s3"},
      ]
    end
    it 'can run the OpenStack cli command and parse the results' do
      expect(TestCommon::Cmd).to receive(:run).with('keystone service-list').and_return([cli_data, 0])
      allow(TestCommon::Cmd).to receive(:openstack_auth)
      expect(TestCommon::Cmd.openstack_cli 'keystone service-list').to eq cli_data_parsed
    end
  end

  context TestCommon::Settings do
    before :each do
      allow(subject.hiera).to receive(:lookup).with('id', nil, {}).and_return('1')
    end

    it 'can get the hiera object' do
      expect(subject.hiera).to be_a Hiera
    end

    it 'can lookup a settings value' do
      expect(subject.lookup 'id').to eq('1')
    end

    it 'can lookup by index or method' do
      expect(subject.id).to eq('1')
      expect(subject['id']).to eq('1')
    end
  end

  context TestCommon::HAProxy do
    let :csv do
      <<-eof
# pxname,svname,qcur,qmax,scur,smax,slim,stot,bin,bout,dreq,dresp,ereq,econ,eresp,wretr,wredis,status,weight,act,bck,chkfail,chkdown,lastchg,downtime,qlimit,pid,iid,sid,throttle,lbtot,tracked,type,rate,rate_lim,rate_max,check_status,check_code,check_duration,hrsp_1xx,hrsp_2xx,hrsp_3xx,hrsp_4xx,hrsp_5xx,hrsp_other,hanafail,req_rate,req_rate_max,req_tot,cli_abrt,srv_abrt,comp_in,comp_out,comp_byp,comp_rsp,lastsess,last_chk,last_agt,qtime,ctime,rtime,ttime,
Stats,FRONTEND,,,0,2,8000,479,3959708,1147775737,0,0,0,,,,,OPEN,,,,,,,,,1,2,0,,,,0,0,0,6,,,,0,11394,0,0,0,0,,0,8,11394,,,0,0,0,0,,,,,,,,
Stats,BACKEND,0,0,0,0,800,0,3959708,1147775737,0,0,,0,0,0,0,UP,0,0,0,,0,347258,0,,1,2,0,,0,,1,0,,0,,,,0,0,0,0,0,0,,,,,0,0,0,0,0,0,319035,,,0,0,0,2585,
horizon,FRONTEND,,,0,0,8000,0,0,0,0,0,0,,,,,OPEN,,,,,,,,,1,3,0,,,,0,0,0,0,,,,0,0,0,0,0,0,,0,0,0,,,0,0,0,0,,,,,,,,
horizon,node-7,0,0,0,0,,0,0,0,,0,,0,0,0,0,DOWN,1,1,0,3,1,10,10,,1,3,1,,0,,2,0,,0,L4CON,,0,0,0,0,0,0,0,0,,,,0,0,,,,,-1,Connection refused,,0,0,0,0,
horizon,BACKEND,0,0,0,0,800,0,0,0,0,0,,0,0,0,0,DOWN,0,0,0,,1,10,10,,1,3,0,,0,,1,0,,0,,,,0,0,0,0,0,0,,,,,0,0,0,0,0,0,-1,,,0,0,0,0,
keystone-1,FRONTEND,,,0,1,8000,25,4200,22925,0,0,0,,,,,OPEN,,,,,,,,,1,4,0,,,,0,0,0,1,,,,0,0,25,0,0,0,,0,1,25,,,0,0,0,0,,,,,,,,
keystone-1,node-7,0,0,0,1,,25,4200,22925,,0,,0,0,0,0,UP,1,1,0,0,0,347258,0,,1,4,1,,25,,2,0,,1,L7OK,300,2,0,0,25,0,0,0,0,,,,0,0,,,,,332047,Multiple Choices,,0,0,1,1,
keystone-1,BACKEND,0,0,0,1,800,25,4200,22925,0,0,,0,0,0,0,UP,1,1,0,,0,347258,0,,1,4,0,,25,,1,0,,1,,,,0,0,25,0,0,0,,,,,0,0,0,0,0,0,332047,,,0,0,1,1,
keystone-2,FRONTEND,,,0,2,8000,135,31659,695738,0,0,0,,,,,OPEN,,,,,,,,,1,5,0,,,,0,0,0,4,,,,0,105,30,0,0,0,,0,4,135,,,0,0,0,0,,,,,,,,
keystone-2,node-7,0,0,0,1,,135,31659,695738,,0,,0,0,0,0,UP,1,1,0,0,0,347258,0,,1,5,1,,135,,2,0,,4,L7OK,300,3,0,105,30,0,0,0,0,,,,0,0,,,,,331832,Multiple Choices,,0,1,16,17,
keystone-2,BACKEND,0,0,0,1,800,135,31659,695738,0,0,,0,0,0,0,UP,1,1,0,,0,347258,0,,1,5,0,,135,,1,0,,4,,,,0,105,30,0,0,0,,,,,0,0,0,0,0,0,331832,,,0,1,16,17,
      eof
    end

    let :backends do
      {"Stats"=>"UP", "horizon"=>"DOWN", "keystone-1"=>"UP", "keystone-2"=>"UP"}
    end

    before :each do
      allow(TestCommon::Settings.hiera).to receive(:lookup).with('management_vip', nil, {}).and_return('127.0.0.1')
      allow(TestCommon::Settings.hiera).to receive(:lookup).with('controller_node_address', nil, {}).and_return('127.0.0.1')
      allow(subject).to receive(:csv).and_return(csv)
    end

    it 'can get the HAProxy stats url' do
      expect(subject.stats_url).to eq('http://127.0.0.1:10000/;csv')
    end

    it 'can parse stats csv' do
      expect(subject.backends).to eq(backends)
    end

    it 'can chack if a backend exists' do
      expect(subject.backend_present? 'horizon').to eq true
      expect(subject.backend_present? 'MISSING').to eq false
    end

    it 'can chack if a backend is up' do
      expect(subject.backend_up? 'horizon').to eq false
      expect(subject.backend_up? 'keystone-1').to eq true
      expect(subject.backend_up? 'MISSING').to eq false
    end

  end

  context TestCommon::Process do

    let(:full_ps) do
      <<-eos
1   0 /bin/init
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

    let(:short_ps) do
      <<-eos
/bin/init
/usr/bin/python nova-api.py
/usr/bin/python nova-api.py
/usr/bin/python nova-api.py
/usr/bin/python nova-api.py
/usr/bin/python cinder-volume.py
/usr/sbin/tgtd
/usr/bin/python neutron.py
/usr/sbin/dnsmasq
/usr/sbin/apache2
/usr/bin/python keystone.py
      eos
    end

    let(:pstree) do
      {
          1 => {
              :children => [100, 104, 106, 108, 109],
              :ppid => 0,
              :pid => 1,
              :cmd => "/bin/init"
          },
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

    let(:pslist) do
      [
          "/bin/init",
          "/usr/bin/python nova-api.py",
          "/usr/bin/python nova-api.py",
          "/usr/bin/python nova-api.py",
          "/usr/bin/python nova-api.py",
          "/usr/bin/python cinder-volume.py",
          "/usr/sbin/tgtd",
          "/usr/bin/python neutron.py",
          "/usr/sbin/dnsmasq",
          "/usr/sbin/apache2",
          "/usr/bin/python keystone.py"
      ]
    end

    before :each do
      allow(TestCommon::Cmd).to receive(:run).with('ps haxo cmd').and_return([short_ps, 0])
      allow(TestCommon::Cmd).to receive(:run).with('ps haxo pid,ppid,cmd').and_return([full_ps, 0])
    end

    it 'can check if command runs successfully' do
      allow(TestCommon::Cmd).to receive(:run).with('/bin/true').and_return(['', 0])
      allow(TestCommon::Cmd).to receive(:run).with('/bin/false').and_return(['', 1])
      expect(subject.run_successful? '/bin/true').to eq true
      expect(subject.run_successful? '/bin/false').to eq false
    end

    it 'can check if a command can be found' do
      cmd = "which 'my_command' 1>/dev/null 2>/dev/null"
      allow(TestCommon::Cmd).to receive(:run).with(cmd).and_return(['', 0])
      expect(subject.command_present? 'my_command').to eq true
      allow(TestCommon::Cmd).to receive(:run).with(cmd).and_return(['', 1])
      expect(subject.command_present? 'my_command').to eq false
    end

    it 'can parse the process tree' do
      expect(subject.tree).to eq(pstree)
    end

    it 'can get the process list' do
      expect(subject.list).to eq(pslist)
    end

    it 'can find if a process is running' do
      expect(subject.running? 'apache2').to eq true
      expect(subject.running? 'nginx').to eq false
    end
  end

  context TestCommon::MySQL do
    let :databases do
      <<-eof
mysql
test
nova
      eof
    end

    it 'can form mysql queries without auth' do
      subject.no_auth
      cmd = %q(mysql --raw --skip-column-names --batch --execute='show databases')
      expect(TestCommon::Cmd).to receive(:run).with(cmd).and_return(['',0])
      subject.query 'show databases'
    end

    it 'can form mysql queries with auth' do
      subject.user = 'user'
      subject.pass = 'pass'
      subject.db = 'mydb'
      subject.port = '123'
      subject.host = 'myhost'
      cmd = %q(mysql --raw --skip-column-names --batch --execute='show databases' --host='myhost' --user='user' --password='pass' --port='123' --database='mydb')
      expect(TestCommon::Cmd).to receive(:run).with(cmd).and_return(['',0])
      subject.query 'show databases'
    end

    it 'can check is there is connection' do
      allow(subject).to receive(:query).and_return(['',0])
      expect(subject.connection?).to eq true
      allow(subject).to receive(:query).and_return(['',1])
      expect(subject.connection?).to eq false
    end

    it 'can get the list of databases' do
      allow(subject).to receive(:query).and_return([databases,0])
      expect(subject.databases).to eq(%w(mysql test nova))
      subject.reset
      allow(subject).to receive(:query).and_return([databases,1])
      expect(subject.databases).to eq nil
    end

    it 'can determine if database exists' do
      allow(subject).to receive(:query).and_return([databases,0])
      expect(subject.database_exists? 'test').to eq true
      expect(subject.database_exists? 'MISSING').to eq false
      subject.reset
      allow(subject).to receive(:query).and_return([databases,1])
      expect(subject.database_exists? 'test').to eq nil
    end
  end

  context TestCommon::Pacemaker do
    let :crm_resource_l do
      <<-eof
p_haproxy:0
p_dns:0
p_ntp:0
p_mysql:0
      eof
    end

    it 'can check if pacemaker is online' do
      allow(TestCommon::Cmd).to receive(:run).with('cibadmin -Q').and_return(['',0])
      expect(subject.online?).to eq true
      allow(TestCommon::Cmd).to receive(:run).with('cibadmin -Q').and_return(['',1])
      expect(subject.online?).to eq false
    end

    it 'can get the list of the primitives' do
      allow(TestCommon::Cmd).to receive(:run).with('crm_resource -l').and_return([crm_resource_l,0])
      expect(subject.primitives).to eq(%w(p_haproxy p_dns p_ntp p_mysql))
    end

    it 'can check if a primitive is present' do
      allow(TestCommon::Cmd).to receive(:run).with('crm_resource -l').and_return([crm_resource_l,0])
      expect(subject.primitive_present? 'p_dns').to eq true
      expect(subject.primitive_present? 'MISSING').to eq false
    end

    it 'can check if primitive is started' do
      allow(TestCommon::Cmd).to receive(:run).with('crm_resource -r p_haproxy -W 2>&1').and_return(['resource p_haproxy is running on: node-1',0])
      expect(subject.primitive_started? 'clone_p_haproxy').to eq true
      allow(TestCommon::Cmd).to receive(:run).with('crm_resource -r p_haproxy -W 2>&1').and_return(['resource p_haproxy is NOT running',0])
      expect(subject.primitive_started? 'clone_p_haproxy').to eq false
      allow(TestCommon::Cmd).to receive(:run).with('crm_resource -r MISSING -W 2>&1').and_return(['',1])
      expect(subject.primitive_started? 'MISSING').to eq nil
    end
  end

  context TestCommon::Facts do
    before :each do
      allow(Facter).to receive(:value).with('kernel').and_return('Linux')
    end

    it 'can get a facter value' do
      expect(subject.value 'kernel').to eq 'Linux'
    end

    it 'can get a facter value by index or method' do
      expect(subject['kernel']).to eq 'Linux'
      expect(subject.kernel).to eq 'Linux'
    end
  end

  context TestCommon::Package do

    let(:deb_packages) do
      <<-eos
mc|3:4.8.11-1|deinstall ok config-files
ipcalc|0.41-4|install ok installed
iproute|3.12.0-2|install ok installed
iptables|1.4.21-1ubuntu1|install ok installed
ntpdate|4.2.6.p5+dfsg-3ubuntu2|install ok installed
mc|3:4.8.11-1|install ok installed
      eos
    end

    let(:deb_packages_list) do
      {
          "iptables"=>"1.4.21-1ubuntu1",
          "iproute"=>"3.12.0-2",
          "ipcalc"=>"0.41-4",
          "ntpdate" =>"4.2.6.p5+dfsg-3ubuntu2",
          "mc" => "3:4.8.11-1",
      }
    end

    let(:rpm_packages) do
      <<-eos
iproute|2.6.32-130.el6.netns.2.mira1
util-linux-ng|2.17.2-12.14.el6_5
udev|147-2.51.el6
device-mapper|1.02.79-8.el6
openssh|5.3p1-94.el6
ntpdate|4.2.6p5-1.el6
mc|1:4.7.0.2-3.el6
      eos
    end

    let(:rpm_packages_list) do
      {
          "util-linux-ng"=>"2.17.2-12.14.el6_5",
          "iproute"=>"2.6.32-130.el6.netns.2.mira1",
          "openssh"=>"5.3p1-94.el6",
          "udev"=>"147-2.51.el6",
          "device-mapper"=>"1.02.79-8.el6",
          "ntpdate"=>"4.2.6p5-1.el6",
          "mc"=>"1:4.7.0.2-3.el6",
      }
    end

    context 'on a Debian system' do
      before :each do
        TestCommon::Package.reset
        TestCommon::Facts.reset
        allow(Facter).to receive(:value).with('osfamily').and_return('Debian')
        allow(TestCommon::Package).to receive(:get_deb_packages).and_return(deb_packages)
      end

      it 'can get a list of packages' do
        expect(subject.installed_packages).to eq(deb_packages_list)
      end

      it 'it can check if a package is installed' do
        expect(subject.is_installed? 'mc').to eq true
        expect(subject.is_installed? 'nginx').to eq false
      end
    end

    context 'on a RedHat system' do
      before :each do
        TestCommon::Package.reset
        TestCommon::Facts.reset
        allow(Facter).to receive(:value).with('osfamily').and_return('RedHat')
        allow(TestCommon::Package).to receive(:get_rpm_packages).and_return(rpm_packages)
      end

      it 'can get a list of packages' do
        expect(subject.installed_packages).to eq(rpm_packages_list)
      end

      it 'it can check if a package is installed' do
        expect(subject.is_installed? 'mc').to eq true
        expect(subject.is_installed? 'nginx').to eq false
      end
    end

  end

  describe TestCommon::Network do

    let :iptables_save do
      <<-eof
-A INPUT -p tcp -m multiport --ports 8777 -m comment --comment "121 ceilometer" -j ACCEPT
-A INPUT -p tcp -m multiport --dports 8386 -m comment --comment "201 sahara-all" -j ACCEPT
-A INPUT -p tcp -m multiport --dports 8004 -m comment --comment "204 heat-api" -j ACCEPT
      eof
    end

    let :ip_a do
      <<-eof
7: br-mgmt: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN
    link/ether 0e:41:54:77:e4:f3 brd ff:ff:ff:ff:ff:ff
    inet 192.168.0.6/24 scope global br-mgmt
    inet6 fe80::f82b:c5ff:fe8c:6cf1/64 scope link
       valid_lft forever preferred_lft forever
8: br-storage: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN
    link/ether 52:54:00:00:01:04 brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.2/24 scope global br-storage
    inet6 fe80::182b:e1ff:fe17:8876/64 scope link
       valid_lft forever preferred_lft forever
      eof
    end

    let :ip_r do
      <<-eof
192.168.0.0/24 dev br-mgmt  proto kernel  scope link  src 192.168.0.6
169.254.0.0/16 dev eth2  scope link  metric 1004
default via 172.16.0.1 dev br-ex
      eof
    end

    it 'can check is the url is accessible' do
      allow(TestCommon::Cmd).to receive(:run).with("curl --fail 'http://localhost' 1>/dev/null 2>/dev/null").and_return(['',0])
      expect(subject.url_accessible? 'http://localhost').to eq true
      allow(TestCommon::Cmd).to receive(:run).with("curl --fail 'http://localhost' 1>/dev/null 2>/dev/null").and_return(['',1])
      expect(subject.url_accessible? 'http://localhost').to eq false
    end

    it 'can check if tcp connection to a socket is possible' do
      allow(TCPSocket).to receive(:open).with('localhost', 123).and_return(nil)
      expect(subject.connection? 'localhost', 123).to eq true
      allow(TCPSocket).to receive(:open).with('localhost', 123).and_raise 'error'
      expect(subject.connection? 'localhost', 123).to eq false
    end

    it 'can get a list of the commented iptables rules' do
      allow(TestCommon::Cmd).to receive(:run).with('iptables-save').and_return([iptables_save,0])
      expect(subject.iptables_rules).to eq %w(ceilometer sahara-all heat-api)
      subject.reset
      allow(TestCommon::Cmd).to receive(:run).with('iptables-save').and_return([iptables_save,1])
      expect(subject.iptables_rules).to eq nil
    end

    it 'can get a list of IP addresses' do
      allow(TestCommon::Cmd).to receive(:run).with('ip addr').and_return([ip_a,0])
      expect(subject.ips).to eq %w(192.168.0.6 192.168.1.2)
    end

    it 'can get a default router' do
      allow(TestCommon::Cmd).to receive(:run).with('ip route').and_return([ip_r,0])
      expect(subject.default_router).to eq '172.16.0.1'
    end

    it 'can check if a host is pingable' do
      allow(TestCommon::Cmd).to receive(:run).with("ping -q -c 1 -W 3 '127.0.0.1'").and_return(['',0])
      expect(subject.ping? '127.0.0.1').to eq true
      allow(TestCommon::Cmd).to receive(:run).with("ping -q -c 1 -W 3 '127.0.0.1'").and_return(['',1])
      expect(subject.ping? '127.0.0.1').to eq false
    end
  end

  describe TestCommon::Config do

    let :ini do
      <<-eof
#data
a=1
[sec1]
b=2
c=
[default]
c=3
#d=4
#e=5
      eof
    end

    let :ini_data do
      {"default/a"=>"1", "sec1/b"=>"2", "default/c"=>"3", "sec1/c" => ''}
    end

    before :each do
      allow(File).to receive(:read).with('myfile').and_return(ini)
    end

    it 'can parse an ini file' do
      expect(subject.ini_file 'myfile').to eq(ini_data)
    end

    it 'can check if a value is present in an ini config' do
      expect(subject.value? 'myfile', 'default/a', '1').to eq true
      expect(subject.value? 'myfile', 'default/a', '2').to eq false
      expect(subject.value? 'myfile', 'DEFAULT/a', '1').to eq true
      expect(subject.value? 'myfile', 'sec1/b', '2').to eq true
      expect(subject.value? 'myfile', 'sec1/b', 2).to eq true
      expect(subject.value? 'myfile', 'default/d', '4').to eq false
      expect(subject.value? 'myfile', 'sec1/missing', '?').to eq false
      expect(subject.value? 'myfile', 'sec1/c', '').to eq true
      expect(subject.value? 'myfile', 'sec1/missing', '').to eq false
      expect(subject.value? 'myfile', 'sec1/missing', nil).to eq true
      expect(subject.value? 'myfile', 'default/a', nil).to eq false
    end

    it 'can check if a string is present in a file' do
      expect(subject.has_line? 'myfile', 'a=1').to eq true
      expect(subject.has_line? 'myfile', 'hello').to eq false
      expect(subject.has_line? 'myfile', /^#e=5$/).to eq true
      expect(subject.has_line? 'myfile', /a=\d+/).to eq true
      expect(subject.has_line? 'myfile', /^xyz/).to eq false
    end
  end
end
