FROM ubuntu:20.10@sha256:a569d854594dae4c70f0efef5f5857eaa3b97cdb1649ce596b113408a0ad5f7f
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get -y install \
        gcc \
        git \
        libc6-dev \
        libglib2.0-dev \
        pkg-config \
        make \
        runc \
        curl