variable "DOCKER_GID" {
  default = "800"
}
// Set EXTRA_GID_ARGS to include a Docker group in case the useradd partial will be included
variable "EXTRA_GID_ARGS" {
  default = "--gid ${DOCKER_GID}"
}

target "docker-client" {
  dockerfile = "docker-client/Dockerfile"
  contexts = {
    docker_image = "docker-image://docker:27.3.1-cli"
  }
}
