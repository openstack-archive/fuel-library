require 'spec_helper'
require 'shared-examples'
require 'pry'
manifest = 'virtual_ips/virtual_ips.pp'

describe manifest do
  shared_examples 'catalog' do
    # TODO: test vip parameters too

    it "should define 'public' VIP" do
      expect(subject).to contain_cluster__virtual_ip('public')
    end

    it "should define 'management' VIP" do
      expect(subject).to contain_cluster__virtual_ip('public')
    end

    it "should define 'vrouter_pub' VIP" do
      expect(subject).to contain_cluster__virtual_ip('public')
    end

    it "should define 'vrouter' VIP" do
      expect(subject).to contain_cluster__virtual_ip('public')
    end
  end

  test_ubuntu_and_centos manifest
end
