#!/bin/bash

# script to startup hsds service
if [ $# -eq 1 ] && ([ $1 == "-h" ] || [ $1 == "--help" ]); then
   echo "Usage: runall.sh [count]"
   exit 1
fi

[ -z ${AWS_S3_GATEWAY}  ] && echo "Need to set AWS_S3_GATEWAY" && exit 1

[ -z ${BUCKET_NAME} ] && echo "No default bucket set - did you mean to export BUCKET_NAME?"

[ -z ${HSDS_ENDPOINT} ] && echo "Need to set HSDS_ENDPOINT" && exit 1

if [[ -z ${PUBLIC_DNS} ]] ; then
  if [[ ${HSDS_ENDPOINT} == "https://"* ]] ; then
     export PUBLIC_DNS=${HSDS_ENDPOINT:8}
  elif [[ ${HSDS_ENDPOINT} == "http://"* ]] ; then
     export PUBLIC_DNS=${HSDS_ENDPOINT:7}
  else
    echo "Invalid HSDS_ENDPOINT: ${HSDS_ENDPOINT}"  && exit 1
  fi
fi

if [ -z $AWS_IAM_ROLE ] ; then
  # if not using s3 or S3 without EC2 IAM roles, need to define AWS access keys
  [ -z ${AWS_ACCESS_KEY_ID} ] && echo "Need to set AWS_ACCESS_KEY_ID" && exit 1
  [ -z ${AWS_SECRET_ACCESS_KEY} ] && echo "Need to set AWS_SECRET_ACCESS_KEY" && exit 1
fi

if [ $# -gt 0 ]; then
  export CORES=$1
elif [ -z ${CORES} ] ; then
  export CORES=1
fi

# Docker Swarm does not use .env or local.env
# This is manual settings at this time

# export CORES=4
export HEAD_PORT=5100
export AN_PORT=6100
export SN_PORT=5101
export DN_PORT=6101
export AN_RAM=128m
export SN_RAM=128m
export DN_RAM=256m
export HEAD_RAM=128m
export CHUNK_MEM_CACHE_SIZE=128m
export MAX_CHUNK_SIZE=8m
export LOG_LEVEL=DEBUG
export RESTART_POLICY=on-failure
export ANONYMOUS_TTL=0
# export AWS_ACCESS_KEY_ID=1234567890
# export AWS_SECRET_ACCESS_KEY=ABCDEFGHIJKL
export BUCKET_NAME=hsds.test
export SYS_BUCKET_NAME=hsds.test
export AWS_REGION=us-east-1
export AWS_DYNAMODB_GATEWAY=
# export AWS_S3_GATEWAY=http://s3.amazonaws.com
export SERVER_NAME=hsdstest
export PUBLIC_DNS=cf.hdf.test

echo "AWS_S3_GATEWAY:" $AWS_S3_GATEWAY
echo "AWS_ACCESS_KEY_ID:" $AWS_ACCESS_KEY_ID
echo "AWS_SECRET_ACCESS_KEY: ******"
echo "BUCKET_NAME:"  $BUCKET_NAME
echo "CORES:" $CORES
echo "HSDS_ENDPOINT:" $HSDS_ENDPOINT
echo "PUBLIC_DNS:" $PUBLIC_DNS



if [[ ${HSDS_USE_HTTPS} ]] ; then
   echo "docker-compose.secure"
   # docker-compose -f docker-compose.secure.yml up -d --scale sn=${CORES} --scale dn=${CORES}
   docker stack deploy --compose-file docker-compose-v3.yml --scale sn=${CORES} --scale dn=${CORES}
else
   echo "docker-compose"
   #docker-compose -f docker-compose-v3.yml up -d --scale sn=${CORES} --scale dn=${CORES}
   docker stack deploy --compose-file docker-compose-v3.yml hsds
fi
