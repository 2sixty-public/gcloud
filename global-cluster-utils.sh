#!/usr/bin/env bash

for_each_cluster() {
    CLUSTER_STATE_URI=${CLUSTER_STATE_URI:-gs://sixty-sre-cluster-state/clusters}
    if [ -z "$CLUSTER_STATE_URI" ];then
        echo "error: CLUSTER_STATE_URI is not set"
        exit 1
    fi

    if [ -z "$DEPLOYMENT_CREDENTIALS" ];then
        echo "error: DEPLOYMENT_CREDENTIALS is not set to b64 encoded service account"
        exit 1
    fi

    echo "Activating service account"
    echo "$DEPLOYMENT_CREDENTIALS" | base64 --decode > "$HOME"/google-application-credentials.json
    gcloud auth activate-service-account --key-file="$HOME"/google-application-credentials.json && \
      rm -f "$HOME"/google-application-credentials.json || \
      rm -f "$HOME"/google-application-credentials.json

    cluster_file=`mktemp`
    gsutil cp $CLUSTER_STATE_URI $cluster_file
    errs=0
    export CLUSTER_INDEX=0
    export CLUSTER_RANK=0
    while read CLUSTER_RANK cluster project region; do
        auth_for_cluster $project $region $cluster
        for cmd in $*;do
            echo "================================================="
            echo "Executing '$cmd' for $CLUSTER_INDEX:$project/$region/$cluster"
            if ! $cmd;then
                echo "ERROR: FAILED! Abandoning run for cluster"
                errs=`expr $errs + 1`
                break
            fi
            echo "================================================="
        done
        CLUSTER_INDEX=`expr $CLUSTER_INDEX + 1`
    done < $cluster_file
    rm $cluster_file
    return $errs
}

auth_for_cluster() {
    project=$1
    region=$2
    cluster=$3
    echo Authenticating for cluster $project/$region/$cluster

    if [ ! -z "$GITLAB_CI" ]; then
        gcloud config set project "$project"
        gcloud container clusters get-credentials "$cluster" \
            --region "$region" \
            --project "$project"
    else
        echo "Running locally, skipping authentication"
    fi
}

unified_docker_build_push() {
  local branch=${CI_COMMIT_REF_SLUG:-$(git branch | grep \* | cut -d ' ' -f2)}
  local commit_sha=${CI_COMMIT_SHA:-$(git rev-parse HEAD)}
  local imagetag
  imagetag="${IMAGETAG:-$branch-$(echo "$commit_sha"|cut -c1-8)}"

  if [ -z "$BUILD_CREDENTIALS" ];then
      echo "error: BUILD_CREDENTIALS is not set to b64 encoded service account"
      exit 1
  fi

  if [ -z "$IMAGEBASE" ];then
      echo "error: IMAGEBASE is not set, please set it to something like: eu.gcr.io/something/something"
      exit 1
  fi
  if [ -z "$DOCKER_FILE" ];then
      echo "error: DOCKER_FILE is not set, please set it to the path of the Dockerfile you wish to build"
      exit 1
  fi
  if [ -z "$DOCKER_CONTEXT" ];then
      echo "error: DOCKER_CONTEXT is not set, please set it the Docker context (the root where your Dockerfile will run its commands)"
      exit 1
  fi

  echo "$BUILD_CREDENTIALS" \
    | base64 --decode \
    | docker login -u _json_key --password-stdin https://"$(echo "$IMAGEBASE"|cut -f1 -d/)" # url like this because maybe it's eu.gcr.io or gcr.io or whatever
  docker pull "$IMAGEBASE:$branch" || true # to reuse some layers built earlier
  docker build --cache-from "$IMAGEBASE:$branch" \
                -t "$IMAGEBASE:$branch" \
                -t "$IMAGEBASE:$imagetag" \
                -f "$DOCKER_FILE" "$DOCKER_CONTEXT" || \
                docker build -t "$IMAGEBASE:$branch" \
                            -t "$IMAGEBASE:$imagetag" \
                            -f "$DOCKER_FILE" "$DOCKER_CONTEXT"
  docker push "$IMAGEBASE:$branch"
  docker push "$IMAGEBASE:$imagetag"
  if [ "$branch" == "master" ]; then # so we know what is actually the latest... (in my head latest=latest stable build)
    docker tag "$IMAGEBASE:$branch" "$IMAGEBASE:latest"
    docker push "$IMAGEBASE:latest"
  fi
}
