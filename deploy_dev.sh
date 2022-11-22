#!/bin/bash

set -e -o pipefail -C

red=$(tput setaf 1)
yellow=$(tput setaf 3)
green=$(tput setaf 2)
normal=$(tput sgr0)

#Options
function help {
cat << EOF 
Usage: $0 [options] [Tomcat env variables]:
Most of the following options are passed to the helm command and will override chart's values
Options:
    -h: Display this help message
    -s: Run helm in dry-run mode to simulate an install
    -d <somedomain.dom>: override the base domain for the apps
    -n <namespace>: override the namespace for the apps
    -e <http://sparql.ndpnt>: sparql endpoint adress
    -p <password>: Tomcat admin password, generated automatically if not provided
    -w <warpath>: path to the war file to deploy

Tomcat env variables:
    This programm will find and apply all your variables unless specified as argument
    You can find them there https://github.com/WoodenMaiden/AgroLD_webapp/blob/easier-deployment/agrold-javaweb/README.md
    Format <ENV1=a ENV2=B ...>.
EOF
    exit 1
}

CHARTS=$(find . -regextype egrep -maxdepth 2 -type f -name 'Chart.yaml' -exec dirname {} \;)
#we generate randomly a password for the tomcat admin user
HELM_OPTS="--install"
DRY_RUN="false"
CATALINA_OPTS=""
PASSWORD="$(cat /dev/random | tr -dc '[:alnum:]' | fold -w 10 | head -n 1; echo '')"
RAND_PWD="true"

# Parse options
while getopts ":shd:n:e:p:w:" opt; do
    case $opt in
        h)
            help
            ;;
        d)
            BASE_DOMAIN=$OPTARG
            HELM_OPTS="$HELM_OPTS --set 'ingress.hosts[0].domain=$BASE_DOMAIN' --set 'ingress.hostname=$BASE_DOMAIN'"
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
        p)
            PASSWORD=$OPTARG
            RAND_PWD="false"
            ;;
        w)
            WAR_PATH=$OPTARG
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

if [ "$RAND_PWD" = "true" ]; then
    echo "${yellow}No password provided for tomcat, using a random one.$normal"
fi

HELM_OPTS="$HELM_OPTS --set 'tomcatPassword=$PASSWORD'"

declare -A var
declare -A opt
declare -A env

# Remove parsed options
shift "$(expr $OPTIND - 1)"

while test $# -gt 0; do
    opt["$(echo "$1" | cut -d '=' -f 1)"]="$(echo "$1" | cut -d '=' -f 2)"
    shift
done

#    To not throw an error if not set 👇
envgrep="$(env | { grep '^AGROLD_' || true; })"

for e in ${envgrep[*]}; do
    env[$(echo "$e" | cut -d '=' -f 1)]="$(echo "$e" | cut -d '=' -f 2)"
done 

var[AGROLD_NAME]="${env[AGROLD_NAME]:=agrold}"
var[AGROLD_DESCRIPTION]="${env[AGROLD_DESCRIPTION]:=}"
var[AGROLD_BASEURL]="${env[AGROLD_BASEURL]:=http://vmagrold-proto}"
var[AGROLD_SPARQL_ENDPOINT]="${env[AGROLD_SPARQL_ENDPOINT]:=http://sparql.southgreen.fr}"
var[AGROLD_DB_CONNECTION_URL]="${env[AGROLD_DB_CONNECTION_URL]}"
var[AGROLD_DB_USERNAME]="${env[AGROLD_DB_USERNAME]}"
var[AGROLD_DB_PASSWORD]="${env[AGROLD_DB_PASSWORD]}"

for v in "${!var[@]}"; do
    var["$v"]="${opt[$v]:=${var[$v]}}"
    if [ "$v" = "AGROLD_DB_CONNECTION_URL" ] || 
       [ "$v" = "AGROLD_DB_USERNAME" ] || 
       [ "$v" = "AGROLD_DB_PASSWORD" ]; then
        if [ -z "${var[$v]}" ]; then
            echo "${red}Missing $v$normal"
            exit 1
        fi
    fi

    CATALINA_OPTS="$CATALINA_OPTS -D$(echo "$v" | awk -F '=' '/^AGROLD/ { lwr=tolower($1); sub(/_/, ".", lwr); print lwr }')=\"${var[$v]}\""
done

HELM_OPTS="$HELM_OPTS --set 'catalinaOpts=$CATALINA_OPTS'"

if [[ -n $(command -v kubectl) ]] && [[ -n $(command -v helm) ]]; then
    if [ "$DRY_RUN" = "true" ]; then
        echo "Running in dry-run mode, no changes will be made"
        echo "Helm options: $HELM_OPTS"
        
        kubectl create configmap dataset --dry-run=client --from-file=./dataset
    else
        #because apply does not crash if the configmap already exists, we need to check if it exists before running helm
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

    if [ "$DRY_RUN" = "true" ]; then
        echo "${yellow}> kubectl wait deployment -n ${NAMESPACE:=default} tomcat --for condition=Available=True --timeout=90s"
        echo "> POD=\$(kubectl get pods -n ${NAMESPACE:=default} | grep tomcat | awk '{print \$1}' | head -n 1\)"
    else
        echo "${yellow}Waiting for tomcat deployment to be ready${normal}"
        kubectl wait deployment -n "${NAMESPACE:=default}" tomcat --for condition=Available=True --timeout=90s
        POD="$(kubectl get pods -n ${NAMESPACE:=default} | grep tomcat | awk '{print $1}' | head -n 1)"
    fi


    if [ -n "$WAR_PATH" ]; then
        echo "${yellow}Installing war file(s)${normal}"
        if [ "$DRY_RUN" = "true" ]; then
        # Since the persistence storage volume is shared we will just copy the war file to a random pod
            echo "> kubectl cp $WAR_PATH ${NAMESPACE:=default}/tomcat-abcdefghij-klmno:/bitnami/tomcat/webapps/aldp.war${normal}"
        else
            kubectl cp "$WAR_PATH" "${NAMESPACE:=default}/$POD:/bitnami/tomcat/webapps/aldp.war"
            echo "${green}War file(s) installed!${normal}"
        fi
    fi

    echo "${yellow}Appling context.xml${normal}"
    if [ "$DRY_RUN" = "true" ]; then
        echo "${yellow}> kubectl cp ./context.xml ${NAMESPACE:=default}/tomcat-abcdefghij-klmno:/bitnami/tomcat/webapps/manager/META-INF/context.xml${normal}"
        echo "${yellow}Restart deployment tomcat${normal}"
        echo "${yellow}> kubectl rollout restart deployment your_deployment_name${normal}"
    else
        kubectl cp ./context.xml "${NAMESPACE:=default}/$POD:/bitnami/tomcat/webapps/manager/META-INF/context.xml"
        echo "${yellow}Restart deployment tomcat${normal}"
        kubectl rollout restart deployment tomcat
    fi

    echo "${green}Done!$normal"
else
    echo "${red}Please install Kubectl and helm.$normal" >&2
    echo "You can install them both via the setup_kube.sh script." >&2
    exit 1
fi