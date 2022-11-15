#!/bin/bash

set -e -o pipefail -C

normal=$(tput sgr0)
red=$(tput setaf 1)
yellow=$(tput setaf 3)
green=$(tput setaf 2)

#Options
function help {
cat << EOF 
Usage: $0 [options]:
Most of the following options are passed to the helm command and will override chart's values
Options:
    -h: Display this help message
    -s: Run helm in dry-run mode to simulate an install
    -d: override the base domain for the apps
    -n: override the namespace for the apps
    -e: sparql endpoint adress
EOF
    exit 1
}

CHARTS=$(find . -regextype egrep -maxdepth 2 -type f -name 'Chart.yaml' -exec dirname {} \;)
HELM_OPTS="--install"
DRY_RUN="false"

# Parse options
while getopts ":shd:n:e:" opt; do
    case $opt in
        h)
            help
            ;;
        d)
            BASE_DOMAIN=$OPTARG
            HELM_OPTS="$HELM_OPTS --set 'ingress.hosts[0].domain=$BASE_DOMAIN'"
            ;;
        n)
            NAMESPACE=$OPTARG
            HELM_OPTS="$HELM_OPTS --namespace $NAMESPACE --create-namespace"
            ;;
        s)
            HELM_OPTS="$HELM_OPTS --debug --dry-run"
            DRY_RUN="true"
            ;;
        e)
            ENDPOINT=$OPTARG
            HELM_OPTS="$HELM_OPTS --set 'sparqlAddress=$ENDPOINT'"
            ;;
        \?)
            echo "${red}Invalid option -$OPTARG$normal" >&2
            help
            ;;
        :)
            echo "${red}Option -$OPTARG requires an argument.$normal" >&2
            help
            ;;
    esac
done

if [ -n $(command -v kubectl) ] && [ -n $(command -v helm) ]; then
    if [ "$DRY_RUN" = "true" ]; then
        echo "Running in dry-run mode, no changes will be made"
        echo "Helm options: $HELM_OPTS"
        
        kubectl create configmap dataset --dry-run=client --from-file=./dataset
    else
        #because apply does not crash if the namespace already exists, we need to check if it exists before running helm
        kubectl create configmap dataset --from-file=./dataset --dry-run=client -o yaml | kubectl apply -f -
    fi

    # for each elt of the array install or update helm config
    for c in $CHARTS; do
        echo "${yellow}Installing chart $(basename "$c")${normal}"
        if [ "$DRY_RUN" = "true" ]; then
            echo "${yellow}> helm upgrade $(basename "$c") --values $c/values.yaml $HELM_OPTS${normal}"
        fi

        eval "helm upgrade $(basename "$c") $c --values $c/values.yaml $HELM_OPTS"
    done

    echo "${green}Done!$normal"
else
    echo "${red}Please install Kubectl and helm.$normal" >&2
    echo "You can install them both via the setup_kube.sh script." >&2
    exit 1
fi