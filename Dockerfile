FROM alpine:3.16@sha256:bc41182d7ef5ffc53a40b044e725193bc10142a1243f395ee852a8d9730fc2ad

LABEL author="Michał Weinert <michal@weinert.io>"

ARG TARGETARCH

RUN apk add --no-cache bash=~5.1
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV helm_version=3.10.0
ENV helm_checksum_amd64=bc102ba0c9d5fba18b520fbedf63d114e47426a6b6aa0337ecab4a327704d6ab
ENV helm_checksum_arm64=3d37439910b7140cc078eba6c34979321ec3c020db54f30a8a86a0d9e92bac85
ENV helm_checksum="helm_checksum_${TARGETARCH}"
LABEL helm-version="v${helm_version}"

ENV kubectl_version=1.25.2
ENV kubectl_checksum_amd64=8639f2b9c33d38910d706171ce3d25be9b19fc139d0e3d4627f38ce84f9040eb
ENV kubectl_checksum_arm64=b26aa656194545699471278ad899a90b1ea9408d35f6c65e3a46831b9c063fd5
ENV kubectl_checksum="kubectl_checksum_${TARGETARCH}"
LABEL kubectl-version="v${kubectl_version}"

ENV stern_version=1.22.0
ENV stern_checksum_amd64=cecafc0110310118fb77c0d9bcc7af8852fe4cfd8252d096b070c647b70d1cd9
ENV stern_checksum_arm64=478d25e974539d515eb2a365c7f8cdf50645015529910d9e4e550f9e01d2c1e6
ENV stern_checksum="stern_checksum_${TARGETARCH}"
LABEL stern-version="v${stern_version}"

ENV KUBECONFIG=/kubeconfig

RUN apk add --no-cache \
    'libssl1.1=~1.1.1t' \
    'libcrypto1.1=~1.1.1t' \
    'yq=~4.25' \
    'py3-pip=~22.1' &&\
    pip install --no-cache --disable-pip-version-check --no-input --root-user-action ignore --progress-bar off \
    'awscli>=1.25' &&\
    wget -q "https://get.helm.sh/helm-v${helm_version}-linux-${TARGETARCH}.tar.gz" -O - | tar xzf - -C /tmp/ --strip-components=1 linux-${TARGETARCH}/helm &&\
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
