#! /usr/bin/env ruby
require 'spec_helper'

require 'puppet/ssl/host'
require 'puppet/indirector/certificate_request/ca'

describe Puppet::SSL::CertificateRequest::Ca, :unless => Puppet.features.microsoft_windows? do
  include PuppetSpec::Files

  before :each do
    Puppet[:ssldir] = tmpdir('ssl')

    Puppet::SSL::Host.ca_location = :local
    Puppet[:localcacert] = Puppet[:cacert]

    @ca = Puppet::SSL::CertificateAuthority.new
  end

  after :all do
    Puppet::SSL::Host.ca_location = :none
  end

  it "should have documentation" do
    Puppet::SSL::CertificateRequest::Ca.doc.should be_instance_of(String)
  end

  it "should use the :csrdir as the collection directory" do
    Puppet[:csrdir] = File.expand_path("/request/dir")
    Puppet::SSL::CertificateRequest::Ca.collection_directory.should == Puppet[:csrdir]
  end

  it "should overwrite the previous certificate request if allow_duplicate_certs is true" do
    Puppet[:allow_duplicate_certs] = true
    host = Puppet::SSL::Host.new("foo")
    host.generate_certificate_request
    @ca.sign(host.name)

    Puppet::SSL::Host.indirection.find("foo").generate_certificate_request

    Puppet::SSL::Certificate.indirection.find("foo").name.should == "foo"
    Puppet::SSL::CertificateRequest.indirection.find("foo").name.should == "foo"
    Puppet::SSL::Host.indirection.find("foo").state.should == "requested"
  end

  it "should reject a new certificate request if allow_duplicate_certs is false" do
    Puppet[:allow_duplicate_certs] = false
    host = Puppet::SSL::Host.new("bar")
    host.generate_certificate_request
    @ca.sign(host.name)

    expect { Puppet::SSL::Host.indirection.find("bar").generate_certificate_request }.to raise_error(/ignoring certificate request/)

    Puppet::SSL::Certificate.indirection.find("bar").name.should == "bar"
    Puppet::SSL::CertificateRequest.indirection.find("bar").should be_nil
    Puppet::SSL::Host.indirection.find("bar").state.should == "signed"
  end
end
