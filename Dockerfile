FROM alpine:3.13@sha256:d0710affa17fad5f466a70159cc458227bd25d4afb39514ef662ead3e6c99515 AS alpine
RUN apk add --update-cache \
        curl \
        bash \
        jq \
        git
WORKDIR /tmp
CMD while true; do sleep 10; done

FROM ubuntu:18.04@sha256:2aeed98f2fa91c365730dc5d70d18e95e8d53ad4f1bbf4269c3bb625060383f0 AS ubuntu-bionic
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

FROM ubuntu:20.04@sha256:703218c0465075f4425e58fac086e09e1de5c340b12976ab9eb8ad26615c3715 AS ubuntu-focal
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

FROM ubuntu:20.10@sha256:160a9181d622d428f6836e17245fea90b87e9f7abb86939d002c2e301383c8a8 AS ubuntu-groovy
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