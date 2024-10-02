# Terraform and Ansible Automation for OpenVPN Deployment on OpenStack

## Introduction

This project automates the deployment of an OpenVPN server on an OpenStack cloud environment using Terraform for infrastructure provisioning and Ansible for configuration management. Docker and Docker Compose are utilized to create a consistent development and deployment environment.

---

## Table of Contents

- [Terraform and Ansible Automation for OpenVPN Deployment on OpenStack](#terraform-and-ansible-automation-for-openvpn-deployment-on-openstack)
  - [Introduction](#introduction)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Getting Started](#getting-started)
    - [Building and Running the Docker Container](#building-and-running-the-docker-container)
      - [Docker Compose Configuration](#docker-compose-configuration)
      - [Dockerfile Configuration](#dockerfile-configuration)
      - [Build and Run the Container](#build-and-run-the-container)
      - [Run the Container Without Rebuilding](#run-the-container-without-rebuilding)
      - [Run the Container in Detached Mode](#run-the-container-in-detached-mode)
    - [Connecting to the Docker Container](#connecting-to-the-docker-container)
  - [Terraform Configuration](#terraform-configuration)
    - [Configuring the Terraform Backend](#configuring-the-terraform-backend)
    - [Initializing Terraform](#initializing-terraform)
    - [Applying the Terraform Configuration](#applying-the-terraform-configuration)
      - [Set OpenStack Environment Variables](#set-openstack-environment-variables)
      - [Apply the Configuration](#apply-the-configuration)
  - [Ansible Configuration](#ansible-configuration)
    - [Activating the Ansible Virtual Environment](#activating-the-ansible-virtual-environment)
    - [Ansible Directory Structure](#ansible-directory-structure)
    - [Defining CA Variables](#defining-ca-variables)
    - [Pinging the Deployed Machines](#pinging-the-deployed-machines)
      - [Configure the Inventory](#configure-the-inventory)
      - [Ping the Hosts](#ping-the-hosts)
    - [Running the Ansible Playbook](#running-the-ansible-playbook)
      - [Navigate to the Ansible Directory](#navigate-to-the-ansible-directory)
      - [Review the Playbook](#review-the-playbook)
      - [Execute the Playbook](#execute-the-playbook)
      - [Run an Ad-Hoc Command (Optional)](#run-an-ad-hoc-command-optional)
  - [Accessing the OpenVPN Server](#accessing-the-openvpn-server)
    - [Connecting via SSH](#connecting-via-ssh)
      - [From Local Machine](#from-local-machine)
      - [From Docker Container](#from-docker-container)
    - [Verifying OpenVPN Status](#verifying-openvpn-status)
  - [Appendix](#appendix)
    - [Explanation of `netstat` Options](#explanation-of-netstat-options)
  - [Notes](#notes)
  - [Contributing](#contributing)
  - [License](#license)

---

## Prerequisites

- **Docker** and **Docker Compose** installed on your local machine.
- Access credentials for an **OpenStack** environment.
- An **SSH key** for accessing OpenStack instances.
- (Optional) **Terraform** and **Ansible** installed locally, if not using the Docker container.

---

## Getting Started

### Building and Running the Docker Container

#### Docker Compose Configuration

Below is the `docker-compose.yml` file used to configure the Docker container. This file defines the services, volumes, environment variables, and other settings needed to build and run the container.

```yaml
services:
  terraform-ansible:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: terraform-ansible
    volumes:
      - ./logs:/var/log/install_logs  # Mount for logs
      - ../terraform:/usr/src/terraform  # Mount Terraform directory
      - ../ansible:/usr/src/ansible  # Mount Ansible directory
      - /path/to/your/.ssh:/root/.ssh_host  # Mount directory containing your SSH key
    environment:
      ANSIBLE_PRIVATE_KEY_FILE: /root/.ssh/your_private_key  # Environment variable for SSH key
    healthcheck:
      test: ["CMD-SHELL", "tail -n 1 /var/log/install_logs/log_all_installs.json"]
      interval: 30s
      timeout: 10s
      retries: 3
    restart: unless-stopped
    working_dir: /usr/src/terraform  # Set working directory for Terraform
    entrypoint: ["/bin/sh", "-c", "cp /root/.ssh_host/your_private_key /root/.ssh/your_private_key && chmod 600 /root/.ssh/your_private_key && tail -f /var/log/install_logs/log_all_installs.json"]
```

**Explanation:**

- **Volumes:**
  - `./logs:/var/log/install_logs`: Mounts the local `logs` directory to the container for logging.
  - `../terraform:/usr/src/terraform`: Mounts the Terraform configuration directory.
  - `../ansible:/usr/src/ansible`: Mounts the Ansible configuration directory.
  - `/path/to/your/.ssh:/root/.ssh_host`: Mounts your local SSH directory containing the private key required for accessing the OpenStack instances.

- **Environment Variables:**
  - `ANSIBLE_PRIVATE_KEY_FILE`: Points to the SSH private key inside the container.

- **Entrypoint:**
  - Copies the SSH private key from the mounted directory to the container's SSH directory.
  - Sets appropriate permissions for the SSH key.
  - Keeps the container running by tailing the log file.

#### Dockerfile Configuration

Below is the `Dockerfile` used to build the Docker image. It sets up an Alpine-based environment with Terraform and Ansible installed inside a Python virtual environment.

```dockerfile
# Use Alpine Linux for a lightweight and secure environment
FROM alpine:latest

# Update existing packages and install necessary dependencies
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
        bash \
        curl \
        gnupg \
        jq \
        openssh \
        openssl \
        python3 \
        py3-pip \
        python3-dev \
        build-base \
        libffi-dev \
        wget \
        unzip

# Configure a Python virtual environment and install Ansible
RUN python3 -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    pip install --upgrade pip && \
    pip install ansible && \
    deactivate

# Download and install the latest version of Terraform
RUN latest_terraform=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r .current_version) && \
    wget https://releases.hashicorp.com/terraform/${latest_terraform}/terraform_${latest_terraform}_linux_amd64.zip && \
    unzip terraform_${latest_terraform}_linux_amd64.zip && \
    mv terraform /usr/local/bin/ && \
    rm terraform_${latest_terraform}_linux_amd64.zip

# Ensure the logs directory exists and set appropriate permissions
RUN mkdir -p /var/log/install_logs && \
    touch /var/log/install_logs/log_all_installs.json && \
    chmod -R 777 /var/log/install_logs

# Create directories for Terraform files and SSH keys
RUN mkdir -p /usr/src/terraform && \
    mkdir -p /root/.ssh

# Copy the logging script
COPY log_installs.sh /usr/local/bin/log_installs.sh
RUN chmod +x /usr/local/bin/log_installs.sh

# Ensure logs are readable and keep the container running
CMD ["/bin/sh", "-c", "tail -f /var/log/install_logs/log_all_installs.json"]
```

**Explanation:**

- **Base Image:**
  - Uses `alpine:latest` for a minimal and secure environment.

- **Package Installation:**
  - Installs necessary packages for running Terraform and Ansible.
  - Includes Python 3 and `py3-pip` for Python package management.

- **Python Virtual Environment:**
  - Creates a virtual environment at `/opt/venv`.
  - Installs Ansible within the virtual environment to keep dependencies isolated.

- **Terraform Installation:**
  - Downloads the latest version of Terraform dynamically.
  - Installs Terraform into `/usr/local/bin`.

- **Directory Setup:**
  - Creates necessary directories for logs, Terraform configurations, and SSH keys.
  - Sets permissions to ensure the container can write logs.

- **Logging:**
  - Copies a logging script `log_installs.sh` into the container.
  - Sets the script as executable.

- **Command:**
  - Keeps the container running by tailing the log file.

#### Build and Run the Container

To build and run the Docker container with a fresh image:

```bash
docker compose down
docker compose up --build
```

#### Run the Container Without Rebuilding

To run the container without rebuilding the image:

```bash
docker compose up
```

#### Run the Container in Detached Mode

To run the container in the background:

```bash
docker compose up -d
```

---

### Connecting to the Docker Container

Navigate to the project directory and execute:

```bash
docker exec -it terraform-ansible /bin/sh
```

This command opens an interactive shell inside the running Docker container.

---

## Terraform Configuration

### Configuring the Terraform Backend

To enable remote state storage for Terraform, you can configure Terraform to use GitLab's HTTP backend. This allows Terraform to store its state file securely in your GitLab repository.

Create a file named `00_backend.tf` in your Terraform configuration directory with the following content (make sure to replace placeholders with your actual project information):

```hcl
terraform {
  backend "http" {
    address        = "https://gitlab.com/api/v4/projects/<your_project_id>/terraform/state/<state_name>"
    lock_address   = "https://gitlab.com/api/v4/projects/<your_project_id>/terraform/state/<state_name>/lock"
    unlock_address = "https://gitlab.com/api/v4/projects/<your_project_id>/terraform/state/<state_name>/lock"
    lock_method    = "POST"
    unlock_method  = "DELETE"
    retry_wait_min = 5
  }
}
```

**Explanation:**

- **address**: The URL where the Terraform state will be stored. Replace `<your_project_id>` with your GitLab project ID and `<state_name>` with the desired name for your state file.
- **lock_address** and **unlock_address**: URLs used to lock and unlock the state during operations.
- **lock_method** and **unlock_method**: HTTP methods used for locking and unlocking.
- **retry_wait_min**: Minimum time to wait before retrying a lock.

**Steps to Configure:**

1. **Create `00_backend.tf` File:**

   Navigate to your Terraform directory and create the `00_backend.tf` file with the content provided above.

2. **Replace Placeholders:**

   - `<your_project_id>`: Find your project ID in GitLab. It's usually visible in the project URL or under the project settings.
   - `<state_name>`: Choose a name for your Terraform state (e.g., `state_vpn`).

3. **Configure GitLab Access:**

   - Ensure you have the appropriate permissions and access tokens configured in GitLab to use the HTTP backend for Terraform state storage.
   - You may need to set up a Personal Access Token with `api` scope.

4. **Save and Commit:**

   - Save the `00_backend.tf` file.
   - **Important:** Do not commit sensitive information (like access tokens) to your repository.

5. **Initialize Terraform with Backend:**

   - Run `terraform init` to initialize the backend configuration.

### Initializing Terraform

Inside the Docker container, initialize Terraform:

```bash
terraform init
```

### Applying the Terraform Configuration

#### Set OpenStack Environment Variables

The `openrc.sh` file contains environment variables necessary for interacting with the OpenStack API. Source this file to load the variables:

```bash
source openrc.sh
```

#### Apply the Configuration

Customize the `00_terraform.tfvars` file with your specific variables. This file includes details like instance types, network configurations, and other resources available via the OpenStack API.

To apply the Terraform configuration and create the infrastructure:

```bash
terraform apply -var-file=00_terraform.tfvars
```

To apply the configuration without manual approval:

```bash
terraform apply -var-file=00_terraform.tfvars -auto-approve
```

---

## Ansible Configuration

### Activating the Ansible Virtual Environment

Navigate to the Ansible development environment directory:

```bash
cd /usr/src/ansible/envs/dev
```

Activate the virtual environment:

```bash
. /opt/venv/bin/activate
```

### Ansible Directory Structure

The directory structure for Ansible is as follows:

```plaintext
(venv) /usr/src/ansible
├── envs
│   └── dev
│       ├── 00_inventory.yml
│       ├── group_vars
│       │   └── openvpn.yml
│       └── host_vars
├── playbook.yml
├── requirements.txt
└── roles
    └── openvpn
        ├── README.md
        ├── defaults
        │   └── main.yml
        ├── files
        ├── handlers
        │   └── main.yml
        ├── meta
        │   └── main.yml
        ├── tasks
        │   └── main.yml
        ├── templates
        ├── tests
        │   ├── inventory
        │   └── test.yml
        └── vars
            └── main.yml
```

### Defining CA Variables

In your Ansible configuration, you'll need to define variables for your Certificate Authority (CA) settings. These variables are typically placed in your group or host variables file, such as `group_vars/openvpn.yml`. Below is an example of how to define these variables with obfuscated values:

```yaml
# group_vars/openvpn.yml

vpn_server_name: "your_vpn_server_name"
vpn_key_name: "your_vpn_key_name"
vpn_key_country: "XX"
vpn_key_province: "Your_Province"
vpn_key_city: "Your_City"
vpn_key_org: "Your_Organization"
vpn_key_email: "your_email@example.com"
vpn_key_ou: "Your_Organizational_Unit"
```

**Explanation:**

- **vpn_server_name**: The name of your VPN server.
- **vpn_key_name**: The key name used for the VPN server certificates.
- **vpn_key_country**: Two-letter country code (e.g., "US", "GB").
- **vpn_key_province**: The province or state where your organization is located.
- **vpn_key_city**: The city where your organization is located.
- **vpn_key_org**: The name of your organization.
- **vpn_key_email**: Contact email address for your organization.
- **vpn_key_ou**: Organizational Unit (e.g., "IT Department").

**Note:** Replace the placeholder values with your actual information. Be cautious not to commit sensitive information to public repositories.

### Pinging the Deployed Machines

#### Configure the Inventory

Edit the `00_inventory.yml` file to include your host details:

```yaml
# 00_inventory.yml
all:
  children:
    openvpn:
      hosts:
        srv1:
          ansible_host: <external_ip_address>  # Replace with your machine's external IP
```

#### Ping the Hosts

From the `envs/dev` directory, execute:

```bash
ANSIBLE_PRIVATE_KEY_FILE=/root/.ssh/your_private_key ansible -i /usr/src/ansible/envs/dev/00_inventory.yml all -u debian -m ping
```

- `ANSIBLE_PRIVATE_KEY_FILE`: Environment variable pointing to your private SSH key.
- `-i`: Specifies the inventory file.
- `-u`: SSH user (e.g., `debian`).
- `-m ping`: Uses the Ansible `ping` module to test connectivity.

---

### Running the Ansible Playbook

#### Navigate to the Ansible Directory

Ensure you are in the Ansible directory:

```bash
cd /usr/src/ansible
```

#### Review the Playbook

Ensure `playbook.yml` is correctly configured:

```yaml
# playbook.yml
- name: Install OpenVPN
  hosts: openvpn
  become: true
  roles:
    - openvpn  # Refer to roles/openvpn/tasks/main.yml
```

#### Execute the Playbook

Run the playbook with the following command:

```bash
ansible-playbook -i envs/dev/ -l openvpn -u debian playbook.yml
```

- `-i envs/dev/`: Specifies the inventory directory.
- `-l openvpn`: Limits execution to hosts in the `openvpn` group.
- `-u debian`: SSH user.

**Option Descriptions:**

```sh
-u : User to connect as (SSH)
-i : Inventory file or directory
-l : Limit execution to specified hosts/groups
```

#### Run an Ad-Hoc Command (Optional)

To execute a one-time command on the server:

```bash
ansible -i "external_ip_address," all -u debian -b -m command -a 'ls -la /root/'
```

- Replace `external_ip_address` with your server's IP.
- `-b`: Become root (sudo).
- `-m command`: Specifies the command module.
- `-a 'ls -la /root/'`: The command to run.

---

## Accessing the OpenVPN Server

### Connecting via SSH

#### From Local Machine

If your private key `your_private_key` is on your local machine:

```bash
ssh -i your_private_key debian@external_ip_address
```

#### From Docker Container

If the key is inside the Docker container at `/root/.ssh/your_private_key`:

```bash
ssh -i /root/.ssh/your_private_key debian@external_ip_address
```

- Replace `external_ip_address` with your server's IP.

---

### Verifying OpenVPN Status

After connecting to the Debian machine where OpenVPN is running, verify active network connections:

```bash
netstat -ntaup
```

---

## Appendix

### Explanation of `netstat` Options

The `netstat` command is used to display network connections, routing tables, interface statistics, masquerade connections, and multicast memberships.

- `-n`: Show numerical addresses instead of resolving hosts.
- `-t`: Display TCP connections.
- `-u`: Display UDP connections.
- `-a`: Show all active connections and listening ports.
- `-p`: Show the PID and name of the program to which each socket belongs.

---

## Notes

- **Security Notice:** Ensure that sensitive information like IP addresses, SSH keys, and credentials are kept secure and not committed to public repositories.
- **Customization:** Adjust the inventory files, variable files, and configurations according to your environment.
- **Documentation:** Refer to the official [Terraform documentation](https://www.terraform.io/docs/) and [Ansible documentation](https://docs.ansible.com/) for in-depth guidance.

---

## Contributing

Contributions are welcome! Please submit a pull request or open an issue to discuss changes.

---

## License

This project is licensed under the [MIT License](LICENSE).

---

If you have any questions or need further assistance, feel free to reach out.