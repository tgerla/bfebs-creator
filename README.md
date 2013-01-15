bfebs-creator
=============

A utility to convert a running instance-store Eucalyptus instance into a boot-from-EBS image.

This script runs from within an instance-store Eucalyptus instance and copies the instance to
an attached EBS volume and prepares that volume to run as a Boot-From-EBS image. An example:

	euca-create-volume -s 3 -z cluster01
	euca-attach-volume -i &lt;instance id&gt; &lt;volume id&gt; -d /dev/vdc
	bfebs-creator.sh /dev/vdc
	euca-detach-volume &lt;volume id&gt;
	euca-create-snapshot &lt;volume id&gt;
	euca-register -n centos-6.3-x86-64-bfebsize-test --root-device-name /dev/vda -b /dev/vda=&lt;snapshot id&gt;

TODO:

- Script the creation, attach, detach, create-snapshot, and register steps too?
- Handle other distributes gracefully--this has been tested on CentOS 6.3 and will likely fail anywhere else.
- Some basic level of error checking and input validation.
