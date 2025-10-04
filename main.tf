terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

provider "kubectl" {
  config_path = "~/.kube/config"
}

# Create monitoring namespace
resource "kubectl_manifest" "monitoring_namespace" {
  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
YAML
}

# Apply Prometheus ConfigMap YAML
resource "kubectl_manifest" "prometheus_config" {
  yaml_body = file("${path.module}/manifests/prometheus-config.yaml")
  depends_on = [kubectl_manifest.monitoring_namespace]
}

# Apply Prometheus Service YAML
resource "kubectl_manifest" "prometheus_service" {
  yaml_body = file("${path.module}/manifests/prometheus-service.yaml")
  depends_on = [kubectl_manifest.monitoring_namespace]
}

locals {
  prometheus_config_hash = filesha256("${path.module}/manifests/prometheus-config.yaml")
}
locals {
  prometheus_config_hash = filesha256("${path.module}/manifests/prometheus-service.yaml")
}
locals {
  prometheus_config_hash = filesha256("${path.module}/manifests/prometheus-deployment.yaml")
}

resource "kubectl_manifest" "prometheus_deployment" {
  yaml_body = templatefile("${path.module}/manifests/prometheus-deployment.yaml", {
    config_hash = local.prometheus_config_hash
  })
  depends_on = [
    kubectl_manifest.prometheus_config,
    kubectl_manifest.prometheus_service
  ]
}
