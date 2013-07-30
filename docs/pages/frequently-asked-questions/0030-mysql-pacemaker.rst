Corosync crashes without network
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**Issue:**
TOTEM, the network protocol used by Corosync exceeds its timeout. Corosync sometimes crashes when networking is unavailable for a length of time. Additionally, MySQL has stopped working.

**Workaround:**

#. Verify that corosync is really broken ``service corosync status``.
     * You should see next error: ``corosync dead but pid file exists``

#. Start corosync manually ``service corosync start``.

#. Run ``ps -ef | grep mysql`` and kill ALL(!) **mysqld** and **mysqld_safe** processes.

#. Wait while pacemaker starts mysql processes again.
     *  You can check it with ``ps -ef | grep mysql`` command.
     *  If it doesn't start, run crm resource p_mysql start

#. Check with ``crm status`` command that this host is part of the cluster and p_mysql is not within "Failed actions".
