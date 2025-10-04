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

# Apply Prometheus Deployment YAML
resource "kubectl_manifest" "prometheus_deployment" {
  yaml_body = file("${path.module}/manifests/prometheus-deployment.yaml")
  depends_on = [
    kubectl_manifest.prometheus_config,
    kubectl_manifest.prometheus_service
  ]
 replace_triggered_by = [
    file("${path.module}/manifests/prometheus-config.yaml")
  ]
}
