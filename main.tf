provider "google" {
  project = "vpc01-335820"
  region  = "us-central1"
  zone    = "us-central1-c"
}

resource "google_compute_shared_vpc_host_project" "host" {
  project = "vpc01-335820"
  
}

# A service project gains access to network resources provided by its
# associated host project.
resource "google_compute_shared_vpc_service_project" "service1" {
  host_project    = google_compute_shared_vpc_host_project.host.project
  service_project = "serviceproject01-336818"
  
}

resource "google_compute_shared_vpc_service_project" "service2" {
  host_project    = google_compute_shared_vpc_host_project.host.project
  service_project = "serviceproject02-336818"
  
}

locals {
  net_data_users = compact(concat(
    var.service_project_owners,
    ["serviceAccount:${var.service_project_number}@cloudservices.gserviceaccount.com"]
  ))
}

module "vpc" {
    source  = "terraform-google-modules/network/google"
    version = "~> 2.3"

    project_id   = var.host_project_id
    network_name = "example-vpc"
    shared_vpc_host = true
    routing_mode = "GLOBAL"

    subnets = [
        {
            subnet_name           = "subnet-01"
            subnet_ip             = "10.10.10.0/24"
            subnet_region         = "us-west1"
        },
        {
            subnet_name           = "subnet-02"
            subnet_ip             = "10.10.20.0/24"
            subnet_region         = "us-west1"
            subnet_private_access = "true"
            subnet_flow_logs      = "true"
            description           = "This subnet has a description"
        },
        {
            subnet_name               = "subnet-03"
            subnet_ip                 = "10.10.30.0/24"
            subnet_region             = "us-west1"
            subnet_flow_logs          = "true"
            subnet_flow_logs_interval = "INTERVAL_10_MIN"
            subnet_flow_logs_sampling = 0.7
            subnet_flow_logs_metadata = "INCLUDE_ALL_METADATA"
        }
    ]

    secondary_ranges = {
        subnet-01 = [
            {
                range_name    = "subnet-01-secondary-01"
                ip_cidr_range = "192.168.64.0/24"
            },
        ]

        subnet-02 = []
    }

    routes = [
        {
            name                   = "egress-internet"
            description            = "route through IGW to access internet"
            destination_range      = "0.0.0.0/0"
            tags                   = "egress-inet"
            next_hop_internet      = "true"
        },
        {
            name                   = "app-proxy"
            description            = "route through proxy to reach app"
            destination_range      = "10.50.10.0/24"
            tags                   = "app-proxy"
            next_hop_instance      = "app-proxy-instance"
            next_hop_instance_zone = "us-west1-a"
        },
    ]
}

# module "net-shared-vpc-access" {
#   source              = "terraform-google-modules/network/google//modules/fabric-net-svpc-access"
#   host_project_id     = var.host_project_id
#   service_project_num = 2
#   service_project_ids = [var.service_project_id1, var.service_project_id2]
#   host_subnets        = ["subnet-01", "subnet-02"]
#   host_subnet_regions = ["us-west1", "us-west1"]
#   host_subnet_users = {
#     data = join(",", local.net_data_users)
#   }
# }