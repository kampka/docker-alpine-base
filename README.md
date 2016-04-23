Docker image alpine-base
========================

[![Circle CI](https://circleci.com/gh/kampka/docker-alpine-base/tree/v3.3.svg?style=svg)](https://circleci.com/gh/kampka/docker-alpine-base/tree/v3.3)
[![](https://imagelayers.io/badge/kampka/alpine-base:v3.3.svg)](https://imagelayers.io/?images=kampka/alpine-base:v3.3 'Get your own badge on imagelayers.io')

This image provides a very minimal [Alpine Linux](https://www.alpinelinux.org) installation
that is intended to be used as a base to build more sophisticated containers upon.
It contains little more that `busybox` and `apk`.

This image builds from scratch using the `prepare.sh` script.
Note that this script will only will only generate a root filesystem.

Afterwards, the usual ```docker build``` will produce the image.
