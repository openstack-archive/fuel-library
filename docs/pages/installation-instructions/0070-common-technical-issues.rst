
.. _common-technical-issues:

Common Technical Issues
-----------------------

#. Puppet fails with "err: Could not retrieve catalog from remote server: Error 400 on SERVER: undefined method 'fact_merge' for nil:NilClass"
    * bug: http://projects.puppetlabs.com/issues/3234
    * workaround: "service puppetmaster restart"
#. Puppet client will never resend certificate to Puppet master. Certificate cannot be signed and verified.
    * bug: http://projects.puppetlabs.com/issues/4680
    * workaround:
        * on Puppet client: "``rm -f /etc/puppet/ssl/certificate_requests/\*.pem``", and "``rm -f /etc/puppet/ssl/certs/\*.pem``"
        * on Puppet master: "``rm -f /var/lib/puppet/ssl/ca/requests/\*.pem``"

#. The manifests are up-to-date under ``/etc/puppet/manifests``, but Puppet master keeps serving the previous version of manifests to the clients. The manifests seem to be cached by Puppet master.
    * issue: https://groups.google.com/forum/?fromgroups=#!topic/puppet-users/OpCBjV1nR2M
    * workaround: "``service puppetmaster restart``"
#. Timeout error for fuel-XX on running "``puppet-agent --test``" to install OpenStack when using HDD instead of SSD
    * | Sep 26 17:56:15 fuel-controller-02 puppet-agent[1493]: Could not retrieve catalog from remote server: execution expired
      | Sep 26 17:56:15 fuel-controller-02 puppet-agent[1493]: Not using cache on failed catalog
      | Sep 26 17:56:15 fuel-controller-02 puppet-agent[1493]: Could not retrieve catalog; skipping run

    * workaround: ``vi /etc/puppet/puppet.conf``
        * add: ``configtimeout = 1200``
#. While running "``puppet agent --test``", the error messages below occur:
    * | err: /File[/var/lib/puppet/lib]: Could not evaluate: Could not retrieve information from environment production source(s) puppet://fuel-pm.mirantis.com/plugins

    and
      | err: Could not retrieve catalog from remote server: Error 400 on SERVER: stack level too deep
      | warning: Not using cache on failed catalog
      | err: Could not retrieve catalog; skipping run

    * The first problem can be solved using the way described here: http://projects.reductivelabs.com/issues/2244
    * The second problem can be solved by rebooting Puppet master

