# env0 Agent - Helm Chart
This is a Helm Chart for installing env0 agent on your Kubernetes cluster.  

## Prerequisites
- A Kubernetes cluster with autoscaler. You may use our `prerequisites` stack to deploy an EKS based solution to your AWS account, or setup your own compatible cluster elsewhere.  
- A Kubernetes `StorageClass` named `env0-state-sc` that supports [Dynamic Provisioning](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#dynamic) and [`ReadWriteMany` access mode](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes). This is where env0 stores your terraform state files.
  - NOTE: that if you are using our state encryption feature, you don't need to provide a `StorageClass` as we will use `env0StateEncryptionKey` (provided in the `values.yaml`) to encrypt your state and store it on a remote storage. It must be base64 encoded - see [Secret values](#secret-values).
- A dedicated `values.yaml` file provided to you by env0 - this file holds your key and secret to integrate your agent with env0.  
  Please see our [Business tier pricing](https://www.env0.com/pricing) and contact us to obtain the file for your agent.    
  
## Secret values

Credentials and keys in `values.yaml` are written into a Kubernetes `Secret` under `data:`, which
Kubernetes base64-decodes before handing the values to the agent. **Every one of them must therefore
be supplied base64 encoded**, whether or not its name ends in `Encoded`:

```bash
printf '%s' 'my-state-passphrase' | base64 -w0
```

Two things to watch for:

- The docker agent takes `ENV0_STATE_ENCRYPTION_KEY` as a plain environment variable. The same key
  in `values.yaml` must be encoded, so the two installation methods do not take the same string.
- Encode the key *as text*. If env0 gave you a generated key that is already a base64 or hex string,
  encode that string - not the bytes behind it. A value that decodes to raw bytes cannot be passed to
  a container as an environment variable, and the agent will fail to start.

The chart rejects values that break either rule at install time, naming the value at fault.

`agentAccessToken` is the exception: the chart encodes it for you, so supply it as-is.

## Installation

Follow [this guide](https://docs.env0.com/docs/self-hosted-kubernetes-agent#installation) for more information on how to install env0's chart.

## Changelog
Can be found in both `CHANGELOG.md` file and in a release description.

-----

For more information, please refer to the [env0 official docs](https://docs.env0.com/docs/self-hosted-kubernetes-agent).
