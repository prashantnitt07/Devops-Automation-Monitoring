provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "kubectl_manifest" "prometheus" {
  yaml_body = file("${path.module}/manifests/prometheus-deployment.yaml")
}
