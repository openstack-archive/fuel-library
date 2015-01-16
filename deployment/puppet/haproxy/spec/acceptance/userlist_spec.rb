require 'spec_helper_acceptance'

# lucid ships with haproxy 1.3 which does not have userlist support by default
describe "userlist define", :unless => (UNSUPPORTED_PLATFORMS.include?(fact('osfamily')) or (fact('lsbdistcodename') == 'lucid') or (fact('osfamily') == 'RedHat' and fact('operatingsystemmajrelease') == '5')) do
  it 'should be able to configure the listen with puppet' do
    # C9966 C9970
    pp = <<-EOS
      class { 'haproxy': }
      haproxy::userlist { 'users_groups':
        users  => [
          'test1 insecure-password elgato',
          'test2 insecure-password elgato',
          '',
        ],
        groups => [
          'g1 users test1',
          '',
        ]
      }

      haproxy::listen { 'app00':
        collect_exported => false,
        ipaddress        => $::ipaddress_lo,
        ports            => '5555',
        options          => {
          'mode'         => 'http',
          'acl'          => 'auth_ok http_auth(users_groups)',
          'http-request' => 'auth realm Okay if !auth_ok',
        },
      }
      haproxy::balancermember { 'app00 port 5556':
        listening_service => 'app00',
        ports             => '5556',
      }

      haproxy::listen { 'app01':
        collect_exported => false,
        ipaddress        => $::ipaddress_lo,
        ports            => '5554',
        options          => {
          'mode'         => 'http',
          'acl'          => 'auth_ok http_auth_group(users_groups) g1',
          'http-request' => 'auth realm Okay if !auth_ok',
        },
      }
      haproxy::balancermember { 'app01 port 5556':
        listening_service => 'app01',
        ports             => '5556',
      }
    EOS
    apply_manifest(pp, :catch_failures => true)
  end

  # C9957
  it "test1 should auth as user" do
    shell('curl http://test1:elgato@localhost:5555').stdout.chomp.should eq('Response on 5556')
  end
  it "test2 should auth as user" do
    shell('curl http://test2:elgato@localhost:5555').stdout.chomp.should eq('Response on 5556')
  end

  # C9958
  it "should not auth as user" do
    shell('curl http://test3:elgato@localhost:5555').stdout.chomp.should_not eq('Response on 5556')
  end

  # C9959
  it "should auth as group" do
    shell('curl http://test1:elgato@localhost:5554').stdout.chomp.should eq('Response on 5556')
  end

  # C9960
  it "should not auth as group" do
    shell('curl http://test2:elgato@localhost:5554').stdout.chomp.should_not eq('Response on 5556')
  end

  # C9965 C9967 C9968 C9969 WONTFIX
end
