FROM alpine:3.12@sha256:25f5332d060da2c7ea2c8a85d2eac623bd0b5f97d508b165f846c7d172897438 AS alpine
RUN apk add --update-cache \
        curl \
        bash \
        jq \
        git
WORKDIR /tmp
CMD while true; do sleep 10; done

FROM ubuntu:18.04@sha256:a7fa45fb43d471f4e66c5b53b1b9b0e02f7f1d37a889a41bbe1601fac70cb54e AS ubuntu-bionic
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
        bash \
        curl \
        jq \
        xz-utils \
        unzip \
        git \
        ca-certificates \
        gettext \
        fontconfig \
        patch \
        make \
        libffi6
WORKDIR /tmp
CMD sleep infinity

FROM ubuntu:20.04@sha256:4e4bc990609ed865e07afc8427c30ffdddca5153fd4e82c20d8f0783a291e241 AS ubuntu-focal
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
        bash \
        curl \
        jq \
        xz-utils \
        unzip \
        git \
        ca-certificates \
        gettext \
        fontconfig \
        patch \
        make \
        libffi7
WORKDIR /tmp
CMD sleep infinity

FROM ubuntu:20.10@sha256:c41e8d2a4ca9cddb4398bf08c99548b9c20d238f575870ae4d3216bc55ef3ca7 AS ubuntu-groovy
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
        bash \
        curl \
        jq \
        xz-utils \
        unzip \
        git \
        ca-certificates \
        gettext \
        fontconfig \
        patch \
        make \
        libffi8ubuntu1
WORKDIR /tmp
CMD sleep infinity