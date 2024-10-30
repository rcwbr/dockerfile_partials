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
  // Replace any non-alphanumeric, underscore, or dot characters in the ref with dashes
  default = regex_replace(GITHUB_REF_NAME, "[^a-zA-Z0-9_.]", "-")
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

target "default" {
  dockerfile = "cwd://Dockerfile"
  context = "."
  cache-from = [
    // Always pull cache from main
    "type=registry,ref=${IMAGE_REF}-cache:main",
    "type=registry,ref=${IMAGE_REF}-cache:${VERSION}"
  ]
  cache-to = [
    "type=registry,ref=${IMAGE_REF}-cache:${VERSION}"
  ]
  output = [
    "type=docker,name=${IMAGE_NAME}",
    // If running for an unprotected ref (e.g. PRs), append the commit SHA
    (
      "${GITHUB_REF_PROTECTED}" == "true"
      ? "type=registry,name=${IMAGE_REF}:${VERSION}"
      : "type=registry,name=${IMAGE_REF}:${VERSION}-${GITHUB_SHA}"
    )
  ]
}
