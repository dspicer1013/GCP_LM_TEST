provider "google" {
  version = "3.5.0"
  credentials = file("~/.ssh/rational-world-316120-265d70a48139.json")
  project = "rational-world-316120"
  }
  #################################   VPC's   ##################################
resource "google_compute_network" "gcp-vpc" {
  name = "gcp-vpc"
  auto_create_subnetworks = false
  routing_mode = "GLOBAL"
  }

  resource "google_compute_subnetwork" "us-cen1" {
  name = "us-central1"
  ip_cidr_range = "192.168.100.0/24"
  region        = "us-central1"
  private_ip_google_access = true
  network       = google_compute_network.gcp-vpc.id
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}
resource "google_compute_subnetwork" "us-wes1" {
  name = "us-west1"
  ip_cidr_range = "192.168.200.0/24"
  region        = "us-west1"
  private_ip_google_access = true
  network       = google_compute_network.gcp-vpc.id
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}
resource "google_compute_address" "static-1" {
  name = "ipv4-address"
  region        = "us-central1"
}
resource "google_compute_instance" "vm_cen1_a" {
  zone         = "us-central1-a"
  name         = "vm-a"
  machine_type = "f1-micro"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
  network_interface {
    network = google_compute_network.gcp-vpc.id
    subnetwork = google_compute_subnetwork.us-cen1.name
    network_ip = "192.168.100.50"
    access_config {
      nat_ip = google_compute_address.static-1.address
    }
  }
  metadata = {
   ssh-keys = "dspicer:${file("~/.ssh/gcp-dspicer.pub")}"
 }
}
resource "google_compute_firewall" "project-firewall-allow-ssh" {
  name    = "ssh-allow-something"
  network = google_compute_network.gcp-vpc.id
  allow {
    protocol = "tcp" #tcp, udp, icmp...
    ports    = [22] #22, 80...
  }
source_ranges = ["74.80.18.254/32", "10.143.0.0/16", "10.243.0.0/16"] #according to cidr notation
}
resource "google_compute_firewall" "project-firewall-allow-icmp" {
  name    = "icmp-allow-something"
  network = google_compute_network.gcp-vpc.id
  allow {
    protocol = "icmp"
    }
source_ranges = ["74.80.18.254/32", "10.143.0.0/16", "10.243.0.0/16"] #according to cidr notation
}



output "VM_Cen1_A_External_Address" {
  description = "private IP address assigned to Test 1 in VPC1"
  value       = google_compute_address.static-1.address
}
