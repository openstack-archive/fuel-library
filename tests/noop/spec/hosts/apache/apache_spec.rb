require 'spec_helper'
require 'shared-examples'
manifest = 'apache/apache.pp'

describe manifest do
  shared_examples 'catalog' do

    internal_address = Noop.node_hash['internal_address']

    # Apache
    # IP:ports
    ['80', '5000', '35357'].each do | port |
      it "should declare apache::listen for #{internal_address}:#{port}" do
        should contain_apache__listen("#{internal_address}:#{port}")
      end
      it "should declare apache::namevirtualhost for #{internal_address}:#{port}" do
        should contain_apache__namevirtualhost("#{internal_address}:#{port}")
      end
    end
    # wildcards
    ['8888'].each do | port |
      it "should declare apache::listen for #{port}" do
        should contain_apache__listen(port)
      end
      it "should declare apache::namevirtualhost for *:#{port}" do
        should contain_apache__namevirtualhost("*:#{port}")
      end
    end

  end
  test_ubuntu_and_centos manifest
end

