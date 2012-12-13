Known issues
=============

.. contents:: :local:

At least one RabbitMQ node must remain operational
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**Issue:** RabbitMQ nodes must not be shut down all at once. RabbitMQ requires
that, after a full shutdown of the cluster, the first node to bring up should
be the last one to shut down.

**Workaround:** If you experienced a complete power loss, it's recommended to
power up all nodes and then manually start RabbitMQ on all of them within 30
seconds, e.g. using an ssh script. If you failed, stop all RabbitMQ's (you might
need to do that using `kill -9` as `rabbitmqctl stop` may hang after such a
failure) and try starting them in different orders.

There is no easy automatic way to determine which node terminated last and so
should be brought up first, it's just trial and error.

**Background:** See http://comments.gmane.org/gmane.comp.networking.rabbitmq.general/19792.
