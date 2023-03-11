#!/bin/bash
######################
#  Set the variables #
#                    #
######################

clusterName='default'
## the Namespace and ServiceAccount name that is used for the config
namespace='argo-ci'
serviceAccount='argo-executor'
## New Kubeconfig file name
newfile='config'

######################
#  Main Script       #
#                    #
######################

server="https://private-ip:6443"
secretName='argo-executor.rollout-sa'
ca=$(kubectl --namespace $namespace get secret/$secretName -o jsonpath='{.data.ca\.crt}')
token=$(kubectl --namespace $namespace get secret/$secretName -o jsonpath='{.data.token}' | base64 --decode)

echo "
---
apiVersion: v1
kind: Config
clusters:
  - name: ${clusterName}
    cluster:
      certificate-authority-data: ${ca}
      server: ${server}
contexts:
  - name: ${serviceAccount}@${clusterName}
    context:
      cluster: ${clusterName}
      namespace: ${namespace}
      user: ${serviceAccount}
users:
  - name: ${serviceAccount}
    user:
      token: ${token}
current-context: ${serviceAccount}@${clusterName}
" >> ${newfile}