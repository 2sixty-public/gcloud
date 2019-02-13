FROM google/cloud-sdk:229.0.0-alpine

COPY github-release.sh .

RUN gcloud components install kubectl --quiet \
    && gcloud components install beta --quiet \
    && apk add --update --no-cache jq py2-pip alpine-sdk python-dev docker \
    && pip list --format json |jq -r .[].name |xargs pip install -U \
    && pip install google-cloud-datastore \
    && pip install jinja2-cli[yaml] \
    && pip install yq

RUN curl -o helm.tgz https://storage.googleapis.com/kubernetes-helm/helm-v2.12.0-linux-amd64.tar.gz \
    && tar -xzf helm.tgz linux-amd64/helm \
    && mv linux-amd64/helm /bin \
    && rm -r helm.tgz \
    && rmdir linux-amd64

RUN ./github-release.sh kubernetes-sigs kustomize kustomize && \
    chmod +x kustomize && \
    mv kustomize /bin

RUN apk del alpine-sdk \
    && apk add -U --no-cache libstdc++ openssl coreutils util-linux openssl grep make

