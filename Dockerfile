FROM alpine:3.12@sha256:d7342993700f8cd7aba8496c2d0e57be0666e80b4c441925fc6f9361fa81d10e as alpine
RUN apk add --update-cache \
        curl \
        bash \
        jq \
        git
WORKDIR /tmp
CMD while true; do sleep 10; done

FROM ubuntu:21.04@sha256:eb9086d472747453ad2d5cfa10f80986d9b0afb9ae9c4256fe2887b029566d06 as ubuntu
RUN apt-get update \
 && apt-get -y install --no-install-recommends \
        bash \
        curl \
        jq \
        unzip \
        git \
        ca-certificates \
        gettext
WORKDIR /tmp
CMD sleep infinity