_: {
  config.perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          # Kubernetes cluster
          k3d
          kubectl
          kubernetes-helm

          # Cluster visualization
          k9s

          # GitOps & deployment
          argocd
          kustomize
          skaffold

          # Utilities
          curl
          jq
        ];
        shellHook = ''
          echo "🚀 TP 5: Local Kubernetes with k3d"
          echo ""
          echo "Available tools:"
          echo "  k3d       - Local Kubernetes clusters in Docker"
          echo "  kubectl   - Kubernetes CLI"
          echo "  helm      - Kubernetes package manager"
          echo "  k9s       - Terminal UI for Kubernetes"
          echo "  argocd    - GitOps continuous delivery"
          echo "  kustomize - Kubernetes configuration management"
          echo "  skaffold  - Local Kubernetes development"
          echo ""
          echo "Get started: k3d cluster create my-cluster --image rancher/k3s:v1.31.6-k3s1 --port 8080:80@loadbalancer --port 8443:443@loadbalancer --agents 2"
        '';
      };
    };
}
