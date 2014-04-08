docker-mkimage-gentoo
=====================

a safe and flexible gentoo stage3 importer for docker.io

 * allows building from all different stage3 flavors {,nomultilib,hardened,hardened+nomultilib}

 * automatically uses latest build and tags resulting docker image

 * verifies checksum-file signature and makes sure it's actually signed by

   > RSA key ID 2D182910

   > Key fingerprint = 13EB BDBE DE7A 1277 5DFD  B1BA BB57 2E0E 2D18 2910

   > "Gentoo Linux Release Engineering (Automated Weekly Release Key) <releng@gentoo.org>"

 * checks both, SHA-512 and Whirlpool digests



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
