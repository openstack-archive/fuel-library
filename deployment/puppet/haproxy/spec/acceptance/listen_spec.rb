require 'spec_helper_acceptance'

describe "listen define", :unless => UNSUPPORTED_PLATFORMS.include?(fact('osfamily')) do
  it 'should be able to configure the listen with puppet' do
    pp = <<-EOS
      class { 'haproxy': }
      haproxy::listen { 'app00':
        ipaddress => $::ipaddress_lo,
        ports     => '5555',
        mode      => 'http',
      }
      haproxy::balancermember { 'port 5556':
        listening_service => 'app00',
        ports             => '5556',
      }
      haproxy::balancermember { 'port 5557':
        listening_service => 'app00',
        ports             => '5557',
      }
    EOS
    apply_manifest(pp, :catch_failures => true)
  end

  # This is not great since it depends on the ordering served by the load
  # balancer. Something with retries would be better.
  # C9876 C9877 C9941 C9954
  it "should do a curl against the LB to make sure it gets a response from each port" do
    shell('curl localhost:5555').stdout.chomp.should match(/Response on 555(6|7)/)
    shell('curl localhost:5555').stdout.chomp.should match(/Response on 555(6|7)/)
  end

  # C9955
  it 'should be able to configure the listen active/passive' do
    pp = <<-EOS
      class { 'haproxy': }
      haproxy::listen { 'app00':
        ipaddress => $::ipaddress_lo,
        ports     => '5555',
        mode      => 'http',
        options   => { 'option' => 'httpchk', },
      }
      haproxy::balancermember { 'port 5556':
        listening_service => 'app00',
        ports             => '5556',
        options           => 'check',
      }
      haproxy::balancermember { 'port 5557':
        listening_service => 'app00',
        ports             => '5557',
        options           => ['check','backup'],
      }
    EOS
    apply_manifest(pp, :catch_failures => true)
    apply_manifest(pp, :catch_changes  => true)
  end

  it "should do a curl against the LB to make sure it only gets a response from the active port" do
    sleep(10)
    shell('curl localhost:5555').stdout.chomp.should match(/Response on 5556/)
    shell('curl localhost:5555').stdout.chomp.should match(/Response on 5556/)
  end

  # C9942 C9944 WONTFIX

  # C9943
  it 'should be able to configure the listen with only one node up' do
    pp = <<-EOS
      class { 'haproxy': }
      haproxy::listen { 'app00':
        ipaddress => $::ipaddress_lo,
        ports     => '5555',
        mode      => 'http',
      }
      haproxy::balancermember { 'port 5556':
        listening_service => 'app00',
        ports             => '5556',
      }
      haproxy::balancermember { 'port 5557':
        listening_service => 'app00',
        ports             => '5558',
      }
    EOS
    apply_manifest(pp, :catch_failures => true)
  end

  it "should do a curl against the LB to make sure it gets a response from each port" do
    shell('curl localhost:5555').stdout.chomp.should match(/Response on 5556/)
    shell('curl localhost:5555').stdout.chomp.should match(/Response on 5556/)
  end

  it 'having no address set but setting bind' do
    pp = <<-EOS
      class { 'haproxy': }
        haproxy::listen { 'app0':
        bind =>
          { '127.0.0.1:5555' => [] }
          ,
        }
    EOS
    apply_manifest(pp, :catch_failures => true)
  end

end
