#!/bin/bash

#Add required helm repos to the cluster

echo "Adding helm repos to the cluster"
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
#helm repo add kube-state-metrics https://kubernetes.github.io/kube-state-metrics   //installed via prometheis values.yaml
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
#helm repo add grafana https://grafana.github.io/helm-charts

helm repo update

#Create EBS CSI Driver

echo "Installing aws-ebs-csi-driver using helm chart in kube-system namespace"
helm upgrade --install aws-ebs-csi-driver \
    --namespace kube-system \
    --set enableVolumeScheduling=true \
    --set enableVolumeResizing=true \
    --set enableVolumeSnapshot=true \
    aws-ebs-csi-driver/aws-ebs-csi-driver

sleep 20

#Create namespace
echo "Creating prometheus namespace"
kubectl create namespace prometheus

#Create Storage Class for EBS volume
echo "creating storage class to create a persistance volume for prometheus"
echo "
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: prometheus
  namespace: prometheus
provisioner: ebs.csi.aws.com
parameters:
  type: gp2
reclaimPolicy: Retain
allowedTopologies:
- matchLabelExpressions:
  - key: topology.ebs.csi.aws.com/zone
    values:
    - us-west-1a    //Change the availability Zone from Cluster region
    - us-west-1b    //Change the availability Zone from Cluster region
" | kubectl apply -f -


#Update the prometheus with namespace

echo "Installing promethues using helm charts"
helm install prometheus -f prometheus-values.yaml \
  prometheus-community/prometheus --namespace prometheus

#sleep 60

#Update the grafana with namespace


#echo "Installing prometheus and garafana using helm charts"

#helm install grafana -f prometheus_values.yml \
#  grafana/grafana --namespace prometheus

#helm install grafana -f grafana_values.yml \
#  grafana/grafana --namespace prometheus
