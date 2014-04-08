docker-mkimage-gentoo
=====================

a safe and flexible gentoo stage3 importer for docker.io

Usage
-----

	mkimage-gentoo.sh
creates images from current amd64 stage3 snapshot

	mkimage-gentoo.sh nomultilib
creates images from current amd64 stage3 nomultilib snapshot

	mkimage-gentoo.sh hardened+nomultilib
creates images from current amd64 stage3 hardened+nomultilib snapshot

	mkimage-gentoo.sh nomultilib http://distfiles.gentoo.org/
creates images from current amd64 stage3 nomultilib snapshot
uses http://distfiles.gentoo.org/ as mirror

Note that the resulting docker.io images are not ready for use, but rather
serve as a base gentoo-based Dockerfiles.
