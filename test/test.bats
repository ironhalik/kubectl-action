# shellcheck disable=SC2030,SC2031
setup() {
    load 'lib/bats-support/load'
    load 'lib/bats-assert/load'

    export INPUT_DEBUG=true
    export BASE64_CONFIG="YXBpVmVyc2lvbjogdjEKY2x1c3RlcnM6Ci0gY2x1c3RlcjoKICAgIHNlcnZlcjogaHR0cDovL2V4YW1wbGUuY29tCiAgbmFtZTogdGVzdC1jbHVzdGVyCmNvbnRleHRzOgotIGNvbnRleHQ6CiAgICBjbHVzdGVyOiB0ZXN0LWNsdXN0ZXIKICAgIG5hbWVzcGFjZTogZGVmYXVsdAogICAgdXNlcjogdGVzdC11c2VyCiAgbmFtZTogdGVzdC1jb250ZXh0Ci0gY29udGV4dDoKICAgIGNsdXN0ZXI6ICIiCiAgICB1c2VyOiAiIgogIG5hbWU6IHRoZS1vdGhlci1jb250ZXh0CmN1cnJlbnQtY29udGV4dDogdGVzdC1jb250ZXh0CmtpbmQ6IENvbmZpZwpwcmVmZXJlbmNlczoge30KdXNlcnM6Ci0gbmFtZTogdGVzdC11c2VyCiAgdXNlcjoKICAgIHRva2VuOiB0ZXN0LXRva2VuCg=="
    export PLAIN_CONFIG="
apiVersion: v1
clusters:
- cluster:
    server: http://example.com
  name: test-cluster
contexts:
- context:
    cluster: test-cluster
    namespace: default
    user: test-user
  name: test-context
- context:
    cluster: ""
    user: ""
  name: the-other-context
current-context: test-context
kind: Config
preferences: {}
users:
- name: test-user
  user:
    token: test-token
"

    DIR="$(cd "$( dirname "${BATS_TEST_FILENAME}" )" > /dev/null 2>&1 && pwd)"
    PATH="${DIR}/../:${PATH}"
}

teardown() {
    echo "" > /kubeconfig
    rm -f /usr/local/bin/kubectl-action.d/*
}


@test "entrypoint is runnable" {
    run kubectl-action.sh
    assert_output --partial "Either config or eks_cluster must be specified"
    assert_failure
}


@test "base64 config is parsed" {
    export INPUT_CONFIG="${BASE64_CONFIG}"

    run kubectl-action.sh
    assert_output --partial "Assuming provided kube config is encoded in base64"
    assert_output --partial "apiVersion: v1"
    assert_output --partial "kind: Config"
    assert_output --partial "Current kubectl context: test-context"
    assert_success
}


@test "plain text config is parsed" {
    export INPUT_CONFIG="${PLAIN_CONFIG}"

    run kubectl-action.sh
    assert_output --partial "Assuming provided kube config is in plain text"
    assert_output --partial "apiVersion: v1"
    assert_output --partial "kind: Config"
    assert_output --partial "Current kubectl context: test-context"
    assert_success
}


@test "eks_cluster config is pulled" {
    export INPUT_EKS_CLUSTER="somecluster-dev"
    export AWS_DEFAULT_REGION=eu-west-1

    run kubectl-action.sh
    assert_output --partial "Getting kube config for cluster somecluster-dev"
    refute_output --partial "using role"
    assert_output --partial "Unable to locate credentials"
    assert_failure
}

@test "eks_cluster config and role_arn are being used" {
    export INPUT_EKS_CLUSTER="somecluster-dev"
    export INPUT_EKS_ROLE_ARN="arn:aws:iam::123456789012:role/Test"
    export AWS_DEFAULT_REGION=eu-west-1

    run kubectl-action.sh
    assert_output --partial "Getting kube config for cluster somecluster-dev using role arn:aws:iam::123456789012:role/Test"
    assert_output --partial "Unable to locate credentials"
    assert_failure
}


@test "provided context is being used" {
    export INPUT_CONFIG="${BASE64_CONFIG}"
    export INPUT_CONTEXT="the-other-context"
    
    run kubectl-action.sh
    assert_output --partial "Current kubectl context: the-other-context"
    assert_success
}


@test "missing context is failing" {
    export INPUT_CONFIG="${BASE64_CONFIG}"
    export INPUT_CONTEXT="fake-context"
    
    run kubectl-action.sh
    assert_output --partial "error: no context exists with the name"
    assert_failure
}


@test "provided namespace is being set" {
    export INPUT_CONFIG="${BASE64_CONFIG}"
    export INPUT_NAMESPACE="some-namespace"
    
    run kubectl-action.sh
    assert_output --partial "Current kubectl namespace: some-namespace"
    assert_success
}


@test "kubectl-action.d scripts are loaded" {
    export INPUT_CONFIG="${BASE64_CONFIG}"

    echo "echo Hello!" > /usr/local/bin/kubectl-action.d/00_hello
    echo "echo World!" > /usr/local/bin/kubectl-action.d/10_world
    
    run kubectl-action.sh
    assert_output --partial "Hello!"
    assert_output --partial "World!"
    assert_success
}


@test "base64 config is parsed (using env var)" {
    export CONFIG="${BASE64_CONFIG}"

    run kubectl-action.sh
    assert_output --partial "Assuming provided kube config is encoded in base64"
    assert_output --partial "Current kubectl context: test-context"
    assert_success
}


@test "input parsing order is correct" {
    export INPUT_CONFIG="${BASE64_CONFIG}"
    export CONFIG="gibberish-that-doesnt-matter-because-input-config-takes-precedence"

    run kubectl-action.sh
    assert_output --partial "Assuming provided kube config is encoded in base64"
    assert_output --partial "Current kubectl context: test-context"
    assert_success
}

@test "commands are being executed" {
    export INPUT_CONFIG="${BASE64_CONFIG}"
    export INPUT_RUN="echo some command"

    run kubectl-action.sh
    assert_output --partial "some command"
    assert_success
}

@test "commands are being executed (using env var)" {
    export INPUT_CONFIG="${BASE64_CONFIG}"
    export RUN="echo some command provided with env vars"

    run kubectl-action.sh
    assert_output --partial "some command provided with env vars"
    assert_success
}

@test "multiline commands are parsed and executed" {
    export INPUT_CONFIG="${BASE64_CONFIG}"
    export RUN="
echo line number one
echo line number two
cat /some-file
"

    echo some-file-contents > /some-file

    run kubectl-action.sh
    assert_output --partial "Running echo line number one"
    assert_output --partial "line number one"
    assert_output --partial "Running echo line number two"
    assert_output --partial "line number two"
    assert_output --partial "some-file-contents"
    assert_success
}
