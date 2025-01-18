// This image is used only to analyze image space efficiency in the CI pipeline

variable "devcontainer_layers" {
  default = [
    "docker-client",
    "useradd",
    "pre-commit"
  ]
}

target "docker-client" {
  contexts = {
    base_context = "docker-image://python:3.12.4"
  }
}
