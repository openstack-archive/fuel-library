Overview
--------


OpenStack services are interconnected by RESTful HTTP-based APIs and AMQP-based RPC messages. So, redundancy for stateless OpenStack API services is implemented through the combination of VIP management (keepalived) and load balancing (HAProxy). Stateful OpenStack components, such as state database and messaging server, rely on their respective active/active modes for high availability -- RabbitMQ uses built-in clustering capabilities, while the database uses MySQL/Galera replication.

.. image:: https://docs.google.com/drawings/pub?id=1PzRBUaZEPMG25488mlb42fRdlFS3BygPwbAGBHudnTM&w=750&h=491