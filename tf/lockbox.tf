resource "yandex_lockbox_secret" "app_config" {
  name = "app-config"
}

resource "yandex_lockbox_secret_version" "my_version" {
  secret_id = yandex_lockbox_secret.app_config.id
  entries {
    key        = "config"
    text_value = file("config.json")
  }
}