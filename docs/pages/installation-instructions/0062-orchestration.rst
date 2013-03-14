Depolying via orchestration
----------------------------

Manually installing a handful of servers might be managable, but repeatable installations, or those that involve a large number of servers, require automated orchestration.  Now you can use orchestration with Fuel through the ``astute`` script.  To configure ``astute``, modify this ``astute.cfg`` file for your own configuration and create it on fuel-pm:

.. literalinclude:: /pages/installation-instructions/astute.cfg

Finally, to begin the deployment, run the following script::

    astute -f astute.cfg

You should see the process continuing as it goes along.
