require 'puppet/network/http/connection'

module Puppet::Network; end

# This module contains the factory methods that should be used for getting a
# Puppet::Network::HTTP::Connection instance.
#
# The name "HttpPool" is a misnomer, and a leftover of history, but we would
# like to make this cache connections in the future.
#
# @api public
#
module Puppet::Network::HttpPool

  # Retrieve a connection for the given host and port.
  #
  # @param host [String] The hostname to connect to
  # @param port [Integer] The port on the host to connect to
  # @param use_ssl [Boolean] Whether to use an SSL connection
  # @param verify_peer [Boolean] Whether to verify the peer credentials, if possible. Verification will not take place if the CA certificate is missing.
  # @return [Puppet::Network::HTTP::Connection]
  #
  # @api public
  #
  def self.http_instance(host, port, use_ssl = true, verify_peer = true)
    verifier = if verify_peer
                 Puppet::SSL::Validator.default_validator()
               else
                 Puppet::SSL::Validator.no_validator()
               end

    Puppet::Network::HTTP::Connection.new(host, port,
                                          :use_ssl => use_ssl,
                                          :verify => verifier)
  end

  # Get an http connection that will be secured with SSL and have the
  # connection verified with the given verifier
  #
  # @param host [String] the DNS name to connect to
  # @param port [Integer] the port to connect to
  # @param verifier [#setup_connection, #peer_certs, #verify_errors] An object that will setup the appropriate
  #   verification on a Net::HTTP instance and report any errors and the certificates used.
  # @return [Puppet::Network::HTTP::Connection]
  #
  # @api public
  #
  def self.http_ssl_instance(host, port, verifier = Puppet::SSL::Validator.default_validator())
    Puppet::Network::HTTP::Connection.new(host, port,
                                          :use_ssl => true,
                                          :verify => verifier)
  end
end
