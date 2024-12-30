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
  app_tag     = "cr.yandex/${yandex_container_registry.demo-registry.id}/app:${data.external.git_hash.result.sha}"
  sidecar_tag = "cr.yandex/${yandex_container_registry.demo-registry.id}/sidecar:${data.external.git_hash.result.sha}"
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

resource "yandex_iam_service_account" "vm_sa" {
  name      = "sa-ymq-creator"
  folder_id = var.folder_id
}

resource "yandex_resourcemanager_folder_iam_binding" "vm_sa" {
  for_each = toset([
    "lockbox.payloadViewer",
    "container-registry.images.puller",
  ])
  role      = each.value
  folder_id = var.folder_id
  members = [
    "serviceAccount:${yandex_iam_service_account.vm_sa.id}",
  ]
  sleep_after = 5
}

data "yandex_compute_image" "my_image" {
  family = "container-optimized-image"
}

resource "yandex_compute_instance" "default" {
  name        = "test"
  platform_id = "standard-v3"
  zone        = "ru-central1-d"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.my_image.id
    }
  }

  network_interface {
    subnet_id = data.yandex_vpc_subnet.default-d.id
    nat = true
  }

  metadata = {
    docker-compose = templatefile("docker-compose.yaml", {
      app_image     = local.app_tag,
      sidecar_image = local.sidecar_tag
      secret_id = yandex_lockbox_secret.app_config.id
    })
    user-data = templatefile("user-data.yaml", {
      SSH_PUBLIC_KEY = trimspace(file("~/.ssh/id_rsa.pub")),
    })
    enable-oslogin=false
  }

  service_account_id = yandex_iam_service_account.vm_sa.id
  depends_on = [
    null_resource.build_app,
    null_resource.build_sidecar,
    yandex_iam_service_account.vm_sa,
    yandex_resourcemanager_folder_iam_binding.vm_sa,
  ]
}

data "yandex_vpc_subnet" "default-d" {
  name = "default-ru-central1-d"
}