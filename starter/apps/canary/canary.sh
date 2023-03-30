#!/bin/bash

DEPLOY_INCREMENTS=2

function manual_verification {
  read -p "Continue deployment? (y/n) " answer

    if [[ $answer =~ ^[Yy]$ ]] ;
    then
        echo "continuing deployment"
    else
        exit
    fi
}

function canary_deploy {
  NUM_OF_V1_PODS=$(kubectl get pods -n udacity | grep -c canary-v1)
  echo "V1 PODS: $NUM_OF_V1_PODS"
  NUM_OF_V2_PODS=$(kubectl get pods -n udacity | grep -c canary-v2)
  echo "V2 PODS: $NUM_OF_V2_PODS"

  kubectl scale deployment canary-v2 -n udacity --replicas=$((NUM_OF_V2_PODS + $DEPLOY_INCREMENTS))
  kubectl scale deployment canary-v1 -n udacity --replicas=$((NUM_OF_V1_PODS - $DEPLOY_INCREMENTS))
  # Check deployment rollout status every 1 second until complete.
  ATTEMPTS=0
  ROLLOUT_STATUS_CMD="kubectl rollout status deployment/canary-v2 -n udacity"
  until $ROLLOUT_STATUS_CMD || [ $ATTEMPTS -eq 60 ]; do
    $ROLLOUT_STATUS_CMD
    ATTEMPTS=$((attempts + 1))
    sleep 1
  done
  echo "Canary deployment of $DEPLOY_INCREMENTS replicas successful!"
}

function canary_curl {
  SVC_IP=$(kubectl get svc canary-svc -n udacity -o jsonpath="{.status.loadBalancer.ingress[*].ip}") #https://stackoverflow.com/questions/45001915/using-kubectl-or-kubernetes-api-to-fetch-external-ip-of-a-service
  for i in {1..10}
    do
      curl $SVC_IP --silent >> canary.txt
    done
}

# Initialize canary-v2 deployment
kubectl apply -f canary-v2.yml

sleep 1
# Begin canary deployment
while [ $(kubectl get pods -n udacity | grep -c canary-v1) -gt 0 ]
do
  canary_deploy
  manual_verification
  if [ $(kubectl get pods -n udacity | grep -c canary-v1) -eq $(kubectl get pods -n udacity | grep -c canary-v2) ]
  then
    echo "Canary deployment has reached 50% - testing load distribution - see canary.txt"
    canary_curl
  fi  
done

echo "Canary deployment of v2 successful"
