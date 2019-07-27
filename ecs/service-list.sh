
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

ecs-cli configure --cluster "$CLUSTER_NAME" \
                  --region "$CLUSTER_REGION" \
                  --default-launch-type "$LAUNCH_TYPE" \
                  --config-name "$CLUSTER_CONFIG_NAME"
echo "Configured ECS cluster $CLUSTER_CONFIG_NAME"

exec ecs-cli ps --cluster-config $CLUSTER_CONFIG_NAME --aws-profile $AWS_PROFILE