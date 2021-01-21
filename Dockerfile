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