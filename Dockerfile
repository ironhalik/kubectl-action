FROM alpine:3.16@sha256:bc41182d7ef5ffc53a40b044e725193bc10142a1243f395ee852a8d9730fc2ad

LABEL author="Michał Weinert <michal@weinert.io>"

ENV kubectl_version=1.25.2
ENV kubectl_checksum=8639f2b9c33d38910d706171ce3d25be9b19fc139d0e3d4627f38ce84f9040eb
LABEL kubectl-version="v${kubectl_version}"

ENV helm_version=3.10.0
ENV helm_checksum=bc102ba0c9d5fba18b520fbedf63d114e47426a6b6aa0337ecab4a327704d6ab
LABEL helm-version="v${helm_version}"

ENV stern_version=1.22.0
ENV stern_checksum=cecafc0110310118fb77c0d9bcc7af8852fe4cfd8252d096b070c647b70d1cd9
LABEL stern-version="v${stern_version}"

ENV KUBECONFIG=/kubeconfig

RUN apk add --no-cache \
    'bash=~5.1' \
    'yq=~4.25' \
    'py3-pip=~22.1' &&\
    pip install --no-cache --disable-pip-version-check --no-input --root-user-action ignore --progress-bar off \
    'awscli>=1.25' &&\
    wget -q "https://storage.googleapis.com/kubernetes-release/release/v${kubectl_version}/bin/linux/amd64/kubectl" -O /tmp/kubectl &&\
    wget -q "https://get.helm.sh/helm-v${helm_version}-linux-amd64.tar.gz" -O - | tar xzf - -C /tmp/ --strip-components=1 linux-amd64/helm &&\
    wget -q "https://github.com/stern/stern/releases/download/v${stern_version}/stern_${stern_version}_linux_amd64.tar.gz" -O - | tar xzf - -C /tmp/  &&\
    sha256sum /tmp/kubectl | grep -q "${kubectl_checksum}" &&\
    sha256sum /tmp/helm | grep -q "${helm_checksum}" &&\
    sha256sum /tmp/stern | grep -q "${stern_checksum}" &&\
    chmod +x /tmp/kubectl /tmp/helm /tmp/stern &&\
    mv /tmp/kubectl /tmp/helm /tmp/stern /usr/local/bin/ &&\
    rm -rf /tmp/* &&\
    touch "${KUBECONFIG}" &&\
    chmod 600 "${KUBECONFIG}"
