Action that lets you run kubectl commands and can be easily extended with other tools in the k8s ecosystem.

---

The base image and script provides tools and methods for authentication and a simple extension interface in the form of kubectl-action.d directory. Any script added there in a child image will be executed in alphabetical order.

The image comes with recent versions of `kubectl`, `helm`, `stern`, and `aws-cli`.

Expected inputs are:  
- `debug` can be enabled explicitly via action input, or is implicitly enabled when a job is rerun with debug enabled. It exports `IS_DEBUG=1` variable to child scripts.
- `config` kubectl config file. Can be either a whole config file (e.g. via ${{ secrets.CONFIG }}), or base64 encoded.
- `eks_cluster` The name of the EKS cluster to get config for. Will use AWS CLI to generate a valid config. Will need standard `aws-cli` env vars and eks:DescribeCluster permission. Mutually exclusive with `config`.
- `context` kubectl config context to use. Not needed if the config has a context already selected.
- `eks_role_arn` IAM role ARN that should be assumed by `aws-cli` when interacting with EKS cluster.
- `namespace` kubectl namespace to use. Same behaviour as in kubectl.
- `run` Scripts to run. Can be multiple lines. Will run before kubectl-action.d scripts.

All inputs can be provided using environment variables (as capitalized input name, eg. eks_cluster would be EKS_CLUSTER).

Once the basic inputs are set, any kubectl dependent tools will have a config available.

When extending this action, you'll need to add the following inputs to your action.yml
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
  namespace:
    description: "Namespace to use."
    required: false
  run:
    description: "Scripts to run. Can be multiple lines. Will run before kubectl-action.d scripts."
    required: false
```

Many thanks to the creators of the tools included:  
[kubectl](https://github.com/kubernetes/kubectl), [helm](https://github.com/helm/helm), [stern](https://github.com/wercker/stern), [aws-cli](https://github.com/aws/aws-cli)