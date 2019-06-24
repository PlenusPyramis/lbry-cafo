#!/bin/bash
exe() { ( echo "## $*"; $*; ) }

# Variables and constants
## dockerfile
## Environment

LBC_LBRY_DOCKER_REPO=${LBC_LBRY_DOCKER_REPO:-https://github.com/lbryio/lbry-docker.git}
LBC_LBRYNET_ORG_REPO=${LBC_LBRYNET_ORG_REPO:-lbryio/lbry-sdk}
LBC_HOME=${LBC_HOME:-$HOME/.local/lbrycafo}
LBC_LBRY_DOCKER_HOME=$LBC_HOME/lbry-docker


## Internal vars

TEMPLATE_DIR=$LBC_HOME/templates
WALLET_DIR=$LBC_HOME/wallets
HOST_IP=127.0.0.1

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
    set -e
    if [ "$#" -ne 0 ]; then
        echo "error: too many args"
        echo "lbrycafo stop"
    fi
    exe sudo docker kill lbrynet

}
start() {
    set -e
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
        --name lbrynet \
        -v $WALLET_PATH:/home/lbrynet \
        -v $TEMPLATE_PATH:/etc/lbry/daemon_settings.yml \
        $DOCKER_TAG

    exe sudo docker ps
}

## ifmain TODO: only specified subcommands can run

$*


