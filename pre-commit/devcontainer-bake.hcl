variable "USER" {
  default = "root"
}
variable "DEVCONTAINER_REGISTRY" {
  default = ""
}
variable "DEVCONTAINER_IMAGE" {
  default = ""
}
variable "GIT_BRANCH_SANITIZED" {
  default = ""
}
variable "PRE_COMMIT_TOOL_IMAGE" {
  default = "type=registry,name=${DEVCONTAINER_REGISTRY}/${DEVCONTAINER_IMAGE}-pre-commit:${GIT_BRANCH_SANITIZED}"
}

target "pre-commit-base" {
  dockerfile-inline = "FROM base_context"
}

target "pre-commit-tool-image" {
  dockerfile = "pre-commit/Dockerfile"
  contexts = {
    local_context = BAKE_CMD_CONTEXT
    base_context  = "target:pre-commit-base"
  }
  output = ["${PRE_COMMIT_TOOL_IMAGE}"]
}

target "pre-commit" {
  dockerfile = "pre-commit/caller.Dockerfile"
  contexts = {
    local_context  = BAKE_CMD_CONTEXT
    common_context = "common"
    base_context   = "target:pre-commit-base"
    // Tool context is unused; referenced only to establish it as a dep
    tool_context   = "target:pre-commit-tool-image"
  }
  args = {
    USER = "${USER}"
    DEVCONTAINER_PRE_COMMIT_IMAGE = "${PRE_COMMIT_TOOL_IMAGE}"
  }
}
