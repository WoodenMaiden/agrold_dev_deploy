#!/bin/bash

set -e

normal=$(tput sgr0)
yellow=$(tput setaf 3)
red=$(tput setaf 1)
green=$(tput setaf 2)

# returns 0 if answered yes, 1 if answered no
# $1: question
function ask_closed_question {
    while true; do
        read -rp "$1 [y/n] " yn
        case $yn in
            [Yy]* ) echo 0; return 0;;
            [Nn]* ) echo 1; return 1;;
            * ) ;;
        esac
    done
}

# Returns 0 is file has read and write permissions for group and others, returns 1 otherwise
function is_RW_by_group_and_others {
    if [ -n "$(stat -c "%a" "$1" | grep ".[2-7][2-7]")" ]; then
        echo 0
        return 0
    else
        echo 1
        return 1
    fi
}

FIND_YAML_CMD="find kubeconfig/ -regextype egrep -type f -regex '.*\.ya?ml'"

if [ -z $(command -v kubectl) ]; then
    if [[ $(ask_closed_question "kubectl not found. Install?") -eq "0" ]]; then
        echo "Installing kubectl..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x ./kubectl
        echo "Moving kubectl to /usr/local/bin"
        sudo mv ./kubectl /usr/local/bin/kubectl
        echo "${green}kubectl installed!$normal"
    fi
fi

if [ -z $(command -v helm) ]; then
    if [[ "$(ask_closed_question "helm not found. Install?")" -eq "0" ]]; then
        echo "Installing helm..."
        curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
        chmod 700 get_helm.sh
        echo "Launching the helm installer"
        ./get_helm.sh
        echo "${green}helm installed!$normal"
    fi
fi

if [ -d ./kubeconfig ]; then
    echo "kubeconfig directory already exists"
    nb_files=$(eval $FIND_YAML_CMD | wc -l)
    if [ $nb_files -eq 0 ]; then
        echo "${red}No kubeconfig found in this directory.$normal"
    elif [ $nb_files -eq 1 ]; then
        export KUBECONFIG=$(pwd)/kubeconfig/$(eval $FIND_YAML_CMD)
        echo "${green}Kubectl and Helm are ready to go!$normal"
    else
        echo "Multiple kube config files found in this directory. Please select one:"
        select file in $(eval $FIND_YAML_CMD); do
            export KUBECONFIG=$(pwd)/$file
            break
        done

        if [ $(ask_closed_question "Do you want to move this file to ~/.kube/config? This Will make it available to all shells.") -eq "0" ]; then
            mkdir -p ~/.kube
            cp -i $KUBECONFIG ~/.kube/config
        fi
        echo "${green}Kubectl and Helm are ready to go!$normal"
    fi
    if [[ $(is_RW_by_group_and_others $KUBECONFIG) -eq "0" ]]; then
        echo "${yellow}Note: For security reasons, make sure your kubeconfig files aren't readable and writable by others and group.$normal"
    fi

else 
    mkdir kubeconfig -m 700
    echo "kubeconfig directory created. Please put your kubeconfig files in this directory."
fi

# To avoid your shell to die when an error occurs after this script
# useful when you want to use KUBECONFIG in the calling shell
set +e