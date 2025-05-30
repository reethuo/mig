provider "google" {
  project = "static-epigram-458808-h4"
  region  = "us-west1"
  zone    = "us-west1-c"
}

resource "google_compute_instance_template" "default" {
  name           = "template-mig"
  machine_type   = "e2-micro"
  region         = "us-west1"

  tags           = ["mig-instance"]

  disk {
    auto_delete  = true
    boot         = true
    source_image = "projects/centos-cloud/global/images/family/centos-stream-9"
  }

  network_interface {
    network = "default"
    access_config {}
  }



  metadata = {
    ssh-keys = "ansible:${var.public_key}"
  }
}

resource "google_compute_region_instance_group_manager" "mig" {
  name               = "mig-harness"
  base_instance_name = "mig-instance"
  region             = "us-west1"
  version {
    instance_template = google_compute_instance_template.default.self_link
  }

  target_size = 2

  auto_healing_policies {
    health_check      = google_compute_health_check.default.self_link
    initial_delay_sec = 60
  }
}

resource "google_compute_health_check" "default" {
  name               = "example-health-check"
  check_interval_sec = 10
  timeout_sec        = 5
  healthy_threshold  = 2
  unhealthy_threshold = 2

  tcp_health_check {
    port = 80
  }
}

resource "google_compute_region_autoscaler" "default" {
  name   = "example-autoscaler"
  region = "us-west1"
  target = google_compute_region_instance_group_manager.mig.self_link

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 2
    cooldown_period = 60

    cpu_utilization {
      target = 0.6
    }
  }
}


variable "public_key" {
  type = string
  default = ""
}

output "template_metadata" {
  value = google_compute_instance_template.default.metadata
}



