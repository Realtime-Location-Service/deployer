#!/usr/bin/env bash

# set env
set -e

# export environment variables
source .env

ecs-cli down --cluster "${CLUSTER_NAME}" -f
echo "deleted cluster"

sleep "${DELAY}"

elb_arn=$(aws elbv2 describe-load-balancers --names "${ELB_NAME}" | grep -i LoadBalancerArn | awk '{$1=$1};1' | cut -d " " -f 2 | cut -d "," -f 1 | sed 's/"//g')
echo "${elb_arn}"

aws elbv2 delete-load-balancer --load-balancer-arn  "${elb_arn}"
echo "deleted ELB"

sleep "${DELAY}"

elb_tg_arn=$(aws elbv2 describe-target-groups --names "${ELB_TG_NAME}" | grep -i TargetGroupArn | awk '{$1=$1};1' | cut -d " " -f 2 | cut -d "," -f 1 | sed 's/"//g')
echo "${elb_tg_arn}"

aws elbv2 delete-target-group --target-group-arn "${elb_tg_arn}"
echo "deleted ELB target group"

aws ec2 delete-security-group --group-name "${CONTAINER_INSTANCE_SG}"
echo "deleted container instance security group"

sleep "${DELAY}"

aws ec2 delete-security-group --group-name "${ELB_SG_NAME}"
echo "deleted ELB security group"
