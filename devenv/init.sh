#!/usr/bin/env bash

kubectl apply -f tiller.yml
helm init --upgrade --wait --tiller-namespace=kube-system --service-account=tiller

helm install stable/dex \
    --name dex \
    --namespace dex \
    -f dex.yaml

