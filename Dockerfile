FROM alpine:3.12@sha256:d7342993700f8cd7aba8496c2d0e57be0666e80b4c441925fc6f9361fa81d10e as alpine
RUN apk add --update-cache \
        curl \
        bash \
        jq \
        git
WORKDIR /tmp

FROM ubuntu:20.04@sha256:1d7b639619bdca2d008eca2d5293e3c43ff84cbee597ff76de3b7a7de3e84956 as ubuntu
RUN apt-get update \
 && apt-get -y install \
        bash \
        curl \
        jq \
        git
WORKDIR /tmp