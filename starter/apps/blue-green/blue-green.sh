#!/bin/bash

function deploy_green {
    read -p "Deploy green deployment? (y/n) " answer
        if [[ $answer =~ ^[Yy]$ ]] ;
        then
            echo "Executing Green deployment..."
            kubectl apply -f green.yml
            kubectl apply -f index_green_html.yml
            ATTEMPTS=0
            ROLLOUT_STATUS_CMD="kubectl rollout status deployment/green -n udacity"
            until $ROLLOUT_STATUS_CMD || [ $ATTEMPTS -eq 60 ]; do
                $ROLLOUT_STATUS_CMD
                ATTEMPTS=$((attempts + 1))
                sleep 1
            done
            echo "Deployment successful!"
            ENDPOINT=$(kubectl get svc green-svc -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
            sleep 2
            echo "Testing endpoint..."
            until $(curl $ENDPOINT --output /dev/null --head --fail); do
                sleep 5
            done
            echo "Green endpoint online!"       
        else
            echo "Green deployment cancelled."
            exit
        fi
}

deploy_green