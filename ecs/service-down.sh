#!/usr/bin/env bash

if [[ $# -ne 1 ]]; then
    echo "Illegal number of parameters"
    echo "Usage:"
    echo "service-up.sh <service name>"
    exit 1
fi

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    TARGET="$(readlink "$SOURCE")"
    if [[ $TARGET == /* ]]; then
        echo "SOURCE '$SOURCE' is an absolute symlink to '$TARGET'"
        SOURCE="$TARGET"
    else
        SCRIPT_HOME="$( dirname "$SOURCE" )"
        echo "SOURCE '$SOURCE' is a relative symlink to '$TARGET' (relative to '$SCRIPT_HOME')"
        SOURCE="$SCRIPT_HOME/$TARGET" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    fi
done

# echo "SOURCE is '$SOURCE'"
RDIR="$( dirname "$SOURCE" )"
SCRIPT_HOME="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

# set env
set -e

# export environment variables
if [[ -f .env ]]; then
    source .env
elif [[ -f $SCRIPT_HOME/.env ]]; then
    source $SCRIPT_HOME/.env
fi

if [[ ! -d $1 ]]; then
    # Control will enter here if $DIRECTORY doesn't exist.
    echo "Service directory $1 not found!"
    if [[ ! -d $SCRIPT_HOME/$1 ]]; then
        # Control will enter here if $DIRECTORY doesn't exist.
        echo "Service directory $1 neither found in current directory nor in $SCRIPT_HOME!"
        exit 1
    else
        WORKING_DIRECTORY="$SCRIPT_HOME/$1"
    fi
else 
    WORKING_DIRECTORY="$( pwd )/$1"
fi
cd $WORKING_DIRECTORY
echo "Working directory is set to $WORKING_DIRECTORY"

if [[ -f $WORKING_DIRECTORY/.env ]]; then
    # Control will enter here if $DIRECTORY doesn't exist.
    source $WORKING_DIRECTORY/.env
fi

echo "Project name is $PROJECT_NAME"

if [[ -f $WORKING_DIRECTORY/stop.sh ]]; then
    # Delegate the responsibility to service's own script to run
    source $WORKING_DIRECTORY/stop.sh
    RC=$?
    if [[ $RC != 0 ]]; then 
        echo "Process returned $RC while trying to stop service $PROJECT_NAME"
        exit $RC
    fi
    echo "Service $PROJECT_NAME is down. :)"
    exit $RC
fi

ecs-cli configure --cluster "$CLUSTER_NAME" \
                  --region "$CLUSTER_REGION" \
                  --default-launch-type "$LAUNCH_TYPE" \
                  --config-name "$CLUSTER_CONFIG_NAME"
echo "Configured ECS cluster $CLUSTER_CONFIG_NAME"

exec ecs-cli compose service rm --cluster-config $CLUSTER_CONFIG_NAME --aws-profile $AWS_PROFILE