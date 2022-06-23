# Trust Anchor (Root CA Certificate) 

resource "tls_private_key" "trustanchor_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_self_signed_cert" "trustanchor_cert" {
  key_algorithm         = tls_private_key.trustanchor_key[0].algorithm
  private_key_pem       = tls_private_key.trustanchor_key[0].private_key_pem
  validity_period_hours = 87600
  is_ca_certificate     = true

  subject {
    common_name = "identity.linkerd.cluster.local"
  }

  allowed_uses = [
    "crl_signing",
    "cert_signing",
    "server_auth",
    "client_auth"
  ]
}

# Issuer Certificate

resource "tls_private_key" "issuer_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_cert_request" "issuer_req" {
  key_algorithm   = tls_private_key.issuer_key[0].algorithm
  private_key_pem = tls_private_key.issuer_key[0].private_key_pem

  subject {
    common_name = "identity.linkerd.cluster.local"
  }
}

resource "tls_locally_signed_cert" "issuer_cert" {
  cert_request_pem      = tls_cert_request.issuer_req[0].cert_request_pem
  ca_key_algorithm      = tls_private_key.trustanchor_key[0].algorithm
  ca_private_key_pem    = tls_private_key.trustanchor_key[0].private_key_pem
  ca_cert_pem           = tls_self_signed_cert.trustanchor_cert[0].cert_pem
  validity_period_hours = 8760
  early_renewal_hours   = var.linkerd_identity_validity_period_hours
  is_ca_certificate     = true


  allowed_uses = [
    "crl_signing",
    "cert_signing",
    "server_auth",
    "client_auth"
  ]
}

# LinkerD

resource "helm_release" "linkerd2" {
  name       = "linkerd"
  repository = "https://helm.linkerd.io/stable"
  chart      = "linkerd2"
  version    = var.linkerd_version
  values     = var.enable_ha ? [file("${path.module}/files/values-ha.yaml")] : []

  set {
    name  = "identityTrustAnchorsPEM"
    value = tls_self_signed_cert.trustanchor_cert[0].cert_pem
  }

  set {
    name  = "identity.issuer.crtExpiry"
    value = tls_locally_signed_cert.issuer_cert[0].validity_end_time
  }

  set {
    name  = "identity.issuer.tls.crtPEM"
    value = tls_locally_signed_cert.issuer_cert[0].cert_pem
  }

  set {
    name  = "identity.issuer.tls.keyPEM"
    value = tls_private_key.issuer_key[0].private_key_pem
  }

  depends_on = [
    var.nginx_elb_dns       # Adding this depend_on to prevent linkerd installation before core aws deployments are deployed successfully
  ]
}

# LinkerD Viz

resource "helm_release" "linkerd2-viz" {
  count      = var.include_viz == true ? 1 : 0
  chart      = "linkerd-viz"
  repository = "https://helm.linkerd.io/stable"
  version    = var.linkerd_version
  name       = "linkerd2-viz"
  values     = var.enable_ha ? [file("${path.module}/files/viz-values-ha.yaml")] : []

  depends_on = [
    helm_release.linkerd2
  ]
}

# LinkerD Jaeger

resource "helm_release" "linkerd2-jaeger" {
  count      = var.include_jaeger == true ? 1 : 0
  chart      = "linkerd-jaeger"
  repository = "https://helm.linkerd.io/stable"
  version    = var.linkerd_version
  name       = "linkerd2-jaeger"

  set {
    name  = "linkerdVersion"
    value = var.linkerd_version
  }

  depends_on = [
    helm_release.linkerd2
  ]
}
