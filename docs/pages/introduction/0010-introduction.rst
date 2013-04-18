This document explains how to use Fuel to more easily create and
maintain an OpenStack cloud infrastructure.

Fuel can be used to create virtually any OpenStack configuration, but the
installation includes several pre-defined architectures. To simplify
matters, the guide emphasises a single common reference architecture,
the multi-node, high-availability configuration. It begins by explaining
that architecture, then moves on to the details of creating that
configuration in a development setting using VirtualBox. Finally, it
gives you the information you need to know to create this and other
OpenStack architectures in a production environment.

This document assumes that you are familiar with general Linux
commands and administration concepts, as well as general networking
concepts. You should have some familiarity with grid or virtualization
systems such as Amazon Web Services or VMware, as well as OpenStack
itself, but you don't need to be an expert.

The Fuel User's Guide is organized as follows:

* Section 1, :ref:`Introduction <Introduction>` (this section), explains what Fuel is and gives you a general idea of how it works.

* Section 2, :ref:`Reference Architecture <Reference-Archiecture>`, provides a general look at the components that make up OpenStack, and describes the reference architecture to be instantiated in Section 3.

* Section 3, :ref:`Create a multi-node OpenStack cluster using Fuel <Create-Cluster>`, takes you step-by-step through the process of creating a high-availability OpenStack cluster.

* Section 4, :ref:`Production Considerations <Production>`, looks at the real-world questions and problems involved in creating an OpenStack cluster for production use. It discusses issues such as network layout and hardware requirements, and provides tips and tricks for creating a cluster of up to 100 nodes.

* Even with a utility as powerful as Fuel, creating an OpenStack cluster can be complex, and Section 5, :ref:`Frequently Asked Questions <FAQ>`, covers many of the issues that tend to arise during that process.

* Finally, the User's Guide assumes that you are taking advantage of certain shortcuts, such as using a pre-built Puppet master; if you prefer not to go that route, Appendix A, :ref:`Creating the Puppet master <Create-PM>`.


Lets start off by taking a look at Fuel itself. We'll start by
explaining what it is and how it works, and then get you set up and ready
to start using it.

