variable "USER" {
  default = "root"
}
variable "UID" {
  default = 0
}
variable "GID" {
  // Use the user id as group id unless set
  default = "${UID}"
}

target "useradd" {
  dockerfile = "useradd/Dockerfile"
  args = {
    USER = "${USER}"
    USER_UID = "${UID}"
    USER_GID = "${GID}"
  }
}
