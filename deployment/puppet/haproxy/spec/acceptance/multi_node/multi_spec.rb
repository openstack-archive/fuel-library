require 'spec_helper_acceptance'

if hosts.length >= 3
  describe "configuring multi-node loadbalancer" do
    let(:ipaddresses) do
      hosts_as('slave').inject({}) do |memo,host|
        memo[host] = fact_on host, "ipaddress_eth1"
        memo
      end
    end

    hosts_as('slave').each do |host|
      it "should be able to configure the daemon on #{host}" do
        pp = <<-EOS
          package { 'nc': ensure => present, }
          package { 'screen': ensure => present, }
          service { 'iptables': ensure => stopped, }
        EOS
        apply_manifest_on(host, pp, :catch_failures => true)
        on host, %{echo 'while :; do echo "#{host}" | nc -l 5555 ; done' > /root/script.sh}
        on host, %{/usr/bin/screen -dmS slave sh /root/script.sh} #, { :pty => true }
        sleep 1
        on host, %{netstat -tnl|grep ':5555\\s'}
      end
    end

    it 'should be able to configure the loadbalancer with puppet' do
      pp = <<-EOS
        class { 'haproxy': }
        haproxy::listen { 'app00':
          ipaddress => $::ipaddress_lo,
          ports     => '5555',
        }
        #{ipaddresses.collect do |host,ipaddress|
          %{
        haproxy::balancermember { '#{host}':
          listening_service => 'app00',
          ports             => '5555',
          ipaddresses       => '#{ipaddress}',
        }}
          end.join
        }
      EOS
      apply_manifest(pp, :catch_failures => true)
    end

    # This is not great since it depends on the ordering served by the load
    # balancer. Something with retries would be better.
    hosts_as('slave').each do |slave|
      it "should do a curl against the LB to make sure it gets a response from #{slave}" do
        shell('curl localhost:5555').stdout.chomp.should eq(slave.to_s)
      end
    end
  end
end
