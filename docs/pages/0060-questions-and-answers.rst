Questions & Answers
===================

.. contents:: :local:

#. **[Q]** Why have you chosen to provide OpenStack packages through your own repository at http://download.mirantis.com?

   **[A]** We are fully committed to providing our customers with working and stable bits and pieces in order to make successful OpenStack deployments. It is important to mention that we do not distribute our own version of OpenStack, we rather provide a plain vanilla distribution. So there is no vendor lock-in, and our repository just keeps the history of OpenStack packages certified to work with our Puppet manifests.

   The benefit is that at any moment in time you can install any OpenStack version you want. If you are running Essex, you just need to use Puppet manifests which reference OpenStack packages for Essex from our repository. Once Folsom comes out, we will add new OpenStack packages for Folsom to our repository and create a separate branch with the corresponding Puppet manifests (which, in turn, will reference these packages). With EPEL it would not be possible, as it only keeps the latest version for OpenStack packages.
