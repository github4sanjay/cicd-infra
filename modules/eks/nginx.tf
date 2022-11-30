resource "helm_release" "ingress-nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.4.0"
  namespace = "ingress"
  create_namespace = true

  values = [
    file("nginx-ingress-values.yaml")
  ]
}