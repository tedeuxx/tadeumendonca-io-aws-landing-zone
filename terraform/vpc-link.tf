# VPC Link for API Gateway to ALB direct integration
# Uses the new AWS feature for direct ALB connectivity (November 2025)

############################
# VPC LINKS
############################

# VPC Link per environment for direct ALB integration
# Note: Using aws_api_gateway_vpc_link for REST API (not aws_apigatewayv2_vpc_link which is for HTTP API)
resource "aws_api_gateway_vpc_link" "main" {
  for_each = toset(var.workload_environments)

  name        = "${replace(local.customer_workload_name, ".", "-")}-${each.value}-vpc-link"
  description = "VPC Link for direct ALB integration - ${each.value} environment"
  target_arns = [data.aws_lb.eks_alb[each.value].arn]

  tags = merge(local.common_tags, {
    Name        = "${local.customer_workload_name}-${each.value}-vpc-link"
    Environment = each.value
    Purpose     = "api-gateway-alb-integration"
  })

  depends_on = [kubernetes_ingress_v1.api]
}

############################
# DATA SOURCES FOR ALB
############################

# Data source to find ALB created by AWS Load Balancer Controller
# We'll use a more reliable approach by looking for ALBs with specific tags
data "aws_lb" "eks_alb" {
  for_each = toset(var.workload_environments)

  # Use name pattern to find the ALB created by the ingress
  name = "${replace(local.customer_workload_name, ".", "-")}-${each.value}-api-alb"

  depends_on = [kubernetes_ingress_v1.api]
}

############################
# KUBERNETES INGRESS RESOURCES
############################

# Kubernetes Ingress to create internal ALB
resource "kubernetes_ingress_v1" "api" {
  for_each = toset(var.workload_environments)

  metadata {
    name      = "api-ingress"
    namespace = each.value

    annotations = {
      "kubernetes.io/ingress.class"                    = "alb"
      "alb.ingress.kubernetes.io/scheme"               = "internal"
      "alb.ingress.kubernetes.io/target-type"          = "ip"
      "alb.ingress.kubernetes.io/certificate-arn"      = data.aws_acm_certificate.main.arn
      "alb.ingress.kubernetes.io/ssl-policy"           = "ELBSecurityPolicy-TLS-1-2-2017-01"
      "alb.ingress.kubernetes.io/listen-ports"         = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
      "alb.ingress.kubernetes.io/ssl-redirect"         = "443"
      "alb.ingress.kubernetes.io/healthcheck-path"     = "/health"
      "alb.ingress.kubernetes.io/healthcheck-protocol" = "HTTP"
      "alb.ingress.kubernetes.io/tags"                 = "Environment=${each.value},Purpose=api-alb"

      # Service tags for VPC Link discovery
      "service.beta.kubernetes.io/aws-load-balancer-name" = "${replace(local.customer_workload_name, ".", "-")}-${each.value}-api-alb"
    }
  }

  spec {
    rule {
      host = local.api_domain_names[each.value]

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "api-service"
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    tls {
      hosts = [local.api_domain_names[each.value]]
    }
  }

  depends_on = [
    module.eks_blueprints_addons,
    kubernetes_namespace.application
  ]
}

############################
# KUBERNETES SERVICES
############################

# Placeholder service for ALB target (will be replaced by actual app services)
resource "kubernetes_service" "api" {
  for_each = toset(var.workload_environments)

  metadata {
    name      = "api-service"
    namespace = each.value

    labels = {
      app = "api-service"
    }
  }

  spec {
    selector = {
      app = "api-service"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_namespace.application]
}

# Placeholder deployment for health checks (will be replaced by actual apps)
resource "kubernetes_deployment" "api" {
  for_each = toset(var.workload_environments)

  metadata {
    name      = "api-service"
    namespace = each.value

    labels = {
      app = "api-service"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "api-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "api-service"
        }
      }

      spec {
        container {
          name  = "api"
          image = "nginx:alpine"

          port {
            container_port = 8080
          }

          # Simple health check endpoint
          volume_mount {
            name       = "nginx-config"
            mount_path = "/etc/nginx/conf.d"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }

        volume {
          name = "nginx-config"

          config_map {
            name = kubernetes_config_map.nginx_config[each.value].metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.application]
}

# Nginx configuration for health check endpoint
resource "kubernetes_config_map" "nginx_config" {
  for_each = toset(var.workload_environments)

  metadata {
    name      = "nginx-config"
    namespace = each.value
  }

  data = {
    "default.conf" = <<-EOT
      server {
          listen 8080;
          server_name localhost;

          location / {
              return 200 '{"status":"ok","environment":"${each.value}","service":"api-placeholder"}';
              add_header Content-Type application/json;
          }

          location /health {
              return 200 '{"status":"healthy","environment":"${each.value}"}';
              add_header Content-Type application/json;
          }
      }
    EOT
  }

  depends_on = [kubernetes_namespace.application]
}