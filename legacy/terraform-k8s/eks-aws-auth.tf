resource "kubernetes_config_map" "aws_auth_configmap" {
  count = var.aws_partition == "public" ? 1 : 0

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<YAML
- rolearn: arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-worker-node
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
- rolearn: arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Okta_SuperAdmin
  username: Okta_SuperAdmin
  groups:
    - system:masters
- rolearn: arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Okta_Developer
  username: Okta_Developer
- rolearn: arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-node-drainer-role
  username: lambda-node-drainer
YAML
  }

  lifecycle {
    ignore_changes = [data, metadata[0].annotations, metadata[0].labels]
  }
}

resource "kubernetes_config_map" "aws_auth_configmap_china" {
  count = var.aws_partition == "china" ? 1 : 0

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<YAML
- rolearn: arn:aws-cn:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-worker-node
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
- rolearn: arn:aws-cn:iam::${data.aws_caller_identity.current.account_id}:role/Okta_SuperAdmin
  username: Okta_SuperAdmin
  groups:
    - system:masters
- rolearn: arn:aws-cn:iam::${data.aws_caller_identity.current.account_id}:role/Okta_Developer
  username: Okta_Developer
- rolearn: arn:aws-cn:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-node-drainer-role
  username: lambda-node-drainer
YAML
  }

  lifecycle {
    ignore_changes = [data, metadata[0].annotations, metadata[0].labels]
  }
}

######
# Lambda Drainer cluster role configuration
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

######
# Okta_Developer cluster role configuration
######

resource "kubernetes_cluster_role" "okta_developer_clusterrole" {
  metadata {
    name = "okta-developer-cluster-role"
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps", "endpoints", "events", "limitranges", "namespaces", "pods", "replicationcontrollers", "resourcequotas", "serviceaccounts", "services", "limitranges"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["daemonsets", "deployments", "replicasets", "statefulsets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["controllerrevisions", "daemonsets", "deployments", "replicasets", "statefulsets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["autoscaling"]
    resources  = ["horizontalpodautoscalers"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["daemonsets", "deployments", "ingresses", "networkpolicies", "replicasets", "replicationcontrollers", "statefulsets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["cronjobs", "jobs"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["policy"]
    resources  = ["poddisruptionbudgets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses", "networkpolicies"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["metrics.k8s.io"]
    resources  = ["pods", "nodes"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "okta_developer_clusterrole_binding" {
  metadata {
    name = "okta-developer-cluster-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.okta_developer_clusterrole.id
  }
  subject {
    kind      = "User"
    name      = "Okta_Developer"
    api_group = "rbac.authorization.k8s.io"
    namespace = "kube-system"
  }
}
