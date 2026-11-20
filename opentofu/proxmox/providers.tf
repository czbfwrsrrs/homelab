terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.123.1"
    }
  }
}

provider "proxmox" {
    endpoint = "https://192.168.53:8006/"
    insecure = true
    
}