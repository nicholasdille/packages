FROM alpine:3.12@sha256:d7342993700f8cd7aba8496c2d0e57be0666e80b4c441925fc6f9361fa81d10e as alpine
RUN apk add --update-cache \
        curl \
        bash \
        jq \
        git
WORKDIR /tmp
CMD while true; do sleep 10; done

FROM ubuntu:20.10@sha256:c41e8d2a4ca9cddb4398bf08c99548b9c20d238f575870ae4d3216bc55ef3ca7 as ubuntu
RUN apt-get update \
 && apt-get -y install --no-install-recommends \
        bash \
        curl \
        jq \
        xz-utils \
        unzip \
        git \
        ca-certificates \
        gettext
WORKDIR /tmp
CMD sleep infinity