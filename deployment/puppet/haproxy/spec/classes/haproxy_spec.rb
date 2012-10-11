require 'spec_helper'

describe 'haproxy', :type => :class do
  let(:default_facts) do
    {
      :concat_basedir => '/dne',
      :ipaddress      => '10.10.10.10'
    }
  end
  context 'on supported platforms' do
    describe 'for OS-agnostic configuration' do
      ['Debian', 'RedHat'].each do |osfamily|
        context "on #{osfamily} family operatingsystems" do
          let(:facts) do
            { :osfamily => osfamily }.merge default_facts
          end
          let(:params) do
            {'enable' => true}
          end
          it { should include_class('concat::setup') }
          it 'should install the haproxy package' do
            subject.should contain_package('haproxy').with(
              'ensure' => 'present'
            )
          end
          it 'should install the haproxy service' do
            subject.should contain_service('haproxy').with(
              'ensure'     => 'running',
              'enable'     => 'true',
              'hasrestart' => 'true',
              'hasstatus'  => 'true',
              'require'    => [
                'Concat[/etc/haproxy/haproxy.cfg]',
                'File[/var/lib/haproxy]'
              ]
            )
          end
          it 'should set up /etc/haproxy/haproxy.cfg as a concat resource' do
            subject.should contain_concat('/etc/haproxy/haproxy.cfg').with(
              'owner' => '0',
              'group' => '0',
              'mode'  => '0644'
            )
          end
          it 'should manage the chroot directory' do
            subject.should contain_file('/var/lib/haproxy').with(
              'ensure' => 'directory'
            )
          end
          it 'should contain a header concat fragment' do
            subject.should contain_concat__fragment('00-header').with(
              'target'  => '/etc/haproxy/haproxy.cfg',
              'order'   => '01',
              'content' => "# This file managed by Puppet\n"
            )
          end
          it 'should contain a haproxy-base concat fragment' do
            subject.should contain_concat__fragment('haproxy-base').with(
              'target'  => '/etc/haproxy/haproxy.cfg',
              'order'   => '10'
            )
          end
          describe 'Base concat fragment contents' do
            let(:contents) { param_value(subject, 'concat::fragment', 'haproxy-base', 'content').split("\n") }
            it 'should contain global and defaults sections' do
              contents.should include('global')
              contents.should include('defaults')
            end
            it 'should log to an ip address for local0' do
              contents.should be_any { |match| match =~ /  log  \d+(\.\d+){3} local0/ }
            end
            it 'should specify the default chroot' do
              contents.should include('  chroot  /var/lib/haproxy')
            end
            it 'should specify the correct user' do
              contents.should include('  user  haproxy')
            end
            it 'should specify the correct group' do
              contents.should include('  group  haproxy')
            end
            it 'should specify the correct pidfile' do
              contents.should include('  pidfile  /var/run/haproxy.pid')
            end
          end
        end
        context "on #{osfamily} family operatingsystems without managing the service" do
          let(:facts) do
            { :osfamily => osfamily }.merge default_facts
          end
          let(:params) do
            {
              'enable'         => true,
              'manage_service' => false,
            }
          end
          it { should include_class('concat::setup') }
          it 'should install the haproxy package' do
            subject.should contain_package('haproxy').with(
              'ensure' => 'present'
            )
          end
          it 'should install the haproxy service' do
            subject.should_not contain_service('haproxy')
          end
        end
      end
    end
    describe 'for OS-specific configuration' do
      context 'only on Debian family operatingsystems' do
        let(:facts) do
          { :osfamily => 'Debian' }.merge default_facts
        end
        it 'should manage haproxy service defaults' do
          subject.should contain_file('/etc/default/haproxy').with(
            'before'  => 'Service[haproxy]',
            'require' => 'Package[haproxy]'
          )
          verify_contents(subject, '/etc/default/haproxy', ['ENABLED=1'])
        end
      end
      context 'only on RedHat family operatingsystems' do
        let(:facts) do
          { :osfamily => 'RedHat' }.merge default_facts
        end
      end
    end
  end
  context 'on unsupported operatingsystems' do
    let(:facts) do
      { :osfamily => 'RainbowUnicorn' }.merge default_facts
    end
    it do
      expect {
        should contain_service('haproxy')
      }.to raise_error(Puppet::Error, /operating system is not supported with the haproxy module/)
    end
  end
end
