FROM google/cloud-sdk:264.0.0-alpine

RUN gcloud components install kubectl --quiet \
    && gcloud components install beta --quiet \
    && apk add --update --no-cache jq py2-pip alpine-sdk python-dev docker unzip \
    && pip list --format json |jq -r .[].name |xargs pip install -U \
    && pip install google-cloud-datastore \
    && pip install jinja2-cli[yaml] \
    && pip install yq

RUN curl -o helm.tgz https://storage.googleapis.com/kubernetes-helm/helm-v2.12.0-linux-amd64.tar.gz \
    && tar -xzf helm.tgz linux-amd64/helm \
    && mv linux-amd64/helm /bin \
    && rm -r helm.tgz \
    && rmdir linux-amd64

COPY github-release.sh .
RUN ./github-release.sh kubernetes-sigs kustomize kustomize && \
    chmod +x kustomize && \
    mv kustomize /bin

RUN curl https://releases.hashicorp.com/terraform/0.11.13/terraform_0.11.13_linux_amd64.zip | funzip > /usr/local/bin/terraform \
    && chmod +x /usr/local/bin/terraform

RUN apk del alpine-sdk \
    && apk add -U --no-cache libstdc++ openssl coreutils util-linux openssl grep make

COPY global-cluster-utils.sh .
