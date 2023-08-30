locals {
  k8s-ns = "flux"
  flux_additional_arguments = [
    for key in keys(var.flux_args_extra) :
    "--${key}=${var.flux_args_extra[key]}"
  ]
}

resource "tls_private_key" "flux" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

#####
# Flux
#####

resource "kubernetes_namespace" "flux" {
  metadata {
    name = local.k8s-ns
  }

  depends_on = [kubernetes_namespace.flux]
}

resource "kubernetes_service_account" "flux" {
  metadata {
    name      = "flux"
    namespace = local.k8s-ns

    labels = {
      name = "flux"
    }
  }

  automount_service_account_token = true

  depends_on = [kubernetes_namespace.flux]
}

resource "kubernetes_cluster_role" "flux" {
  metadata {
    name = "flux"

    labels = {
      name = "flux"
    }
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    non_resource_urls = ["*"]
    verbs             = ["*"]
  }

  depends_on = [kubernetes_namespace.flux]
}

resource "kubernetes_cluster_role_binding" "flux" {
  metadata {
    name = "flux"

    labels = {
      name = "flux"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "flux"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "flux"
    namespace = local.k8s-ns
    api_group = ""
  }

  depends_on = [
    kubernetes_namespace.flux,
    kubernetes_cluster_role.flux,
    kubernetes_service_account.flux,
  ]
}

resource "kubernetes_config_map" "root_sshdir" {
  metadata {
    name      = "flux-root-sshdir"
    namespace = local.k8s-ns

    labels = {
      name = "flux"
    }
  }
  data = {
    "known_hosts" = join("\n", var.flux_known_hosts)
  }
}

resource "kubernetes_deployment" "flux" {
  metadata {
    name      = "flux"
    namespace = local.k8s-ns
  }

  spec {
    selector {
      match_labels = {
        name = "flux"
      }
    }

    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app  = "flux"
          name = "flux"
        }
      }

      spec {
        service_account_name = "flux"

        # See the following GH issue for why we have to do this manually
        # https://github.com/terraform-providers/terraform-provider-kubernetes/issues/38
        volume {
          name = kubernetes_service_account.flux.default_secret_name

          secret {
            secret_name = kubernetes_service_account.flux.default_secret_name
          }
        }

        volume {
          name = "git-key"

          secret {
            secret_name  = "flux-git-deploy"
            default_mode = "0400"
          }
        }

        volume {
          name = "git-keygen"

          empty_dir {
            medium = "Memory"
          }
        }

        volume {
          name = "root-sshdir"
          config_map {
            name         = kubernetes_config_map.root_sshdir.metadata[0].name
            default_mode = "0600"
          }
        }

        container {
          name  = "flux"
          image = "docker.io/umotif/flux:${var.flux_docker_tag}"

          # See the following GH issue for why we have to do this manually
          # https://github.com/terraform-providers/terraform-provider-kubernetes/issues/38
          volume_mount {
            mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
            name       = kubernetes_service_account.flux.default_secret_name
            read_only  = true
          }

          volume_mount {
            name       = "git-key"
            mount_path = "/etc/fluxd/ssh"
            read_only  = true
          }

          volume_mount {
            name       = "git-keygen"
            mount_path = "/var/fluxd/keygen"
          }

          volume_mount {
            name       = "root-sshdir"
            mount_path = "/root/.ssh"
            read_only  = true
          }

          args = concat(
            [
              "--memcached-service=memcached",
              "--ssh-keygen-dir=/var/fluxd/keygen",
              "--git-url=${var.git_url}",
              "--git-path=${var.git_path}",
              "--git-branch=${var.git_repository_branch}",
              "--git-poll-interval=180s",
              "--automation-interval=180s",
              "--sync-garbage-collection"
            ],
            local.flux_additional_arguments
          )
        }
      }
    }
  }
  depends_on = [
    kubernetes_cluster_role_binding.flux,
    kubernetes_secret.flux-git-deploy,
  ]
}

resource "kubernetes_secret" "flux-git-deploy" {
  metadata {
    name      = "flux-git-deploy"
    namespace = local.k8s-ns
  }

  type = "Opaque"

  data = {
    identity = tls_private_key.flux.private_key_pem
  }

  depends_on = [kubernetes_namespace.flux]
}

#####
# Memcache
#####

resource "kubernetes_deployment" "memcached" {
  metadata {
    name      = "memcached"
    namespace = local.k8s-ns
  }

  spec {
    selector {
      match_labels = {
        name = "memcached"
      }
    }

    template {
      metadata {
        labels = {
          name = "memcached"
        }
      }

      spec {
        container {
          name  = "memcached"
          image = "memcached:1.6.0"

          port {
            name           = "clients"
            container_port = 11211
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.flux]
}

resource "kubernetes_service" "memcached" {
  metadata {
    name      = "memcached"
    namespace = local.k8s-ns
  }

  spec {
    port {
      name = "memcached"
      port = 11211
    }

    selector = {
      name = "memcached"
    }
  }

  depends_on = [kubernetes_namespace.flux]
}
