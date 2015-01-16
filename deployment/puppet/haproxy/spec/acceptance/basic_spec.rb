require 'spec_helper_acceptance'

# C9708 C9709 WONTFIX
describe "configuring haproxy", :unless => UNSUPPORTED_PLATFORMS.include?(fact('osfamily')) do
  # C9961
  describe 'not managing the service' do
    it 'should not listen on any ports' do
      pp = <<-EOS
      class { 'haproxy':
        service_manage => false,
      }
      haproxy::listen { 'stats':
        ipaddress => '127.0.0.1',
        ports     => ['9090','9091'],
        options   => {
          'mode'  => 'http',
          'stats' => ['uri /','auth puppet:puppet'],
        },
      }
      haproxy::listen { 'test00': ports => '80',}
      EOS
      apply_manifest(pp, :catch_failures => true)
    end

    describe port('9090') do
      it { should_not be_listening }
    end
    describe port('9091') do
      it { should_not be_listening }
    end
  end

  describe "configuring haproxy load balancing" do
    before :all do
    end

    describe "multiple ports" do
      it 'should be able to listen on an array of ports' do
        pp = <<-EOS
        class { 'haproxy': }
        haproxy::listen { 'stats':
          ipaddress => '127.0.0.1',
          ports     => ['9090','9091'],
          mode      => 'http',
          options   => { 'stats' => ['uri /','auth puppet:puppet'], },
        }
        EOS
        apply_manifest(pp, :catch_failures => true)
      end

      it 'should have stats listening on each port' do
        ['9090','9091'].each do |port|
          shell("/usr/bin/curl -u puppet:puppet localhost:#{port}") do |r|
            r.stdout.should =~ /HAProxy/
            r.exit_code.should == 0
          end
        end
      end
    end
  end

  # C9934
  describe "uninstalling haproxy" do
    it 'removes it' do
      pp = <<-EOS
        class { 'haproxy':
          package_ensure => 'absent',
          service_ensure => 'stopped',
        }
      EOS
      apply_manifest(pp, :catch_failures => true)
    end
    describe package('haproxy') do
      it { should_not be_installed }
    end
  end

  # C9935 C9939
  describe "disabling haproxy" do
    it 'stops the service' do
      pp = <<-EOS
        class { 'haproxy':
          service_ensure => 'stopped',
        }
      EOS
      apply_manifest(pp, :catch_failures => true)
    end
    describe service('haproxy') do
      it { should_not be_running }
      it { should_not be_enabled }
    end
  end
end
