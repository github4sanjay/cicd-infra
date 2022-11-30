resource "aws_route53_zone" "example" {
  name = "example.com"
  comment = "example.com (production)"
  tags = {
    Environment = "production"
    Terraform   = "true"
    Label = "cicd"
  }
}

resource "aws_route53_record" "ci" {
  allow_overwrite = true
  name            = "ci.example.com"
  ttl             = 172800
  type            = "NS"
  zone_id         = aws_route53_zone.example.zone_id

  records = [
    aws_route53_zone.example.name_servers[0],
    aws_route53_zone.example.name_servers[1],
    aws_route53_zone.example.name_servers[2],
    aws_route53_zone.example.name_servers[3],
  ]

  tags = {
    Environment = "production"
    Terraform   = "true"
    Label = "cicd"
  }
}

resource "aws_route53_record" "cd" {
  allow_overwrite = true
  name            = "cd.example.com"
  ttl             = 172800
  type            = "NS"
  zone_id         = aws_route53_zone.example.zone_id

  records = [
    aws_route53_zone.example.name_servers[0],
    aws_route53_zone.example.name_servers[1],
    aws_route53_zone.example.name_servers[2],
    aws_route53_zone.example.name_servers[3],
  ]

  tags = {
    Environment = "production"
    Terraform   = "true"
    Label = "cicd"
  }
}

module "cert_manager_irsa" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "3.6.0"
  create_role                   = true
  role_name                     = "cicd-cluster-cert_manager-irsa"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.cert_manager_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:cert-manager:cert-manager"]

  tags = {
    Environment = "production"
    Terraform   = "true"
    Label = "cicd"
  }
}

resource "aws_iam_policy" "cert_manager_policy" {
  name        = "cicd-cluster-cert-manager-policy"
  path        = "/"
  description = "Policy, which allows CertManager to create Route53 records"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "route53:GetChange",
        "Resource" : "arn:aws:route53:::change/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ],
        "Resource" : "arn:aws:route53:::hostedzone/${aws_route53_zone.example.id}"
      },
    ]
  })

  tags = {
    Environment = "production"
    Terraform   = "true"
    Label = "cicd"
  }
}

resource "helm_release" "cert-manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io/jetstack"
  chart      = "cert-manager"
  version    = "v1.10.1"
  namespace = "cert-manager"
  create_namespace = true

  values = [
    templatefile("cert-manager-values.yml", {
      role_cert_manager_acme = module.cert_manager_irsa.this_iam_role_arn
    })
  ]
}

output "route53_zone_id" {
  value = aws_route53_zone.example.id
}

output "cert_manager_irsa_role_arn" {
  // to be used in ingress/cert-manager-values.yaml
  value = module.cert_manager_irsa.this_iam_role_arn
}