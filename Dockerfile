FROM alpine:3.13@sha256:08d6ca16c60fe7490c03d10dc339d9fd8ea67c6466dea8d558526b1330a85930 AS alpine-3.13
RUN apk add --update-cache \
        curl \
        bash \
        jq \
        git \
        coreutils \
        util-linux
WORKDIR /tmp
CMD while true; do sleep 10; done

# Ubuntu 18.04 (Bionic)
FROM ubuntu:18.04@sha256:ea188fdc5be9b25ca048f1e882b33f1bc763fb976a8a4fea446b38ed0efcbeba AS ubuntu-18.04
RUN echo 'APT::Get::Install-Recommends "false";' >/etc/apt/apt.conf.d/docker-no-recommends \
 && echo 'APT::Get::Install-Suggests "false";' >/etc/apt/apt.conf.d/docker-no-suggests \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get -y install \
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
        libffi6 \
        bsdmainutils
WORKDIR /tmp
CMD sleep infinity

# Ubuntu 20.04 (Focal)
FROM ubuntu:20.04@sha256:703218c0465075f4425e58fac086e09e1de5c340b12976ab9eb8ad26615c3715 AS ubuntu-20.04
RUN echo 'APT::Get::Install-Recommends "false";' >/etc/apt/apt.conf.d/docker-no-recommends \
 && echo 'APT::Get::Install-Suggests "false";' >/etc/apt/apt.conf.d/docker-no-suggests \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get -y install \
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
        libffi7 \
        bsdmainutils
WORKDIR /tmp
CMD sleep infinity

# Ubuntu 20.10 (Groovy)
FROM ubuntu:20.10@sha256:2b276cc0800becc0f288b1e03e445efe1e24e21f7a1bea19c9f690fbc6d63724 AS ubuntu-20.10
RUN echo 'APT::Get::Install-Recommends "false";' >/etc/apt/apt.conf.d/docker-no-recommends \
 && echo 'APT::Get::Install-Suggests "false";' >/etc/apt/apt.conf.d/docker-no-suggests \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get -y install \
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
        libffi8ubuntu1 \
        bsdextrautils
WORKDIR /tmp
CMD sleep infinity

# Ubuntu 21.04 (Hirsute)
FROM ubuntu:21.04@sha256:2fc51f401cb873bfec33022d065efacbaf868b2e23f4dd76d7230d129258e255 AS ubuntu-21.04
RUN echo 'APT::Get::Install-Recommends "false";' >/etc/apt/apt.conf.d/docker-no-recommends \
 && echo 'APT::Get::Install-Suggests "false";' >/etc/apt/apt.conf.d/docker-no-suggests \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get -y install \
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
        libffi8ubuntu1 \
        bsdextrautils
WORKDIR /tmp
CMD sleep infinity