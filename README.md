Docker image alpine-base
========================
[![Circle CI](https://circleci.com/gh/kampka/docker-alpine-base/tree/v3.7.svg?style=svg)](https://circleci.com/gh/kampka/docker-alpine-base/tree/v3.7)
[![](https://imagelayers.io/badge/kampka/alpine-base:3.7.svg)](https://imagelayers.io/?images=kampka/alpine-base:3.7 'Get your own badge on imagelayers.io')

This image provides a very minimal [Alpine Linux](https://www.alpinelinux.org) installation
that is intended to be used as a base to build more sophisticated containers upon.
It contains little more that `busybox` and `apk`.

Building
-----------
This image build is customizable using the `configure` script.
To build the standard image, run:

```
$ ./configure --target-tag "3.7"
$ make
```

For a customized build, see `configure --help`.
