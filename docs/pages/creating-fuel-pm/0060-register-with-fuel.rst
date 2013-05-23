Register the nodes with the Puppet Master
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

At this point you the have OS installed configured on all nodes. Fuel
has also made sure that these nodes have been configured, with Puppet
installed and pointing to the Puppet Master, so the nodes are almost
ready for deploying OpenStack. As the last step, you need to register the
nodes in Puppet master. Do this by running the Puppet agent::



    puppet agent --test



This action generates a certificate, sends it to the Puppet Master for
signing, and then fails. That's fine. It's exactly what we want to
happen; we just want to send the certificate request to the Puppet
Master.



Once you've done this on all four nodes, switch to the Puppet Master
and sign the certificate requests::



    puppet cert list
    puppet cert sign --all



Alternatively, you can sign only a single certificate using::



    puppet cert sign fuel-XX.localdomain



Now return to the newly installed node and run the Puppet agent again::



    puppet agent --test



This time the process should successfully complete and result in the
"Hello World from fuel-XX" message you defined earlier.
