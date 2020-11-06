FROM alpine:3.12@sha256:d7342993700f8cd7aba8496c2d0e57be0666e80b4c441925fc6f9361fa81d10e
RUN apk add --update-cache \
        curl \
        bash \
        jq \
        git \
        go
WORKDIR /tmp
COPY . .
RUN for dir in $(find . -mindepth 1 -maxdepth 1 -type d); do bash ${dir}/install.sh; done
