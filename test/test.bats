setup() {
    load 'lib/bats-support/load'
    load 'lib/bats-assert/load'

    export INPUT_DEBUG=true
    export BASE64_CONFIG="YXBpVmVyc2lvbjogdjEKY2x1c3RlcnM6Ci0gY2x1c3RlcjoKICAgIHNlcnZlcjogaHR0cDovL2V4YW1wbGUuY29tCiAgbmFtZTogdGVzdC1jbHVzdGVyCmNvbnRleHRzOgotIGNvbnRleHQ6CiAgICBjbHVzdGVyOiB0ZXN0LWNsdXN0ZXIKICAgIG5hbWVzcGFjZTogZGVmYXVsdAogICAgdXNlcjogdGVzdC11c2VyCiAgbmFtZTogdGVzdC1jb250ZXh0Ci0gY29udGV4dDoKICAgIGNsdXN0ZXI6ICIiCiAgICB1c2VyOiAiIgogIG5hbWU6IHRoZS1vdGhlci1jb250ZXh0CmN1cnJlbnQtY29udGV4dDogZGV2LWNvbnRleHQKa2luZDogQ29uZmlnCnByZWZlcmVuY2VzOiB7fQp1c2VyczoKLSBuYW1lOiB0ZXN0LXVzZXIKICB1c2VyOgogICAgdG9rZW46IHRlc3QtdG9rZW4="
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
current-context: dev-context
kind: Config
preferences: {}
users:
- name: test-user
  user:
    token: test-token
"

    DIR="$(cd "$( dirname ${BATS_TEST_FILENAME} )" > /dev/null 2>&1 && pwd)"
    PATH="${DIR}/../:${PATH}"
}

teardown() {
    echo "" > /kubeconfig
}


@test "entrypoint is runnable" {
    run docker-entrypoint.sh
    assert_failure
    assert_output --partial "Either config or eks_cluster must be specified"
}


@test "base64 config is parsed" {
    export INPUT_CONFIG="${BASE64_CONFIG}"

    run docker-entrypoint.sh
    assert_output --partial "Assuming provided kube config is encoded in base64"
    assert_output --partial "Current kubectl context: dev-context"
}


@test "plain text config is parsed" {
    export INPUT_CONFIG="${PLAIN_CONFIG}"

    run docker-entrypoint.sh
    assert_output --partial "Assuming provided kube config is in plain text"
    assert_output --partial "Current kubectl context: dev-context"
}


@test "eks_cluster config is pulled" {
    export INPUT_EKS_CLUSTER="somecluster-dev"
    export AWS_DEFAULT_REGION=eu-west-1

    run docker-entrypoint.sh
    assert_output --partial "Getting kube config for cluster somecluster-dev"
    assert_output --partial "Unable to locate credentials"
    assert_output --partial "error: current-context is not set"
}


@test "provided context is being used" {
    export INPUT_CONFIG="${BASE64_CONFIG}"
    export INPUT_CONTEXT="the-other-context"
    
    run docker-entrypoint.sh
    assert_output --partial "Current kubectl context: the-other-context"
}


@test "missing context is failing" {
    export INPUT_CONFIG="${BASE64_CONFIG}"
    export INPUT_CONTEXT="fake-context"
    
    run docker-entrypoint.sh
    assert_output --partial "error: no context exists with the name"
    assert_failure
}


@test "docker-entrypoint.d scripts are loaded" {
    export INPUT_CONFIG="${BASE64_CONFIG}"

    echo "echo Hello!" > /usr/local/bin/docker-entrypoint.d/00_hello
    echo "echo World!" > /usr/local/bin/docker-entrypoint.d/10_world
    
    run docker-entrypoint.sh
    assert_output --partial "Hello!"
    assert_output --partial "World!"

    rm /usr/local/bin/docker-entrypoint.d/*
}