
RabbitMQ
^^^^^^^^

At least one RabbitMQ node must remain operational
--------------------------------------------------

**Issue:** 
All RabbitMQ nodes must not be shut down simultaneously. RabbitMQ requires
that, after a full shutdown of the cluster, the first node to bring up should
be the last one to shut down.

**Workaround:** 
There are 2 possible scenarios, depending on shutdown results.

**1. RabbitMQ master node alive and can be started.**

FUEL installation updates ``/etc/init.d/rabbitmq-server`` init scripts for RHEL/Centos and Ubuntu to customized versions. These scripts attempt to start RabbitMQ 5 times and so give RabbitMQ master node necessary time to start
after complete power loss. 
It is recommended to power up all nodes and then check if RabbitMQ server started on all nodes. All nodes should start automatically.

**2. Impossible to start RabbitMQ master node (hardware or system failure)**

There is no easy automatic way to resolve this situation.
Proposed solution is to delete mirrored queue directly from mnesia (RabbitMQ database)

1. Select any alive node. Run

``erl -mnesia dir '"/var/lib/rabbitmq/mnesia/rabbit\@<failed_controller_name>"'``

2. Run ``mnesia:start().`` in Erlang console.

3. Compile and run the following Erlang script::

    AllTables = mnesia:system_info(tables),
    DataTables = lists:filter(fun(Table) -> Table =/= schema end,
                          AllTables),
    RemoveTableCopy = fun(Table,Node) ->
    Nodes = mnesia:table_info(Table,ram_copies) ++
          mnesia:table_info(Table,disc_copies) ++
          mnesia:table_info(Table,disc_only_copies),
    case lists:is_member(Node,Nodes) of
      true -> mnesia:del_table_copy(Table,Node);
      false -> ok
    end
    end,
    RemoveTableCopy(Tbl,'rabbit@<failed_controller_name>') || Tbl <- DataTables.
    rpc:call('rabbit@<failed_controller_name>',mnesia,stop,[]),
    rpc:call('rabbit@<failed_controller_name>',mnesia,delete_schema,[SchemaDir]),
    RemoveTablecopy(schema,'rabbit@<failed_controller_name>').

4. Exit Erlang console ``halt().``

5. Run ``service rabbitmq-server start``

**Background:** See http://comments.gmane.org/gmane.comp.networking.rabbitmq.general/19792.
