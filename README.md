# env0 Agent - Helm Chart
This is a Helm Chart for installing env0 agent on your Kubernetes cluster.  

## Prerequisites
- A Kubernetes cluster with autoscaler. You may use our `prerequisites` stack to deploy an EKS based solution to your AWS account, or setup your own compatible cluster elsewhere.  
- A Kubernetes `StorageClass` named `env0-state-sc` that supports [Dynamic Provisioning](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#dynamic) and [`ReadWriteMany` access mode](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes). This is where env0 stores your terraform state files.
  - NOTE: that if you are using our state encryption feature, you don't need to provide a `StorageClass` as we will use `env0StateEncryptionKey` (provided in the `values.yaml`) to encrypt your state and store it on a remote storage.
- A dedicated `values.yaml` file provided to you by env0 - this file holds your key and secret to integrate your agent with env0.  
  Please see our [Business tier pricing](https://www.env0.com/pricing) and contact us to obtain the file for your agent.    
  
## Installation

Follow [this guide](https://docs.env0.com/docs/self-hosted-kubernetes-agent#installation) for more information on how to install env0's chart.

## Changelog
Can be found in both `CHANGELOG.md` file and in a release description.

-----

For more information, please refer to the [env0 official docs](https://docs.env0.com/docs/self-hosted-kubernetes-agent).
