FROM google/cloud-sdk:272.0.0-alpine

RUN apk add --update --no-cache jq py3-pip alpine-sdk python-dev python3-dev libffi-dev unzip curl bash grep make openssl-dev coreutils util-linux g++

RUN curl https://releases.hashicorp.com/terraform/0.11.13/terraform_0.11.13_linux_amd64.zip | funzip > /usr/local/bin/terraform \
    && chmod +x /usr/local/bin/terraform

RUN apk del alpine-sdk \
    && apk add -U --no-cache libstdc++ 

COPY requirements.txt /
RUN pip3 install -r /requirements.txt
