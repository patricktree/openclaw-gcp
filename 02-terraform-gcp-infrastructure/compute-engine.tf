resource "google_compute_instance_template" "vm" {
  name_prefix  = "openclaw-"
  machine_type = "c4a-standard-2"

  lifecycle {
    create_before_destroy = true
  }

  scheduling {
    provisioning_model          = "SPOT"
    preemptible                 = true
    automatic_restart           = false
    instance_termination_action = "STOP"
  }

  disk {
    boot        = true
    auto_delete = true
    device_name = "persistent-disk-0"

    source_image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2404-lts-arm64"
    disk_size_gb = 30
    disk_type    = "hyperdisk-balanced"

    provisioned_iops       = 3000
    provisioned_throughput = 140
  }

  network_interface {
    network    = google_compute_network.vpc.name
    subnetwork = google_compute_subnetwork.subnet.name

    access_config {
      # Ephemeral public IP
    }
  }

  tags = ["openclaw-vm"]
}

resource "google_compute_instance_group_manager" "vm" {
  name               = "openclaw-mig"
  base_instance_name = "openclaw"
  zone               = local.zone
  target_size        = 1

  version {
    instance_template = google_compute_instance_template.vm.self_link
  }

  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_unavailable_fixed = 1
    replacement_method    = "RECREATE"
  }

  stateful_disk {
    device_name = "persistent-disk-0"
    delete_rule = "NEVER"
  }
}
