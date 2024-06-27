# Prometheus, Loki and Promtail
This directory contains installation guide for prometheus and grafana along with Loki and Promtail for logs visualization.

# Pre-requisites
**Assuming Grafana server and kubernetes cluster is up and running with kubectl command on server** 
If not then install [kubetctl] (https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) on linux server.  
Before we get started installing the Prometheus, ensure you install the latest version of [helm] (https://helm.sh/docs/intro/install/#from-script).

# Installation & Configuration

## Install Prometheus

1. Add required helm repos to the cluster:
```console
    helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```

2. Update the helm repo:
```console
    helm repo update
```

3. Create EBS CSI Driver:
```console
    helm upgrade --install aws-ebs-csi-driver \
        --namespace kube-system \
        --set enableVolumeScheduling=true \
        --set enableVolumeResizing=true \
        --set enableVolumeSnapshot=true \
        aws-ebs-csi-driver/aws-ebs-csi-driver
```

4. Create prometheus namespace:
```console
    kubectl create namespace prometheus
```

5. Create Storage Class for EBS volume:
```console
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
```

6. Install the prometheus:
```console
    helm install prometheus -f prometheus-values.yaml \
      prometheus-community/prometheus --namespace prometheus
```

**OR** simply execute the [prometheus-installation.sh](prometheus-installation.sh) by following command, which will install prometheus, node-exporter and kube metrics for promethues on the cluster by creating prometheus namespace. In this script we download the hemp chart for aws-ebs-csi-driver, prometheus-community.
```console
    bash -x prometheus-installation.sh
```

## Install Loki and Promtail 

1. Add Grafana helm repo and update it in the cluster:
```console
    helm repo add grafana https://grafana.github.io/helm-charts
```

2. Create namespace for loki
```console    
    kubetcl create ns loki
```

3. Create the secret for access key and secret access key to store the logs in AWS S3 bucket 
```console    
    kubectl create secret generic iam-loki-s3 --from-literal=AWS_ACCESS_KEY_ID='<access_key>' --from-literal=AWS_SECRET_ACCESS_KEY='<secret_access_key>' -n loki
```

4. Install Loki and Promtail
```console    
    helm install loki grafana/loki-stack --values loki-values.yaml -n loki 
```

5. Change Loki service from ClusterIP to LoadBalancer

Manually change the type to LoadBalancer
```console
    kubectl edit service/loki -n loki 
```

**OR** use follwoing command:
```console
    kubectl patch service/loki -p '{"spec": {"type": "LoadBalancer"}}' -n loki
```

**OR** simply execute the [loki-installation.sh](loki-installation.sh) by following command, which will install loki, and promtail on the cluster by creating loki namespace.

**After installation of prometheus and loki copy the loadbalancer DNS name and create a datasource in Grafana**