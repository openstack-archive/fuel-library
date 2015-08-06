#! /usr/bin/env ruby
require 'spec_helper'

require 'puppet/ssl/certificate_authority'

describe Puppet::SSL::CertificateAuthority, :unless => Puppet.features.microsoft_windows? do
  include PuppetSpec::Files

  let(:ca) { @ca }

  before do
    dir = tmpdir("ca_integration_testing")

    Puppet.settings[:confdir] = dir
    Puppet.settings[:vardir] = dir
    Puppet.settings[:group] = Process.gid

    Puppet::SSL::Host.ca_location = :local

    # this has the side-effect of creating the various directories that we need
    @ca = Puppet::SSL::CertificateAuthority.new
  end

  it "should be able to generate a new host certificate" do
    ca.generate("newhost")

    Puppet::SSL::Certificate.indirection.find("newhost").should be_instance_of(Puppet::SSL::Certificate)
  end

  it "should be able to revoke a host certificate" do
    ca.generate("newhost")

    ca.revoke("newhost")

    expect { ca.verify("newhost") }.to raise_error(Puppet::SSL::CertificateAuthority::CertificateVerificationError, "certificate revoked")
  end

  describe "when signing certificates" do
    it "should save the signed certificate" do
      host = certificate_request_for("luke.madstop.com")

      ca.sign("luke.madstop.com")

      Puppet::SSL::Certificate.indirection.find("luke.madstop.com").should be_instance_of(Puppet::SSL::Certificate)
    end

    it "should be able to sign multiple certificates" do
      host = certificate_request_for("luke.madstop.com")
      other = certificate_request_for("other.madstop.com")

      ca.sign("luke.madstop.com")
      ca.sign("other.madstop.com")

      Puppet::SSL::Certificate.indirection.find("other.madstop.com").should be_instance_of(Puppet::SSL::Certificate)
      Puppet::SSL::Certificate.indirection.find("luke.madstop.com").should be_instance_of(Puppet::SSL::Certificate)
    end

    it "should save the signed certificate to the :signeddir" do
      host = certificate_request_for("luke.madstop.com")

      ca.sign("luke.madstop.com")

      client_cert = File.join(Puppet[:signeddir], "luke.madstop.com.pem")
      File.read(client_cert).should == Puppet::SSL::Certificate.indirection.find("luke.madstop.com").content.to_s
    end

    it "should save valid certificates" do
      host = certificate_request_for("luke.madstop.com")

      ca.sign("luke.madstop.com")

      unless ssl = Puppet::Util::which('openssl')
        pending "No ssl available"
      else
        ca_cert = Puppet[:cacert]
        client_cert = File.join(Puppet[:signeddir], "luke.madstop.com.pem")
        output = %x{openssl verify -CAfile #{ca_cert} #{client_cert}}
        $CHILD_STATUS.should == 0
      end
    end

    it "should verify proof of possession when signing certificates" do
      host = certificate_request_for("luke.madstop.com")
      csr = host.certificate_request
      wrong_key = Puppet::SSL::Key.new(host.name)
      wrong_key.generate

      csr.content.public_key = wrong_key.content.public_key
      # The correct key has to be removed so we can save the incorrect one
      Puppet::SSL::CertificateRequest.indirection.destroy(host.name)
      Puppet::SSL::CertificateRequest.indirection.save(csr)

      expect {
        ca.sign(host.name)
      }.to raise_error(
        Puppet::SSL::CertificateAuthority::CertificateSigningError,
        "CSR contains a public key that does not correspond to the signing key"
      )
    end
  end

  it "allows autosigning certificates concurrently", :unless => Puppet::Util::Platform.windows? do
    Puppet[:autosign] = true
    hosts = (0..4).collect { |i| certificate_request_for("host#{i}") }

    run_in_parallel(5) do |i|
      ca.autosign(Puppet::SSL::CertificateRequest.indirection.find(hosts[i].name))
    end

    certs = hosts.collect { |host| Puppet::SSL::Certificate.indirection.find(host.name).content }
    serial_numbers = certs.collect(&:serial)

    serial_numbers.sort.should == [2, 3, 4, 5, 6] # serial 1 is the ca certificate
  end

  def certificate_request_for(hostname)
    key = Puppet::SSL::Key.new(hostname)
    key.generate

    host = Puppet::SSL::Host.new(hostname)
    host.key = key
    host.generate_certificate_request

    host
  end

  def run_in_parallel(number)
    children = []
    number.times do |i|
      children << Kernel.fork do
        yield i
      end
    end

    children.each { |pid| Process.wait(pid) }
  end
end
