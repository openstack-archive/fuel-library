require 'spec_helper'

describe 'haproxy::base', :type => :class do
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

          it { should contain_class('concat::setup') }

          it 'should set up /etc/haproxy/haproxy.cfg as a concat resource' do
            subject.should contain_concat('/etc/haproxy/haproxy.cfg').with(
              'owner'  => '0',
              'group'  => '0',
              'mode'   => '0644'
            )
          end

          it 'should contain a haproxy-header concat fragment' do
            subject.should contain_concat__fragment('haproxy-header').with(
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

          context 'when use_include is enabled' do
            let(:params) do
              {'use_include' => true}
            end

            it 'should manage the conf.d directory' do
              subject.should contain_file('/etc/haproxy/conf.d').with(
                'ensure' => 'directory'
              )
            end

            it 'should include *.cfg from the fragments directory' do
              subject.should contain_concat__fragment('haproxy-include').with_content(
                %r{^include conf.d/\*\.cfg$}
              )
            end
          end

          it 'should manage the chroot directory' do
            subject.should contain_file('/var/lib/haproxy').with(
              'ensure' => 'directory'
            )
          end
        end
      end
    end
  end
end
