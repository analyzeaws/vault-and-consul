# ---------------------------------------------------------------------------------------------------------------------
#  CREATE A CA CERTIFICATE
# ---------------------------------------------------------------------------------------------------------------------

# (1) generate a random private key (P1)
resource "tls_private_key" "ca" {
  algorithm   = "${var.private_key_algorithm}"
  ecdsa_curve = "${var.private_key_ecdsa_curve}"
  rsa_bits    = "${var.private_key_rsa_bits}"
}

# ------------------------------------------------------
#Generate Self Signed Root Certificate Authority (CA)
#Uses the private key (1) generated above
# ------------------------------------------------------
resource "tls_self_signed_cert" "ca" {
  key_algorithm     = "${tls_private_key.ca.algorithm}"
  private_key_pem   = "${tls_private_key.ca.private_key_pem}"
  is_ca_certificate = true

  validity_period_hours = "${var.validity_period_hours}"
  allowed_uses          = ["${var.ca_allowed_uses}"]

  subject {
    common_name  = "${var.ca_common_name}"
    organization = "${var.organization_name}"
  }

  # Store the CA public key in a file.
  provisioner "local-exec" {
    command = "echo '${tls_self_signed_cert.ca.cert_pem}' > '${var.ca_public_key_file_path}' && chmod ${var.permissions} '${var.ca_public_key_file_path}' && chown ${var.owner} '${var.ca_public_key_file_path}'"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A TLS CERTIFICATE (for SERVER) SIGNED USING THE CA CERTIFICATE
# ---------------------------------------------------------------------------------------------------------------------

# Generate another private key (P2)
resource "tls_private_key" "cert" {
  algorithm   = "${var.private_key_algorithm}"
  ecdsa_curve = "${var.private_key_ecdsa_curve}"
  rsa_bits    = "${var.private_key_rsa_bits}"

  # Store the certificate's private key in a file.
  provisioner "local-exec" {
    command = "echo '${tls_private_key.cert.private_key_pem}' > '${var.private_key_file_path}' && chmod ${var.permissions} '${var.private_key_file_path}' && chown ${var.owner} '${var.private_key_file_path}'"
  }
}

# using above private key (P2), create the cert signing request (R)
resource "tls_cert_request" "cert" {
  key_algorithm   = "${tls_private_key.cert.algorithm}"
  private_key_pem = "${tls_private_key.cert.private_key_pem}"

  dns_names    = ["${var.dns_names}"]
  ip_addresses = ["${var.ip_addresses}"]

  subject {
    common_name  = "${var.common_name}"
    organization = "${var.organization_name}"
  }
}

# sign above cert request (R), using local root cert authority (A), created above.
resource "tls_locally_signed_cert" "cert" {
  cert_request_pem = "${tls_cert_request.cert.cert_request_pem}"

  ca_key_algorithm   = "${tls_private_key.ca.algorithm}"
  ca_private_key_pem = "${tls_private_key.ca.private_key_pem}"
  ca_cert_pem        = "${tls_self_signed_cert.ca.cert_pem}"

  validity_period_hours = "${var.validity_period_hours}"
  allowed_uses          = ["${var.allowed_uses}"]

  # Store the certificate's public key in a file.
  provisioner "local-exec" {
    command = "echo '${tls_locally_signed_cert.cert.cert_pem}' > '${var.public_key_file_path}' && chmod ${var.permissions} '${var.public_key_file_path}' && chown ${var.owner} '${var.public_key_file_path}'"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A TLS CERTIFICATE (for CLIENT) SIGNED USING THE SAME CA CERTIFICATE
# ---------------------------------------------------------------------------------------------------------------------

# Generate another private key (C1)
resource "tls_private_key" "client_cert" {
  algorithm   = "${var.private_key_algorithm}"
  ecdsa_curve = "${var.private_key_ecdsa_curve}"
  rsa_bits    = "${var.private_key_rsa_bits}"

  # Store the client certificate's private key in a file.
  provisioner "local-exec" {
    command = "echo '${tls_private_key.client_cert.private_key_pem}' > '${var.client_private_key_file_path}' && chmod ${var.permissions} '${var.client_private_key_file_path}' && chown ${var.owner} '${var.client_private_key_file_path}'"
  }
}

# using above private key (C1), create the cert signing request (client_R)
resource "tls_cert_request" "client_cert" {
  key_algorithm   = "${tls_private_key.client_cert.algorithm}"
  private_key_pem = "${tls_private_key.client_cert.private_key_pem}"

  dns_names    = ["${var.client_dns_names}"]
  ip_addresses = ["${var.client_ip_addresses}"]

  subject {
    common_name  = "${var.client_common_name}"
    organization = "${var.client_organization_name}"
  }
}

# sign above cert request (Client_R), using local root cert authority (A), created above.
resource "tls_locally_signed_cert" "client_cert" {
  cert_request_pem = "${tls_cert_request.client_cert.cert_request_pem}"

  ca_key_algorithm   = "${tls_private_key.ca.algorithm}"
  ca_private_key_pem = "${tls_private_key.ca.private_key_pem}"
  ca_cert_pem        = "${tls_self_signed_cert.ca.cert_pem}"

  validity_period_hours = "${var.validity_period_hours}"
  allowed_uses          = ["${var.client_allowed_uses}"]

  # Store the certificate's public key in a file.
  provisioner "local-exec" {
    command = "echo '${tls_locally_signed_cert.client_cert.cert_pem}' > '${var.client_public_key_file_path}' && chmod ${var.permissions} '${var.client_public_key_file_path}' && chown ${var.owner} '${var.client_public_key_file_path}'"
  }
}
