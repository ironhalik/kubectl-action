This is a base image used for multiple Github Actions meant to interact with Kubernetes clusters.  
The idea here is to provide basic tools and methods for authentication and a simple extension interface in the form of docker-entrypoint.d directory. Any script added there in a child image will be executed in alphabetical order.

The image comes with recent versions of `kubectl`, `helm`, `stern`, and `aws-cli`.

The expected inputs are:  
- `debug` can be enabled explicitly via action input, or is implicitly enabled when a job is rerun with debug enabled. It exports `IS_DEBUG=1` variable to child scripts.
- `config` kubectl config file. Can be either a whole config file (e.g. via ${{ secrets.CONFIG }}), or base64 encoded.
- `eks_cluster` The name of the EKS cluster to get config for. Will use AWS CLI to generate a valid config. Will need standard `aws-cli` env vars and eks:DescribeCluster permission. Mutually exclusive with `config`.
- `context` kubectl config context to use. Not needed if the config has a context already selected.
- `eks_role_arn` IAM role ARN that should be assumed by `aws-cli` when interacting with EKS cluster.

Once the basic inputs are set, any kubectl dependent tools will have a config available.

If extending this base action, you'll need to add the following inputs to your action.yml
```
inputs:
  # Inputs from kubectl-action-base
  debug:
    description: "Adds action debug messages. Might contain sensitive data."
    required: false
  config:
    description: "Kubeconfig yaml contents. Can be base64 encoded or just yaml."
    required: false
  eks_cluster:
    description: "Name of the EKS cluster to interact with. Will use aws eks update-kubeconfig."
    required: false
  eks_role_arn:
    description: "The AWS IAM role to use when authenticating with EKS."
    required: false
  context:
    description: "Context to use if there are multiple."
    required: false
```

Many thanks to the creators of the tools included:  
[kubectl](https://github.com/kubernetes/kubectl), [helm](https://github.com/helm/helm), [stern](https://github.com/wercker/stern), [aws-cli](https://github.com/aws/aws-cli)