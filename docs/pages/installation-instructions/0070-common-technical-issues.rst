
.. _common-technical-issues:

Common Technical Issues
-----------------------

#. Puppet fails with "err: Could not retrieve catalog from remote server: Error 400 on SERVER: undefined method 'fact_merge' for nil:NilClass"
    * bug: http://projects.puppetlabs.com/issues/3234
    * workaround: ``service puppetmaster restart``
#. Puppet client will never resend the certificate to Puppet master. Certificate cannot be signed and verified.
    * bug: http://projects.puppetlabs.com/issues/4680
    * workaround:
        * on puppet client: "``rm -f /etc/puppet/ssl/certificate_requests/\*.pem``", and "``rm -f /etc/puppet/ssl/certs/\*.pem``"
        * on puppet master: "``rm -f /var/lib/puppet/ssl/ca/requests/\*.pem``"

#. The manifests are up-to-date under ``/etc/puppet/manifests``, but Puppet master keeps serving the previous version of manifests to the clients. Manifests seem to be cached by Puppet master.
    * issue: https://groups.google.com/forum/?fromgroups=#!topic/puppet-users/OpCBjV1nR2M
    * workaround: "``service puppetmaster restart``"
#. Timeout error for fuel-controller-XX when running "``puppet-agent --test``" to install OpenStack when using HDD instead of SSD
    * | Sep 26 17:56:15 fuel-controller-02 puppet-agent[1493]: Could not retrieve catalog from remote server: execution expired
      | Sep 26 17:56:15 fuel-controller-02 puppet-agent[1493]: Not using cache on failed catalog
      | Sep 26 17:56:15 fuel-controller-02 puppet-agent[1493]: Could not retrieve catalog; skipping run

    * workaround: ``vi /etc/puppet/puppet.conf``
        * add: ``configtimeout = 1200``
#. On running "``puppet agent --test``", the error messages below occur:
    * | err: /File[/var/lib/puppet/lib]: Could not evaluate: Could not retrieve information from environment production source(s) puppet://fuel-pm.your-domain-name.com/plugins

    and
      | err: Could not retrieve catalog from remote server: Error 400 on SERVER: stack level too deep
      | warning: Not using cache on failed catalog
      | err: Could not retrieve catalog; skipping run

    * The first problem can be solved using the way described here: http://projects.reductivelabs.com/issues/2244
    * The second problem can be solved by rebooting Puppet master.

#. PuppetDB Connection Failures
  Puppet fails on fuel-pm with message:
   Could not retrieve catalog from remote server: Error 400 on SERVER: Failed to submit 'replace facts' command for fuel-pm to PuppetDB at fuel-pm:8081: Connection refused - connect(2)

  This message is often the result of one of the following:

  * Firewall blocking the puppetdb port
  * DNS issue with the hostname specified in your puppetdb.conf
  * DNS issue with the ssl-host specified in your jetty.ini on the puppetdb server

  If you are able to connect (e.g. via telnet) to port 8081 on the puppetdb machine, so try the next step:
   | put in ``/etc/puppetdb/conf.d/jetty.ini`` a line:
   | ``certificate-whitelist = /etc/puppetdb/whitelist.txt``
   | listing all aliases for the machine in that file.
