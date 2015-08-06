require 'puppet/indirector'
require 'puppet/ssl'
require 'puppet/ssl/key'
require 'puppet/ssl/certificate'
require 'puppet/ssl/certificate_request'
require 'puppet/ssl/certificate_revocation_list'
require 'puppet/ssl/certificate_request_attributes'

# The class that manages all aspects of our SSL certificates --
# private keys, public keys, requests, etc.
class Puppet::SSL::Host
  # Yay, ruby's strange constant lookups.
  Key = Puppet::SSL::Key
  CA_NAME = Puppet::SSL::CA_NAME
  Certificate = Puppet::SSL::Certificate
  CertificateRequest = Puppet::SSL::CertificateRequest
  CertificateRevocationList = Puppet::SSL::CertificateRevocationList

  extend Puppet::Indirector
  indirects :certificate_status, :terminus_class => :file, :doc => <<DOC
    This indirection represents the host that ties a key, certificate, and certificate request together.
    The indirection key is the certificate CN (generally a hostname).
DOC

  attr_reader :name
  attr_accessor :ca

  attr_writer :key, :certificate, :certificate_request

  # This accessor is used in instances for indirector requests to hold desired state
  attr_accessor :desired_state

  def self.localhost
    return @localhost if @localhost
    @localhost = new
    @localhost.generate unless @localhost.certificate
    @localhost.key
    @localhost
  end

  def self.reset
    @localhost = nil
  end

  # This is the constant that people will use to mark that a given host is
  # a certificate authority.
  def self.ca_name
    CA_NAME
  end

  class << self
    attr_reader :ca_location
  end

  # Configure how our various classes interact with their various terminuses.
  def self.configure_indirection(terminus, cache = nil)
    Certificate.indirection.terminus_class = terminus
    CertificateRequest.indirection.terminus_class = terminus
    CertificateRevocationList.indirection.terminus_class = terminus

    host_map = {:ca => :file, :disabled_ca => nil, :file => nil, :rest => :rest}
    if term = host_map[terminus]
      self.indirection.terminus_class = term
    else
      self.indirection.reset_terminus_class
    end

    if cache
      # This is weird; we don't actually cache our keys, we
      # use what would otherwise be the cache as our normal
      # terminus.
      Key.indirection.terminus_class = cache
    else
      Key.indirection.terminus_class = terminus
    end

    if cache
      Certificate.indirection.cache_class = cache
      CertificateRequest.indirection.cache_class = cache
      CertificateRevocationList.indirection.cache_class = cache
    else
      # Make sure we have no cache configured.  puppet master
      # switches the configurations around a bit, so it's important
      # that we specify the configs for absolutely everything, every
      # time.
      Certificate.indirection.cache_class = nil
      CertificateRequest.indirection.cache_class = nil
      CertificateRevocationList.indirection.cache_class = nil
    end
  end

  CA_MODES = {
    # Our ca is local, so we use it as the ultimate source of information
    # And we cache files locally.
    :local => [:ca, :file],
    # We're a remote CA client.
    :remote => [:rest, :file],
    # We are the CA, so we don't have read/write access to the normal certificates.
    :only => [:ca],
    # We have no CA, so we just look in the local file store.
    :none => [:disabled_ca]
  }

  # Specify how we expect to interact with our certificate authority.
  def self.ca_location=(mode)
    modes = CA_MODES.collect { |m, vals| m.to_s }.join(", ")
    raise ArgumentError, "CA Mode can only be one of: #{modes}" unless CA_MODES.include?(mode)

    @ca_location = mode

    configure_indirection(*CA_MODES[@ca_location])
  end

  # Puppet::SSL::Host is actually indirected now so the original implementation
  # has been moved into the certificate_status indirector.  This method is in-use
  # in `puppet cert -c <certname>`.
  def self.destroy(name)
    indirection.destroy(name)
  end

  def self.from_pson(pson)
    instance = new(pson["name"])
    if pson["desired_state"]
      instance.desired_state = pson["desired_state"]
    end
    instance
  end

  # Puppet::SSL::Host is actually indirected now so the original implementation
  # has been moved into the certificate_status indirector.  This method does not
  # appear to be in use in `puppet cert -l`.
  def self.search(options = {})
    indirection.search("*", options)
  end

  # Is this a ca host, meaning that all of its files go in the CA location?
  def ca?
    ca
  end

  def key
    @key ||= Key.indirection.find(name)
  end

  # This is the private key; we can create it from scratch
  # with no inputs.
  def generate_key
    @key = Key.new(name)
    @key.generate
    begin
      Key.indirection.save(@key)
    rescue
      @key = nil
      raise
    end
    true
  end

  def certificate_request
    @certificate_request ||= CertificateRequest.indirection.find(name)
  end

  # Our certificate request requires the key but that's all.
  def generate_certificate_request(options = {})
    generate_key unless key

    # If this CSR is for the current machine...
    if name == Puppet[:certname].downcase
      # ...add our configured dns_alt_names
      if Puppet[:dns_alt_names] and Puppet[:dns_alt_names] != ''
        options[:dns_alt_names] ||= Puppet[:dns_alt_names]
      elsif Puppet::SSL::CertificateAuthority.ca? and fqdn = Facter.value(:fqdn) and domain = Facter.value(:domain)
        options[:dns_alt_names] = "puppet, #{fqdn}, puppet.#{domain}"
      end
    end

    csr_attributes = Puppet::SSL::CertificateRequestAttributes.new(Puppet[:csr_attributes])
    if csr_attributes.load
      options[:csr_attributes] = csr_attributes.custom_attributes
      options[:extension_requests] = csr_attributes.extension_requests
    end

    @certificate_request = CertificateRequest.new(name)
    @certificate_request.generate(key.content, options)
    begin
      CertificateRequest.indirection.save(@certificate_request)
    rescue
      @certificate_request = nil
      raise
    end

    true
  end

  def certificate
    unless @certificate
      generate_key unless key

      # get the CA cert first, since it's required for the normal cert
      # to be of any use.
      return nil unless Certificate.indirection.find("ca") unless ca?
      return nil unless @certificate = Certificate.indirection.find(name)

      validate_certificate_with_key
    end
    @certificate
  end

  def validate_certificate_with_key
    raise Puppet::Error, "No certificate to validate." unless certificate
    raise Puppet::Error, "No private key with which to validate certificate with fingerprint: #{certificate.fingerprint}" unless key
    unless certificate.content.check_private_key(key.content)
      raise Puppet::Error, <<ERROR_STRING
The certificate retrieved from the master does not match the agent's private key.
Certificate fingerprint: #{certificate.fingerprint}
To fix this, remove the certificate from both the master and the agent and then start a puppet run, which will automatically regenerate a certficate.
On the master:
  puppet cert clean #{Puppet[:certname]}
On the agent:
  rm -f #{Puppet[:hostcert]}
  puppet agent -t
ERROR_STRING
    end
  end

  # Generate all necessary parts of our ssl host.
  def generate
    generate_key unless key
    generate_certificate_request unless certificate_request

    # If we can get a CA instance, then we're a valid CA, and we
    # should use it to sign our request; else, just try to read
    # the cert.
    if ! certificate and ca = Puppet::SSL::CertificateAuthority.instance
      ca.sign(self.name, true)
    end
  end

  def initialize(name = nil)
    @name = (name || Puppet[:certname]).downcase
    Puppet::SSL::Base.validate_certname(@name)
    @key = @certificate = @certificate_request = nil
    @ca = (name == self.class.ca_name)
  end

  # Extract the public key from the private key.
  def public_key
    key.content.public_key
  end

  # Create/return a store that uses our SSL info to validate
  # connections.
  def ssl_store(purpose = OpenSSL::X509::PURPOSE_ANY)
    unless @ssl_store
      @ssl_store = OpenSSL::X509::Store.new
      @ssl_store.purpose = purpose

      # Use the file path here, because we don't want to cause
      # a lookup in the middle of setting our ssl connection.
      @ssl_store.add_file(Puppet[:localcacert])

      # If we're doing revocation and there's a CRL, add it to our store.
      if Puppet.settings[:certificate_revocation]
        if crl = Puppet::SSL::CertificateRevocationList.indirection.find(CA_NAME)
          @ssl_store.flags = OpenSSL::X509::V_FLAG_CRL_CHECK_ALL|OpenSSL::X509::V_FLAG_CRL_CHECK
          @ssl_store.add_crl(crl.content)
        end
      end
      return @ssl_store
    end
    @ssl_store
  end

  def to_data_hash
    my_cert = Puppet::SSL::Certificate.indirection.find(name)
    result = { :name  => name }

    my_state = state

    result[:state] = my_state
    result[:desired_state] = desired_state if desired_state

    thing_to_use = (my_state == 'requested') ? certificate_request : my_cert

    # this is for backwards-compatibility
    # we should deprecate it and transition people to using
    # pson[:fingerprints][:default]
    # It appears that we have no internal consumers of this api
    # --jeffweiss 30 aug 2012
    result[:fingerprint] = thing_to_use.fingerprint

    # The above fingerprint doesn't tell us what message digest algorithm was used
    # No problem, except that the default is changing between 2.7 and 3.0. Also, as
    # we move to FIPS 140-2 compliance, MD5 is no longer allowed (and, gasp, will
    # segfault in rubies older than 1.9.3)
    # So, when we add the newer fingerprints, we're explicit about the hashing
    # algorithm used.
    # --jeffweiss 31 july 2012
    result[:fingerprints] = {}
    result[:fingerprints][:default] = thing_to_use.fingerprint

    suitable_message_digest_algorithms.each do |md|
      result[:fingerprints][md] = thing_to_use.fingerprint md
    end
    result[:dns_alt_names] = thing_to_use.subject_alt_names

    result
  end

  def to_pson(*args)
    to_data_hash.to_pson(*args)
  end

  # eventually we'll probably want to move this somewhere else or make it
  # configurable
  # --jeffweiss 29 aug 2012
  def suitable_message_digest_algorithms
    [:SHA1, :SHA256, :SHA512]
  end

  # Attempt to retrieve a cert, if we don't already have one.
  def wait_for_cert(time)
    begin
      return if certificate
      generate
      return if certificate
    rescue SystemExit,NoMemoryError
      raise
    rescue Exception => detail
      Puppet.log_exception(detail, "Could not request certificate: #{detail.message}")
      if time < 1
        puts "Exiting; failed to retrieve certificate and waitforcert is disabled"
        exit(1)
      else
        sleep(time)
      end
      retry
    end

    if time < 1
      puts "Exiting; no certificate found and waitforcert is disabled"
      exit(1)
    end

    while true
      sleep time
      begin
        break if certificate
        Puppet.notice "Did not receive certificate"
      rescue StandardError => detail
        Puppet.log_exception(detail, "Could not request certificate: #{detail.message}")
      end
    end
  end

  def state
    if certificate_request
      return 'requested'
    end

    begin
      Puppet::SSL::CertificateAuthority.new.verify(name)
      return 'signed'
    rescue Puppet::SSL::CertificateAuthority::CertificateVerificationError
      return 'revoked'
    end
  end
end

require 'puppet/ssl/certificate_authority'
