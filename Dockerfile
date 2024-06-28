FROM alpine:3.20@sha256:b89d9c93e9ed3597455c90a0b88a8bbb5cb7188438f70953fede212a0c4394e0

LABEL author="Michał Weinert <michal@weinert.io>"

ARG TARGETARCH

RUN apk add --no-cache \
    "bash=~5.2" \
    'yq=~4.44' \
    'aws-cli=~2.15'

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV helm_version=3.15.2
ENV helm_checksum_amd64=2dc819262ef5a362134322de223b9f39d42a2f2164b8ee62e3613a2a83b31e72
ENV helm_checksum_arm64=5e5e3b098aa808055ab6703112269c5a3891d37aaa945bc423554503985d2e74
ENV helm_checksum="helm_checksum_${TARGETARCH}"
LABEL helm-version="v${helm_version}"

ENV kubectl_version=1.30.2
ENV kubectl_checksum_amd64=c6e9c45ce3f82c90663e3c30db3b27c167e8b19d83ed4048b61c1013f6a7c66e
ENV kubectl_checksum_arm64=56becf07105fbacd2b70f87f3f696cfbed226cb48d6d89ed7f65ba4acae3f2f8
ENV kubectl_checksum="kubectl_checksum_${TARGETARCH}"
LABEL kubectl-version="v${kubectl_version}"

ENV stern_version=1.30.0
ENV stern_checksum_amd64=74f26ef1422be8bd3539a9f1e6e0738bf2f03e6b096bc7acd314dbbfaecb5943
ENV stern_checksum_arm64=fd1c721dda48e6d23f6f4cd3314e93ed7ecf62593ab4acdde6940b4dd9d7b568
ENV stern_checksum="stern_checksum_${TARGETARCH}"
LABEL stern-version="v${stern_version}"

ENV KUBECONFIG=/kubeconfig

RUN wget -q "https://get.helm.sh/helm-v${helm_version}-linux-${TARGETARCH}.tar.gz" -O - | tar xzf - -C /tmp/ --strip-components=1 linux-${TARGETARCH}/helm &&\
    wget -q "https://storage.googleapis.com/kubernetes-release/release/v${kubectl_version}/bin/linux/${TARGETARCH}/kubectl" -O /tmp/kubectl &&\
    wget -q "https://github.com/stern/stern/releases/download/v${stern_version}/stern_${stern_version}_linux_${TARGETARCH}.tar.gz" -O - | tar xzf - -C /tmp/  &&\
    sha256sum /tmp/helm | grep -q "${!helm_checksum}" &&\
    sha256sum /tmp/kubectl | grep -q "${!kubectl_checksum}" &&\
    sha256sum /tmp/stern | grep -q "${!stern_checksum}" &&\
    chmod +x /tmp/kubectl /tmp/helm /tmp/stern &&\
    mv /tmp/kubectl /tmp/helm /tmp/stern /usr/local/bin/ &&\
    rm -rf /tmp/* &&\
    touch "${KUBECONFIG}" &&\
    chmod 600 "${KUBECONFIG}" &&\
    mkdir -p /usr/local/bin/kubectl-action.d/

COPY kubectl-action.sh /usr/local/bin/
ENTRYPOINT ["kubectl-action.sh"]
