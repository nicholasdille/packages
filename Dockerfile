FROM alpine:3.12@sha256:d7342993700f8cd7aba8496c2d0e57be0666e80b4c441925fc6f9361fa81d10e as alpine
RUN apk add --update-cache \
        curl \
        bash \
        jq \
        git
WORKDIR /tmp

FROM ubuntu:20.10@sha256:a569d854594dae4c70f0efef5f5857eaa3b97cdb1649ce596b113408a0ad5f7f as ubuntu
RUN apt-get update \
 && apt-get -y install --no-install-recommends \
        bash \
        curl \
        jq \
        git
WORKDIR /tmp