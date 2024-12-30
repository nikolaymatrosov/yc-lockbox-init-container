data "external" "git_hash" {
  program = [
    "git",
    "log",
    "--pretty={\"sha\":\"%H\"}",
    "-1",
    "HEAD"
  ]
}

locals {
  app_tag = "cr.yandex/${yandex_container_registry.demo-registry}/app:${data.external.git_hash.result.sha}"
  sidecar_tag = "cr.yandex/${yandex_container_registry.demo-registry}/sidecar:${data.external.git_hash.result.sha}"
}

resource "null_resource" "build_app" {
  triggers = {
    git_sha = data.external.git_hash.result.sha
  }

  provisioner "local-exec" {
    command = "cd .. && docker build --platform linux/amd64 -t ${local.app_tag} -f ./Dockerfile . && docker push ${local.app_tag}"
  }
}

resource "null_resource" "build_sidecar" {
  triggers = {
    git_sha = data.external.git_hash.result.sha
  }

  provisioner "local-exec" {
    command = "cd .. && docker build --platform linux/amd64 -t ${local.sidecar_tag} -f ./yc.Dockerfile . && docker push ${local.sidecar_tag}"
  }
}