#!/usr/bin/env bash

# set env
set -e

# export environment variables
source .env

# create sequrity group for ecs cluster
aws ec2 create-security-group \
        --group-name "${CONTAINER_INSTANCE_SG}" \
        --description "${CONTAINER_INSTANCE_SG_DESC}" \
        --vpc-id "${VPC}"
echo "security group created for ECS cluster container instance"

# create sequrity group for ecs ELB
aws ec2 create-security-group \
        --group-name "${ELB_SG_NAME}" \
        --description "${ELB_SG_DESC}" \
        --vpc-id "${VPC}"
echo "security group created for ELB"

# allow traffic for elb
aws ec2 authorize-security-group-ingress \
        --group-name "${ELB_SG_NAME}" \
        --protocol tcp \
        --port "${ELB_PORT}" \
        --cidr "${TRAFFIC_FROM_ANYWHERE}"
echo "allowed traffic for ELB"

# allow traffic from elb
aws ec2 authorize-security-group-ingress \
        --group-name "${CONTAINER_INSTANCE_SG}" \
        --protocol tcp \
        --port 1-65535 \
        --source-group "${ELB_SG_NAME}"
echo "allowed traffic from ELB to ECS container instance"

# get ELB security group_id
elb_sg_id=$(aws ec2 describe-security-groups --query "SecurityGroups[?GroupName=='$ELB_SG_NAME'].GroupId" --region "${CLUSTER_REGION}" --output text)
echo "Fetched security ELB group id=$elb_sg_id"

# create application load balancer
aws elbv2 create-load-balancer \
          --name "${ELB_NAME}" \
          --subnets $SUBNETS \
          --security-groups "${elb_sg_id}" \
          --tags "${KEY}=${OWNER_KEY},${VALUE}=${OWNER_NAME}" \
          --type "${ELB_TYPE}"
echo "created ELB"

# create tragetgroup for elb
aws elbv2 create-target-group \
          --name "${ELB_TG_NAME}" \
          --protocol HTTP \
          --port "${ELB_PORT}" \
          --vpc-id "${VPC}" \
          --health-check-path "${ELB_TG_HEALTH_CHECK_PATH}"
echo "created ELB TG"

elb_arn=$(aws elbv2 describe-load-balancers --names "${ELB_NAME}" | grep -i LoadBalancerArn | awk '{$1=$1};1' | cut -d " " -f 2 | cut -d "," -f 1 | sed 's/"//g')
echo "ELB ARN $elb_arn"

elb_tg_arn=$(aws elbv2 describe-target-groups --names "${ELB_TG_NAME}" | grep -i TargetGroupArn | awk '{$1=$1};1' | cut -d " " -f 2 | cut -d "," -f 1 | sed 's/"//g')
echo "ELB TG ARN $elb_tg_arn"

aws elbv2 create-listener \
          --load-balancer-arn "${elb_arn}" \
          --protocol HTTP --port "${ELB_PORT}"  \
          --default-actions Type=forward,TargetGroupArn="${elb_tg_arn}"
echo "attached ELB to TG"

ecs-cli configure --cluster "${CLUSTER_NAME}" \
                  --region "${CLUSTER_REGION}" \
                  --default-launch-type "${LAUNCH_TYPE}" \
                  --config-name "${CLUSTER_CONFIG_NAME}"

echo "configured ECS cluster"

ecs-cli up --security-group "${CONTAINER_INSTANCE_SG}" \
           --vpc "${VPC}" \
           --subnets $CLUSTER_SUBNETS \
           --keypair "${CONTAINER_INSTANCE_KP}" \
           --instance-type "${CONTAINER_INSTANCE_TYPE}" \
           --instance-role "${CONTAINER_INSTANCE_ROLE}" \
           --cluster-config "${CLUSTER_CONFIG_NAME}" \
           --size "${TOTAL_CONTAINER_INSTANCE}" \
            --tags "${OWNER_KEY}=${OWNER_NAME}" \
           --force

echo "ECS cluster up and running"