FROM alpine:3.21

WORKDIR /

RUN apk --update add ca-certificates wget jq bash

ENV HOME=/
ENV PATH=/yandex-cloud/bin:$PATH

# Install Yandex Cli
RUN curl https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
