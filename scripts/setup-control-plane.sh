#!/usr/bin/env bash
set -eu

_kubeadm_init() {
    echo "Check google reachable."
    ping -c1 packages.cloud.google.com
    GOOGLE_REACHABLE=$?

    # Install and setup control plane
    echo "Setup Kubernetes Control plane."
    K8S_IMAGE_REPO_URL=""
    if [ "$GOOGLE_REACHABLE" -ne 0 ];then
        K8S_IMAGE_REPO_URL="--image-repository=registry.aliyuncs.com/google_containers"
    fi

    sudo kubeadm init --v=5 $K8S_IMAGE_REPO_URL

    echo "Setting up kubectl for $(whoami)"
    set -x
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    echo 'source <(kubectl completion bash)' >> $HOME/.bashrc
    set +x

    sleep 1
    kubectl cluster-info
}

_install_cni_plugin() {
    echo "Install and configure cni"
    # https://kubernetes.io/docs/tasks/administer-cluster/network-policy-provider/cilium-network-policy/
    # curl -sSL https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz | sudo tar xzvfC - /usr/local/bin
    # cilium install

    kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml

    kubectl -n kube-system get pods
}

_install_helm() {
    # Install helm via offical script
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | sudo bash
}

_install_k9s() {
    k9s_download_url=$( curl  -w "%{redirect_url}" -o /dev/null -s https://github.com/derailed/k9s/releases/latest | perl -pe "s/tag/download/" )
    cd /usr/local/bin/ && curl -sSL $k9s_download_url/k9s_Linux_amd64.tar.gz | sudo tar zxvf -
}

main() {
    for func in $(grep -Po "^_\w+(?=\(\))" $0); do
        $func
    done
}

if [ $# -ne 0 ]; then
    eval "$1"
else 
    main
fi
