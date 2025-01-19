variable "USER" {
  default = "root"
}

target "pre-commit" {
  dockerfile = "pre-commit/Dockerfile"
  contexts = {
    local_context  = BAKE_CMD_CONTEXT
    common_context = "common"
  }
  args = {
    USER = "${USER}"
  }
}
