resource "yandex_container_registry" "demo-registry" {
  name      = "lockbox-demo"
  folder_id = var.folder_id
}

resource "yandex_container_repository" "demo-repo" {
  name = "${yandex_container_registry.demo-registry.id}/lockbox-demo"
}
