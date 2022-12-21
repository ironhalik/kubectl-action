#!/bin/bash
set -eo pipefail

# Logging function
# log [level] [msg] [msg]
log() {
    local log_level="${1}"
    shift
    if [ "${log_level}" == "info" ]; then
        echo -e "${*}"
    else
        echo -e "${*}" | sed "s/^/::${log_level}:: /g"
    fi
}


# Prepare inputs
# RUNNER_DEBUG is set by GHA when a rerun with debug is used
if [ -n "${INPUT_DEBUG}" ] || [ -n "${DEBUG}" ] || [ -n "${RUNNER_DEBUG}" ]; then
    # shellcheck disable=SC2034
    IS_DEBUG=1
fi
# shellcheck disable=SC2034
IS_KUBECTL_ACTION_BASE=1
# We support every input parameter as an env var
CONFIG="${INPUT_CONFIG:-${CONFIG}}"
EKS_CLUSTER="${INPUT_EKS_CLUSTER:-${EKS_CLUSTER}}"
EKS_ROLE_ARN="${INPUT_EKS_ROLE_ARN:-${EKS_ROLE_ARN}}"
CONTEXT="${INPUT_CONTEXT:-${CONTEXT}}"
NAMESPACE="${INPUT_NAMESPACE:-${NAMESPACE}}"


# Prepare kubeconfig
if [ -n "${CONFIG}" ]; then
    log info "Writing kube config to ${KUBECONFIG}."
    if [[ "${CONFIG}" =~ ^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)?$ ]]; then
        log debug "Assuming provided kube config is encoded in base64."
        echo "${CONFIG}" | base64 -d > "${KUBECONFIG}"
    else
        log debug "Assuming provided kube config is in plain text."
        echo "${CONFIG}" > "${KUBECONFIG}"
    fi
elif [ -n "${EKS_CLUSTER}" ]; then
    if [ -n "${EKS_ROLE_ARN}" ]; then
        log info "Getting kube config for cluster ${EKS_CLUSTER} using role ${EKS_ROLE_ARN}"
        log debug "$(aws eks update-kubeconfig --name ${EKS_CLUSTER} --role-arn ${EKS_ROLE_ARN})"
    else
        log info "Getting kube config for cluster ${EKS_CLUSTER}"
        log debug "$(aws eks update-kubeconfig --name ${EKS_CLUSTER})"
    fi
else
    log error "Either config or eks_cluster must be specified."
    exit 2
fi
log debug "${KUBECONFIG} contents:"
log debug "$(cat ${KUBECONFIG})"

if [ -n "${CONTEXT}" ]; then
    log info "Setting kubectl context to ${CONTEXT}"
    kubectl config use-context "${CONTEXT}"
fi
current_context="$(kubectl config current-context)"
log debug "Current kubectl context: ${current_context}"

if [ -n "${NAMESPACE}" ]; then
    log info "Setting namespace to ${NAMESPACE}"
    kubectl config set-context --current --namespace "${NAMESPACE}"
fi
current_namespace="$(kubectl config view --minify -o jsonpath='{..namespace}')"
log debug "Current kubectl namespace: ${current_namespace}"

if [ "$(ls -A /usr/local/bin/docker-entrypoint.d/)" ]; then
    for file in /usr/local/bin/docker-entrypoint.d/*; do
        # shellcheck source=/dev/null
        source "${file}"
    done
fi
