provider "google" {
  alias = "impersonate"

}

#############################Base Project and Resource Creation#######################
resource "random_id" "id" {
  byte_length = 4
  prefix      = "host-1"
}

resource "random_id" "id1" {
  byte_length = 4
  prefix      = "service-1"
}

resource "random_id" "id2" {
  byte_length = 4
  prefix      = "service-2"
}

resource "google_project" "project" {
  name            = "host-1"
  project_id      = random_id.id.hex
  billing_account = "01DEF7-F9833E-AD765A"
  org_id          = "42165644541"
}

resource "google_project" "project1" {
  name            = "service-1"
  project_id      = random_id.id1.hex
  billing_account = "01DEF7-F9833E-AD765A"
  org_id          = "42165644541"
}

resource "google_project" "project2" {
  name            = "service-2"
  project_id      = random_id.id2.hex
  billing_account = "01DEF7-F9833E-AD765A"
  org_id          = "42165644541"
}

output "project_id" {
  value = google_project.project.project_id
}

output "project_id1" {
  value = google_project.project1.project_id
}

output "project_id2" {
  value = google_project.project2.project_id
}

resource "google_project_service" "project" {
  project = google_project.project.project_id
  service = "iam.googleapis.com"

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_dependent_services = true
}

 resource "google_compute_shared_vpc_host_project" "host" {
   project = google_project.project.project_id
  
}






locals {
  net_data_users = compact(concat(
    var.service_project_owners,
    ["serviceAccount:${var.service_project_number}@cloudservices.gserviceaccount.com"]
  ))
}

#############################SVPC#######################
module "vpc" {
    source  = "terraform-google-modules/network/google"
    version = "~> 2.3"

    project_id   = google_project.project.project_id
    network_name = "test-vpc"
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
        }
    ]
}

  
#############################Service Project Attachment#######################

module "net-shared-vpc-access" {
    source              = "terraform-google-modules/network/google//modules/fabric-net-svpc-access"
    host_project_id     = google_project.project.project_id
    service_project_num = 2
    service_project_ids = [google_project.project1.project_id, google_project.project2.project_id]
    host_subnets        = ["subnet-01", "subnet-02"]
    host_subnet_regions = ["us-west1", "us-west1"]
    host_subnet_users   = {
    subnet-01 = "user:siddharth.mehra@badal.io"
    subnet-02 = "user:siddharth.mehra@badal.io"
  }
  host_service_agent_role = true
  host_service_agent_users = [
    "user:siddharth.mehra@badal.io"
  ]
}

#############################SGCS Buckets#######################

module "gcs_buckets" {
  source  = "terraform-google-modules/cloud-storage/google"
  version = "~> 2.2"
  project_id  = google_project.project2.project_id
  names = ["test-Bucket02"]
  prefix = "test"
  set_admin_roles = true
  admins = ["user:siddharth.mehra@badal.io"]
  versioning = {
    first = true
  }
  bucket_admins = {
    second = "user:siddharth.mehra@badal.io"
  }
}

resource "google_storage_bucket" "auto-expire" {
  name          = "test-bucket04"
  location      = "US"
  force_destroy = true
  uniform_bucket_level_access = true
  project = google_project.project1.project_id

  lifecycle_rule {
    condition {
      age = 3
    }
    action {
      type = "Delete"
    }
  }
}

#############################VM Instance#######################
resource "google_compute_instance" "default" {
  name         = "test"
  machine_type = "e2-medium"
  zone         = "us-central1-a"
  project = google_project.project1.project_id

  tags = ["foo", "bar"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  

  network_interface {
    network = "default"

    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    foo = "bar"
  }

  metadata_startup_script = "echo hi > /test.txt"

   service_account {
     # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
     email  = "tst02-768@service-11ea10474.iam.gserviceaccount.com"
     scopes = ["cloud-platform"]
   }
}


#############################Service Account Impersonation#######################
data "google_service_account_access_token" "default" {
  provider               = google.impersonate
  target_service_account = "tst01-845@host-1a73e38fb.iam.gserviceaccount.com"
  scopes                 = ["userinfo-email", "cloud-platform"]
  lifetime               = "600s"
}
/******************************************
  Provider credential configuration
 *****************************************/
provider "google" {
  access_token = data.google_service_account_access_token.default.access_token
}

provider "google-beta" {
  access_token = data.google_service_account_access_token.default.access_token
}



#############################Service Perimeter(VPCSC)#######################

module "regular_service_perimeter_1" {
  source         = "terraform-google-modules/vpc-service-controls/google//modules/regular_service_perimeter"
  policy         = "989883403927"
  perimeter_name = "regular_perimeter_1"
  description    = "Some description"
  resources      = ["751798861190"]

  restricted_services = ["bigquery.googleapis.com", "storage.googleapis.com"]

  ingress_policies = [{
      "from" = {
        "sources" = {
          resources = [
            "projects/751798861190"
          ],
        },
        "identity_type" = ""
        "identities"    = ["user:siddharth.mehra@badal.io"]
      }
      "to" = {
        "operations" = {
          "bigquery.googleapis.com" = {
            "methods" = [
              "BigQueryStorage.ReadRows",
              "TableService.ListTables"
            ],
            "permissions" = [
              "bigquery.jobs.get"
            ]
          }
          "storage.googleapis.com" = {
            "methods" = [
              "google.storage.objects.create"
            ]
          }
        }
      }
    },
  ]
  egress_policies = [{
       "from" = {
        "identity_type" = ""
        "identities"    = ["user:siddharth.mehra@badal.io", "serviceAccount:tst02-768@service-11ea10474.iam.gserviceaccount.com"]
      },
       "to" = {
        "resources" = ["projects/1075536143113"]
        "operations" = {
          "storage.googleapis.com" = {
            "methods" = ["*"]
            
          }
        }
      }
    },
  ]

  shared_resources = {
    all = ["751798861190"]
  }
}

#"projects/1075536143113"