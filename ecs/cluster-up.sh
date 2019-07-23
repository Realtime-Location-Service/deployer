#!/usr/bin bash

# set env
set -e

# create sequrity group for ecs cluster
aws ec2 create-security-group --group-name "${CONTAINER_INSTANCE_SG_NAME}" --description "${CONTAINER_INSTANCE_SG_DESC}"

# create sequrity group for ecs ELB
aws ec2 create-security-group --group-name "${ELB_SG_NAME}" --description "${ELB_SG_DESC}"

# allow trafic for elb
aws ec2 authorize-security-group-ingress --group-name "${ELB_SG_NAME}" --protocol tcp --port "${ELB_PORT}" --source-group "${TRAFFIC_FROM_ANYWHERE}"

# allow traffic from elb
aws ec2 authorize-security-group-ingress --group-name "${CONTAINER_INSTANCE_SG_NAME}" --protocol tcp --port 1-65535 --source-group "${ELB_SG_NAME}"

# get ELB security group_id
ELB_SG_IDS=$(aws ec2 describe-security-groups --query "SecurityGroups[?GroupName=='$ELB_SG_NAME'].GroupId" --region "${CLUSTER_REGION}" --output text)

# create application load balancer
aws elbv2 create-load-balancer --name "${ELB_NAME}" --type "${ELB_TYPE}" --subnets "${SUBNETS}" --security-groups "${ELB_SG_IDS[0]}"

# create tragetgroup for elb
aws elbv2 create-target-group --name "${ELB_TG_NAME}" --protocol HTTP --port "${ELB_PORT}" --vpc-id "${VPC}"

# export environment variables
export "$(grep -v '^#' $(PWD)/.env | xargs)"

ecs-cli configure --cluster "${CLUSTER_NAME}" \
                  --region "${CLUSTER_REGION}" \
                  --default-launch-type "${LAUNCH_TYPE}" \
                  --config-name "${CLUSTER_CONFIG_NAME}"

ecs-cli up --security-group "${CONTAINER_INSTANCE_SG_NAME}" \
           --vpc "${VPC}" \
           --subnets "${SUBNETS}" \
           --keypair "${CONTAINER_INSTANCE_KP}" \
           --instance-type "${CONTAINER_INSTANCE_TYPE}" \
           --instance-role "${CONTAINER_INSTANCE_ROLE}" \
           --cluster-config "${CLUSTER_CONFIG_NAME}" \
           --size "${TOTAL_CONTAINER_INSTANCE}" \
           --port "${CLUSTER_INBOUND_PORT}" \
           --tags "${OWNER}=${OWNER_NAME}" \
           --force
