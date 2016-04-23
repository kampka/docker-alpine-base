FROM scratch

ADD alpine-base.tar.xz /

ENTRYPOINT ["/bin/sh", "-c"]
