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
  prometheus_config_hash     = filesha256("${path.module}/manifests/prometheus-config.yaml")
  prometheus_service_hash    = filesha256("${path.module}/manifests/prometheus-service.yaml")
  prometheus_deployment_hash = filesha256("${path.module}/manifests/prometheus-deployment.yaml")
  

  # Combine all hashes into one string before hashing again
  prometheus_full_hash = sha256("${local.prometheus_config_hash}${local.prometheus_service_hash}${local.prometheus_deployment_hash}")
}

resource "kubectl_manifest" "prometheus_deployment" {
  yaml_body = templatefile("${path.module}/manifests/prometheus-deployment.yaml", {
    config_hash = local.prometheus_full_hash
  })

  depends_on = [
    kubectl_manifest.prometheus_config,
    kubectl_manifest.prometheus_service
  ]
}


# Deploy Node Exporter DaemonSet + Service
resource "kubectl_manifest" "node_exporter" {
  yaml_body = file("${path.module}/manifests/node-exporter.yaml")
  depends_on = [kubectl_manifest.monitoring_namespace]
}

# Deploy Node Exporter DaemonSet - Service


resource "kubectl_manifest" "node_exporter" {
  yaml_body = file("${path.module}/manifests/node-exporter-service.yaml")
  depends_on = [kubectl_manifest.monitoring_namespace]
}

# (Optional) Use SHA hash to force reapply if manifest changes
locals {
  node_exporter_hash = filesha256("${path.module}/manifests/node-exporter.yaml")
}

resource "null_resource" "trigger_node_exporter_restart" {
  triggers = {
    config_hash = local.node_exporter_hash
  }

  provisioner "local-exec" {
    command = "kubectl rollout restart daemonset/node-exporter -n monitoring || true"
  }
}
