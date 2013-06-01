
Installing OpenStack using Puppet directly
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Now that you've set all of your configurations, all that's left to stand
up your OpenStack cluster is to run Puppet on each of your nodes; the
Puppet Master knows what to do for each of them.

You have two options for performing this step.  The first, and by far the easiest, is to use the orchestrator.  If you're going to take that option, skip ahead to :ref:`Deploying OpenStack via Orchestration <orchestration>`.  If you choose not to use orchestration, or if for some reason you want to reload only one or two nodes, you can run Puppet manually on a the target nodes.

If you're starting from scratch, start by logging in to fuel-controller-01 and running the Puppet
agent.

One optional step would be to use the script command to log all
of your output so you can check for errors if necessary::



    script agent-01.log
    puppet agent --test

You will to see a great number of messages scroll by, and the
installation will take a significant amount of time. When the process
has completed, press CTRL-D to stop logging and grep for errors::



    grep err: agent-01.log



If you find any errors relating to other nodes, ignore them for now.



Now you can run the same installation procedure on fuel-controller-01
and fuel-controller-02, as well as fuel-compute-01.



Note that the controllers must be installed sequentially due to the
nature of assembling a MySQL cluster based on Galera, which means that
one must complete its installation before the next begins, but that
compute nodes can be installed concurrently once the controllers are
in place.



In some cases, you may find errors related to resources that are not
yet available when the installation takes place. To solve that
problem, simply re-run the puppet agent on the affected node after running the other controllers, and
again grep for error messages.



When you see no errors on any of your nodes, your OpenStack cluster is
ready to go.


Examples of OpenStack installation sequences
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

When running Puppet manually, the exact sequence depends on what it is you're trying to achieve.  In most cases, you'll need to run Puppet more than once; with every deployment pass Puppet collects and adds necessary absent information to the OpenStack configuration, stores it to PuppedDB and applies necessary changes.  

  **Note:** *Sequentially run* means you don't start the next node deployment until previous one is finished.

  **Example 1:** **Full OpenStack deployment with standalone storage nodes**

    * Create necessary volumes on storage nodes as described in	 :ref:`create-the-XFS-partition`.
    * Sequentially run a deployment pass on every SwiftProxy node (``fuel-swiftproxy-01 ... fuel-swiftproxy-xx``), starting with the ``primary-swift-proxy node``. Node names are set by the ``$swift_proxies`` variable in ``site.pp``. There are 2 Swift Proxies by default.
    * Sequentially run a deployment pass on every storage node (``fuel-swift-01`` ... ``fuel-swift-xx``). 
    * Sequentially run a deployment pass on the controller nodes (``fuel-controller-01 ... fuel-controller-xx``). starting with the ``primary-controller`` node.
    * Run a deployment pass on the Quantum node (``fuel-quantum``) to install the Quantum router.
    * Run a deployment pass on every compute node (``fuel-compute-01 ... fuel-compute-xx``) - unlike the controllers, these nodes may be deployed in parallel.
    * Run an additional deployment pass on Controller 1 only (``fuel-controller-01``) to finalize the Galera cluster configuration.

  **Example 2:** **Compact OpenStack deployment with storage and swift-proxy combined with nova-controller on the same nodes**

    * Create the necessary volumes on controller nodes as described in :ref:`create-the-XFS-partition`
    * Sequentially run a deployment pass on the controller nodes (``fuel-controller-01 ... fuel-controller-xx``), starting with the ``primary-controller node``. Errors in Swift storage such as */Stage[main]/Swift::Storage::Container/Ring_container_device[<device address>]: Could not evaluate: Device not found check device on <device address>* are expected during the deployment passes until the very final pass.
    * Run an additional deployment pass on Controller 1 only (``fuel-controller-01``) to finalize the Galera cluster configuration.
    * Run a deployment pass on the Quantum node (``fuel-quantum``) to install the Quantum router.
    * Run a deployment pass on every compute node (``fuel-compute-01 ... fuel-compute-xx``) - unlike the controllers these nodes may be deployed in parallel.

  **Example 3:** **OpenStack HA installation without Swift**

    * Sequentially run a deployment pass on the controller nodes (``fuel-controller-01 ... fuel-controller-xx``), starting with the primary controller. No errors should appear during this deployment pass.
    * Run an additional deployment pass on the primary controller only (``fuel-controller-01``) to finalize the Galera cluster configuration.
    * Run a deployment pass on the Quantum node (``fuel-quantum``) to install the Quantum router.
    * Run a deployment pass on every compute node (``fuel-compute-01 ... fuel-compute-xx``) - unlike the controllers these nodes may be deployed in parallel.

  **Example 4:** **The most simple OpenStack installation: Controller + Compute on the same node**

    * Set the ``node /fuel-controller-[\d+]/`` variable in ``site.pp`` to match the hostname of the node on which you are going to deploy OpenStack. Set the ``node /fuel-compute-[\d+]/`` variable to **mismatch** the node name. Run a deployment pass on this node. No errors should appear during this deployment pass.
    * Set the ``node /fuel-compute-[\d+]/`` variable in ``site.pp`` to match the hostname of the node on which you are going to deploy OpenStack. Set the ``node /fuel-controller-[\d+]/`` variable to **mismatch** the node name. Run a deployment pass on this node. No errors should appear during this deployment pass.
