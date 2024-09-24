variable "HOSTNAME" {
  default = ""
}
// HOST for OS compatibility
variable "HOST" {
  default = "${HOSTNAME}"
}

variable "GITHUB_REF_PROTECTED" {
  default = "false"
}
variable "GITHUB_SHA" {
  // If not running in CI, assume local
  default = "local"
}
variable "GITHUB_REF_NAME" {
  // If not executing in GitHub Actions, use a local, host-specific ref
  default = "local-${HOST}"
}
variable "VERSION" {
  // Default the version to the ref from CI, sanitized
  // Replace any non-alphanumeric (or underscore) characters in the ref with dashes
  default = regex_replace(GITHUB_REF_NAME, "[^a-zA-Z0-9_]", "-")
}

variable "IMAGE_NAME" {
  default = ""
}

variable "REGISTRY" {
  default = "ghcr.io/"
}
variable "IMAGE_REF" {
  default = "${REGISTRY}${IMAGE_NAME}"
}

variable "VARIANTS" {
  default = [
    ""
  ]
}

target "image" {
  matrix = {
    variant = VARIANTS
  }
  name = "${IMAGE_NAME}${variant}"
  dockerfile = "${variant}/Dockerfile"
  cache-from = [
    // Always pull cache from main
    "type=registry,ref=${IMAGE_REF}${variant}-cache:main",
    "type=registry,ref=${IMAGE_REF}${variant}-cache:${VERSION}"
  ]
  cache-to = [
    "type=registry,ref=${IMAGE_REF}${variant}-cache:${VERSION}"
  ]
  output = [
    "type=docker,name=${IMAGE_NAME}${variant}",
    // If running for an unprotected ref (e.g. PRs), append the commit SHA
    (
      "${GITHUB_REF_PROTECTED}" == "true"
      ? "type=registry,name=${IMAGE_REF}${variant}:${VERSION}"
      : "type=registry,name=${IMAGE_REF}${variant}:${VERSION}-${GITHUB_SHA}"
    )
  ]
}

group "default" {
  targets = [
    for variant in VARIANTS: "${IMAGE_REF}${variant}"
  ]
}
