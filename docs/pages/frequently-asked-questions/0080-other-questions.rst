Other Questions
---------------

#. **[Q]** Why did you decide to provide OpenStack packages through your own repository?

   **[A]** We are fully committed to providing our customers with working and stable bits and pieces in order to make successful OpenStack deployments. Please note that we do not distribute our own version of OpenStack; we rather provide a plain vanilla distribution. So there is no vendor lock-in. Our repository just keeps the history of OpenStack packages certified to work with our Puppet manifests.  

   The benefit of this approach is that at any moment in time you can install any OpenStack version you want. If you are running Essex, you just need to use Puppet manifests which reference OpenStack packages for Essex from our repository. Once Folsom was released, we added new OpenStack packages for Folsom to our repository and created a separate branch with the corresponding Puppet manifests (which, in turn, reference these packages). With EPEL this would not be possible, as repository only keeps the latest version for OpenStack packages.
