FROM alpine:3.13@sha256:d9a7354e3845ea8466bb00b22224d9116b183e594527fb5b6c3d30bc01a20378 AS alpine
RUN apk add --update-cache \
        curl \
        bash \
        jq \
        git
WORKDIR /tmp
CMD while true; do sleep 10; done

FROM ubuntu:18.04@sha256:ea188fdc5be9b25ca048f1e882b33f1bc763fb976a8a4fea446b38ed0efcbeba AS ubuntu-bionic
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

FROM ubuntu:20.10@sha256:2b276cc0800becc0f288b1e03e445efe1e24e21f7a1bea19c9f690fbc6d63724 AS ubuntu-groovy
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