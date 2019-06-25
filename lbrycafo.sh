#!/bin/bash
exe() { ( echo "## $*"; $*; ) }

# Variables and constants
## dockerfile
## Environment

LBC_LBRY_DOCKER_REPO=${LBC_LBRY_DOCKER_REPO:-https://github.com/lbryio/lbry-docker}
LBC_LBRYNET_ORG_REPO=${LBC_ORG_REPO:-lbryio/lbry-sdk}
LBC_HOME=${LBC_HOME:-$HOME/.local/lbrycafo}
LBC_LBRY_DOCKER_HOME=$LBC_HOME/lbry-docker

## Internal vars

TEMPLATE_DIR=$LBC_HOME/templates
WALLET_DIR=$LBC_HOME/wallets
HOST_IP=127.0.0.1
LBRYNET_CONTAINER_NAME=lbrynet

# Subcommands

init() {
    if ! which git > /dev/null; then
        echo "Install git"
        exit 1
    fi
    if ! which docker > /dev/null; then
        echo "Install docker"
        exit 1
    fi
    exe mkdir -p $TEMPLATE_DIR/default
    exe mkdir -p $WALLET_DIR/default
    (
        cd $LBC_HOME
        exe git clone $LBC_LBRY_DOCKER_REPO $LBC_LBRY_DOCKER_HOME
    )
    cat <<'EOF' > $TEMPLATE_DIR/default/daemon_settings.yml
api: 127.0.0.1:5279
streaming_server: 127.0.0.1:5280
EOF
}

stop() {
    exe sudo docker kill $LBRYNET_CONTAINER_NAME
}

start() {
    if [ "$#" -eq 0 ]; then
        VERSION=$(curl -s https://api.github.com/repos/lbryio/lbry-sdk/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
        TEMPLATE=default
        WALLET=default

    elif [ "$#" -eq 1 ]; then
        VERSION=$1
        TEMPLATE=default
        WALLET=default

    elif [ "$#" -eq 2 ]; then
        VERSION=$1
        TEMPLATE=$2
        WALLET=default

    elif [ "$#" -eq 3 ]; then
        VERSION=$1
        TEMPLATE=$2
        WALLET=$3
    else
        echo "error: too many args"
        echo "lbrycafo VERSION [TEMPLATE [WALLET]]"
        exit 1
    fi

    TEMPLATE_PATH=$TEMPLATE_DIR/$TEMPLATE/daemon_settings.yml
    WALLET_PATH=$WALLET_DIR/$WALLET/
    if [ ! -f $TEMPLATE_PATH ]; then
        echo "error: template does not exist: $TEMPLATE_PATH"
        exit 1
    fi
    exe mkdir -p $WALLET_PATH

    DOCKER_TAG=lbrycafo-lbrynet:$VERSION
    (
        set -e
        cd $LBC_LBRY_DOCKER_HOME/lbrynet
        exe sudo docker build \
             -t $DOCKER_TAG \
             --build-arg VERSION=$VERSION \
             --build-arg REPO=https://github.com/$LBC_LBRYNET_ORG_REPO.git \
             -f Dockerfile-linux-multiarch-compiler .
    )

    exe sudo docker run --rm -d \
        -p $HOST_IP:5279:5279 \
        --name $LBRYNET_CONTAINER_NAME \
        -v $WALLET_PATH:/home/lbrynet \
        -v $TEMPLATE_PATH:/etc/lbry/daemon_settings.yml \
        $DOCKER_TAG

    exe sudo docker ps
}

## Main function to run all subcommands:
SUBCOMMANDS_NO_ARGS=(init stop)
SUBCOMMANDS_PASS_ARGS=(start)

if printf '%s\n' ${SUBCOMMANDS_NO_ARGS[@]} | grep -q -P "^$1$"; then
    ## Subcommands that take no arguments:
    (
        set -e
        if [ "$#" -eq 1 ]; then
            $*
        else
            echo "$1 does not take any additional arguments"
        fi
    )
elif printf '%s\n' ${SUBCOMMANDS_PASS_ARGS[@]} | grep -q -P "^$1$"; then
    ## Subcommands that pass all arguments:
    (
        set -e
        $*
    )
else
    if [[ $# -gt 0 ]]; then
        echo "## Invalid command: $1"
    else
        echo "## Must specify a command:"
    fi
    echo ""
    echo "##   lbry-cafo init"
    echo "##     - Initialize lbry-cafo"
    echo "##   lbry-cafo start [VERSION] [TEMPLATE] [WALLET]"
    echo "##     - Start lbrynet container"
    echo "##   lbry-cafo stop"
    echo "##     - Stop lbrynet container"
fi
