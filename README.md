# epicbook-infra

Infrastructure repository for EpicBook on Microsoft Azure (DMI Week 10, Assignment 4), owned by Oluwagbade Odimayo.

Terraform in `terraform/` provisions, in UK West, inside the existing resource group `rg-oluwagbade-epicbook`:

- a virtual network with separate frontend, backend and database subnets
- a frontend VM (Nginx) that accepts HTTP from the internet
- a backend VM (EpicBook on port 8080) whose application port is reachable only from the frontend subnet
- Azure Database for MySQL Flexible Server with private access (delegated subnet and private DNS zone)
- network security groups that restrict SSH to the pipeline agent and the administrator

State is stored remotely in Azure Storage (`stepicbooka70995/tfstate/epicbook.tfstate`) and is never committed.

`azure-pipelines.yml` runs on changes under `terraform/`: Validate, then Plan (the plan is saved as an artifact), then Apply, which waits for approval on the `epicbook-infra` environment and applies exactly the reviewed plan. It prints four non-sensitive outputs (`app_public_ip`, `backend_ansible_host`, `backend_private_ip`, `mysql_fqdn`), which are handed over manually to the `epicbook-app` repository.

Secrets are never stored here: Azure access uses a workload-identity-federated service connection (no client secret), the VM public key comes from a secure file, and the MySQL password comes from a secret pipeline variable.
