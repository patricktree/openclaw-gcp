resource "google_compute_instance" "vm" {
  name         = "clawdbot"
  machine_type = "c4a-standard-1"

  allow_stopping_for_update = true

  scheduling {
    provisioning_model          = "SPOT"
    preemptible                 = true
    automatic_restart           = false
    instance_termination_action = "STOP"
  }

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2510-arm64"
      size  = 30
      type  = "hyperdisk-balanced"

      provisioned_iops       = 3000
      provisioned_throughput = 140
    }
  }

  network_interface {
    network    = google_compute_network.vpc.name
    subnetwork = google_compute_subnetwork.subnet.name

    access_config {
      # Ephemeral public IP
    }
  }

  tags = ["clawdbot-vm"]
}

resource "google_compute_firewall" "ssh" {
  name    = "clawdbot-allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["clawdbot-vm"]
}
