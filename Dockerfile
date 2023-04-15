FROM alpine:3.17@sha256:124c7d2707904eea7431fffe91522a01e5a861a624ee31d03372cc1d138a3126

LABEL author="Michał Weinert <michal@weinert.io>"

ARG TARGETARCH

RUN apk add --no-cache \
    "bash=~5.2" \
    'yq=~4.30' \
    'aws-cli=~1.25'

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV helm_version=3.11.3
ENV helm_checksum_amd64=1f4c31531e5b077e2b5d44016908eeef970eb4540b3bfe8a0fc78e1a933df1c0
ENV helm_checksum_arm64=bd5e3e6733ed58e6448619ce9baad6a95be20123b74ab8510bb0e4b484988407
ENV helm_checksum="helm_checksum_${TARGETARCH}"
LABEL helm-version="v${helm_version}"

ENV kubectl_version=1.27.1
ENV kubectl_checksum_amd64=7fe3a762d926fb068bae32c399880e946e8caf3d903078bea9b169dcd5c17f6d
ENV kubectl_checksum_arm64=fd3cb8f16e6ed8aee9955b76e3027ac423b6d1cc7356867310d128082e2db916
ENV kubectl_checksum="kubectl_checksum_${TARGETARCH}"
LABEL kubectl-version="v${kubectl_version}"

ENV stern_version=1.25.0
ENV stern_checksum_amd64=1a89589da2694fadcec2e002ca6e38a3a5eab2096bbdd1c46a551b9f416bc75a
ENV stern_checksum_arm64=b76e32863cff4b15c23382a777a7e3763a688916a441c9cb2de04624673ab379
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

COPY kubectl-action.sh /usr/local/bin/
ENTRYPOINT ["kubectl-action.sh"]
