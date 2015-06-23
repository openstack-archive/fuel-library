require 'spec_helper_acceptance'

describe "frontend backend defines", :unless => UNSUPPORTED_PLATFORMS.include?(fact('osfamily')) do
  it 'should be able to configure the frontend/backend with puppet' do
    pp = <<-EOS
      class { 'haproxy': }
      haproxy::frontend { 'app00':
        ipaddress => $::ipaddress_lo,
        mode      => 'http',
        ports     => '5555',
        options   => { 'default_backend' => 'app00' },
      }
      haproxy::backend { 'app00':
        collect_exported => false,
        options          => { 'mode' => 'http' },
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
  # C9945
  it "should do a curl against the LB to make sure it gets a response from each port" do
    shell('curl localhost:5555').stdout.chomp.should match(/Response on 555(6|7)/)
    shell('curl localhost:5555').stdout.chomp.should match(/Response on 555(6|7)/)
  end

  it 'should be able to configure the frontend/backend with one node up' do
    pp = <<-EOS
      class { 'haproxy': }
      haproxy::frontend { 'app00':
        ipaddress => $::ipaddress_lo,
        mode      => 'http',
        ports     => '5555',
        options   => { 'default_backend' => 'app00' },
      }
      haproxy::backend { 'app00':
        collect_exported => false,
        options          => { 'mode' => 'http' },
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

  # C9951
  it "should do a curl against the LB to make sure it gets a response from each port" do
    shell('curl localhost:5555').stdout.chomp.should match(/Response on 5556/)
    shell('curl localhost:5555').stdout.chomp.should match(/Response on 5556/)
  end

  it 'having no address set but setting bind' do
    pp = <<-EOS
      class { 'haproxy': }
        haproxy::frontend { 'app0':
        bind =>
          { '127.0.0.1:5555' => [] }
          ,
        }
    EOS
    apply_manifest(pp, :catch_failures => true)
  end

end
