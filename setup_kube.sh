#!/bin/bash

set -e

# returns 0 if answered yes, 1 if answered no
# $1: question
function ask_closed_question {
    while true; do
        read -p "$1 [y/n] " yn
        case $yn in
            [Yy]* ) echo 0; return 0;;
            [Nn]* ) echo 1; return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

FIND_YAML_CMD="find kubeconfig/ -regextype egrep -type f -regex '.*\.ya?ml'"

if [ -z $(command -v kubectl) ]; then
    if [[ $(ask_closed_question "kubectl not found. Install?") -eq "0" ]]; then
        echo "Installing kubectl..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x ./kubectl
        echo "Moving kubectl to /usr/local/bin"
        sudo mv ./kubectl /usr/local/bin/kubectl
        echo "\e[32mkubectl installed!\e[0m"
    fi
fi

if [ -z $(command -v helm) ]; then
    if [[ "$(ask_closed_question "helm not found. Install?")" -eq "0" ]]; then
        echo "Installing helm..."
        curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
        chmod 700 get_helm.sh
        echo "Launching the helm installer"
        ./get_helm.sh
        echo "\e[32mhelm installed!\e[0m"
    fi
fi

if [ -d ./kubeconfig ]; then
    echo "kubeconfig directory already exists"
    nb_files=$(eval $FIND_YAML_CMD | wc -l)
    if [ $nb_files -eq 0 ]; then
        echo "No kube config found in this directory"
    elif [ $nb_files -eq 1 ]; then
        export KUBECONFIG=$(pwd)/kubeconfig/$(eval $FIND_YAML_CMD)
        echo "\e[32mKubectl is ready to go!\e[0m"
    else
        echo "Multiple kube config files found in this directory. Please select one:"
        select file in $(eval $FIND_YAML_CMD); do
            export KUBECONFIG=$(pwd)/kubeconfig/$file
            break
        done
        echo "\e[32mKubectl is ready to go!\e[0m"
    fi
    echo "Note: For security reasons, make sure your kubeconfig files aren't readable and writable by others and group."

else 
    mkdir kubeconfig -m 700
    echo "kubeconfig directory created"
fi

