#!/bin/bash

 
if [ $# -eq 0 ] || [ $1 == "-h" ] || [ $1 == "--help" ]; then
   echo "Usage: run.sh [head|dn|sn|stopdn|stopsn|clean] [count]"
   exit 1
fi

count=1
if [ $# -eq 2 ]; then 
  count=$2
fi
  
 
#
# Define common variables
#
NODE_TYPE="head_node"
HEAD_PORT=5100
DN_PORT=5101
SN_PORT=5102

#
# run container given in arguments
#
if [ $1 == "head" ]; then
  echo "run head_node - ${HEAD_PORT}"
  docker run -d -p ${HEAD_PORT}:${HEAD_PORT} --name hsds_head \
  --env TARGET_SN_COUNT=${count} \
  --env TARGET_DN_COUNT=${count} \
  --env HEAD_PORT=${HEAD_PORT} \
  --env NODE_TYPE="head_node"  \
  --env AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
  --env AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
  hdfgroup/hsds  
elif [ $1 == "dn" ]; then
  echo "run dn"
  
  for i in $(seq 1 $count);
    do    
      NAME="hsds_dn_"$(($i-1))
      docker run -d -p ${DN_PORT}:${DN_PORT} --name $NAME \
        --env DN_PORT=${DN_PORT} \
        --env HEAD_HOST="hsds_head" \
        --env HEAD_PORT=${HEAD_PORT} \
        --env NODE_TYPE="dn"  \
        --env AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
        --env AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
        --link hsds_head:hsds_head \
        hdfgroup/hsds
      DN_PORT=$(($DN_PORT+2))
    done
elif [ $1 == "sn" ]; then
  echo "run sn"
  for i in $(seq 1 $count);
    do    
      NAME="hsds_sn_"$(($i-1))
      docker run -d -p ${SN_PORT}:${SN_PORT} --name $NAME \
        --env SN_PORT=${SN_PORT} \
        --env HEAD_HOST="hsds_head" \
        --env HEAD_PORT=${HEAD_PORT} \
        --env NODE_TYPE="sn"  \
        --env AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
        --env AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
        --link hsds_head:hsds_head \
        hdfgroup/hsds
      SN_PORT=$(($SN_PORT+2))
    done    
elif [ $1 == "stopdn" ]; then
   for i in $(seq 1 $count);
     do    
        DN_NAME="hsds_dn_"$(($i-1))   
        docker stop $DN_NAME &
     done
elif [ $1 == "stopsn" ]; then
   for i in $(seq 1 $count);
     do    
        SN_NAME="hsds_sn_"$(($i-1))
        docker stop $SN_NAME &
     done
elif [ $1 == "clean" ]; then
   echo "run_clean"
   docker rm -v $(docker ps -aq -f status=exited) 
fi
 


 

 