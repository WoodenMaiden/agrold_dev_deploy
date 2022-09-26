#!/bin/bash

if [ -n $(command -v kubectl) ] && [ -n $(command -v helm) ]; then
    kubectl create configmap dataset --from-file=./dataset

    CHARTS=$(find . -regextype egrep -type f -name 'Chart.yaml' -exec dirname {} \;)

    # for each elt of the array install or update helm config
    for c in $CHARTS; do
        helm upgrade --install $(basename "$c") $c
    done
else
    echo "\e[31mPlease install Kubectl and helm.\e[0m"
    echo "You can install them both via the setup_kube.sh script."
fi