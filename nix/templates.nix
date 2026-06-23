_:
{
  flake.templates = {
    default = {
      path = ./templates;
      description = ''
        Template to write project build system
      '';
    };
    tp5-k8s = {
      path = ./templates-tp5;
      description = ''
        TP 5: Local Kubernetes with k3d — all tools included (k3d, kubectl, helm, k9s, argocd, kustomize, skaffold)
      '';
    };
  };
}
