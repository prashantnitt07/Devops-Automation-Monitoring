terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "kubectl" {
  config_path = "~/.kube/config"
}

# Create monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# Apply Prometheus ConfigMap YAML
resource "kubectl_manifest" "prometheus_config" {
  yaml_body = file("${path.module}/manifests/prometheus-config.yaml")
  depends_on = [kubernetes_namespace.monitoring]
}

# Apply Prometheus Service YAML
resource "kubectl_manifest" "prometheus_service" {
  yaml_body = file("${path.module}/manifests/prometheus-service.yaml")
  depends_on = [
    kubectl_manifest.prometheus_config
  ]
}

# Apply Prometheus Deployment YAML
resource "kubectl_manifest" "prometheus" {
  yaml_body = file("${path.module}/manifests/prometheus-deployment.yaml")
  depends_on = [
    kubectl_manifest.prometheus_config,
    kubectl_manifest.prometheus_service
  ]
}
