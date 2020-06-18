FROM alpine
RUN apk add --update-cache \
        curl \
        bash \
        jq \
        git \
        go
WORKDIR /tmp
COPY . .
RUN for dir in $(find . -mindepth 1 -maxdepth 1 -type d); do bash ${dir}/install.sh; done
