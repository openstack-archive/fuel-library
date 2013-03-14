Configuring Cobbler
-------------------

(NOTE:  This section is a draft and is awaiting final testing before completion.)

Fuel uses a single file, config.yaml, to both configure Cobbler and assist in the configuration of the site.pp file.  An example of this file will be distributed with later versions of Fuel, but in the meantime, you can use this file as an example:

(Note that this complete file should not have to be included in the final docs; it should be on the ISO.)

.. literalinclude:: /pages/installation-instructions/config.yaml

This file has been customized for the example in the docs, but in general you will need to be certain that IP and gateway information matches the decisions you made earlier in the process.




