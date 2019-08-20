data "aws_caller_identity" "current" {}

data "aws_eks_cluster_auth" "cluster_auth" {
  name = aws_eks_cluster.cluster.id
}

resource "kubernetes_config_map" "aws_auth_configmap" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<YAML
- rolearn: ${aws_iam_role.worker_node.arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
- rolearn: ${aws_iam_role.node_drainer.arn}
  username: lambda-node-drainer
YAML
  }

  lifecycle {
    ignore_changes = [data, metadata[0].annotations, metadata[0].labels]
  }
}

######
# Lambda Drainer role configuration
######
resource "kubernetes_cluster_role" "node_drainer" {
  metadata {
    name = "lambda-node-drainer"
  }

  rule {
    api_groups = ["", "extensions", "apps"]
    resources  = ["pods", "pods/eviction", "nodes", "statefulsets", "daemonsets", "replicasets"]
    verbs      = ["get", "list", "watch", "patch", "update", "create"]
  }
}

resource "kubernetes_cluster_role_binding" "node_drainer" {
  metadata {
    name = "lambda-node-drainer"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "lambda-node-drainer"
  }
  subject {
    kind      = "User"
    name      = "lambda-node-drainer"
    api_group = "rbac.authorization.k8s.io"
    namespace = "kube-system"
  }
}
