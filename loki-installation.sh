#!/bin/bash

# Add required helm repos to the cluster:
helm repo add grafana https://grafana.github.io/helm-charts

# Create namespace for loki
    
kubetcl create ns loki

# Create the secret for access key and secret access key to store the logs in AWS S3 bucket 
    
kubectl create secret generic iam-loki-s3 --from-literal=AWS_ACCESS_KEY_ID='<access_key>' --from-literal=AWS_SECRET_ACCESS_KEY='<secret_access_key>' -n loki

# Install Loki and Promtail
    
helm install loki grafana/loki-stack --values loki-values.yaml -n loki 

# Change Loki service from ClusterIP to LoadBalancer

kubectl patch service/loki -p '{"spec": {"type": "LoadBalancer"}}' -n loki