resource "kubectl_manifest" "cert_cluster_issuer" {
  yaml_body = <<-EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: sanjaykumarsingh9201@gmail.com
    privateKeySecretRef:
      name: letsencrypt
    server: https://acme-v02.api.letsencrypt.org/directory
    solvers:
      - dns01:
          route53:
            region: ap-southeast-1
            hostedZoneID: ${aws_route53_zone.example.id}
EOF
}
