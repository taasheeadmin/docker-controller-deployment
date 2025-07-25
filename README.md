# Docker Swarm Deployment with EFS and Auto-Scaling

This guide walks through the steps to set up a Docker Swarm environment on AWS with NFS (EFS) storage and deploy the Code Server application using Docker Stack.

## Prerequisites

- AWS account with permissions to create EFS, EC2, and Launch Templates
- EC2 Key Pair for SSH access (optional but recommended)

---

## Steps

### 1. Create NFS Storage (AWS EFS)
- Navigate to AWS EFS Console.
- Create a new EFS filesystem in your preferred region and VPC.
- Note the EFS mount target DNS name for later use.

---

### 2. Set Up Docker Swarm Master

- Launch a new EC2 instance (name it `master`) and SSH into it.
- Install Docker from [official website](https://docs.docker.com/engine/install/)

* Initialize Docker Swarm:

  ```bash
  docker swarm init
  ```

* Note down the output join command (you'll use this for worker nodes).
* Execute below command before mounting:-
  change user_name & group_name accordingly in the below command
  ```bash
  mkdir -p /mnt/nfs_storage/code-spaces-mapping
  sudo chown {user_name}:{group_name} -R nfs_storage/
  ```
* Mount the EFS filesystem using command given in Attach session of EFS.

---

### 3. Create Launch Template for Worker Nodes

* Go to EC2 → Launch Templates → Create new template.

* In **User Data**, add the following script (replace with actual values):

  ```bash
  #!/bin/bash
  set -e
  
  # Update package list
  
  apt update -y
  
  # Install required packages
  
  apt install -y curl nfs-common
  
  # Install Docker from external script
  echo "Removing old versions of Docker (if any)..."
  for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
      sudo apt-get remove -y "$pkg" || true
  done
  
  sudo apt-get autoremove -y
  
  echo "Installing prerequisites..."
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl
  
  echo "Adding Docker’s official GPG key..."
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  
  echo "Setting up the Docker repository..."
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  
  sudo apt-get update
  
  echo "Installing Docker Engine and related components..."
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  
  echo "Docker installed successfully."
  
  # Create a directory to mount EFS
  
  mkdir -p /mnt/nfs_storage
  
  # Mount EFS
  
  mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 10.0.1.10:/ /mnt/nfs_storage
  
  # Join Docker swarm
  
  docker swarm join --token SWMTKN-1-5ityofb9d2qpn2byy7q6csgpfvouihjwx97196d8to0ji5g0bv-clhuuhwijyn8n40m88uiu1bw8 10.0.1.198:2377
  
  docker pull taasheeadmin/code-server
  ```

* Update docker swarm token and nfs mount command.

---

### 4. Clone and Deploy the Application

* On the **master node**, clone the repository:

  ```bash
  git clone -b master https://github.com/taasheeadmin/docker-controller-deployment.git
  cd docker-controller-deployment
  ```

* Update the `.env` file with appropriate environment variables.
environment:
      - MAPPING_PATH=/mnt/nfs_storage/code-spaces-mapping
      - BASE_URL={master_public_ip}
      - ACCEPTED_CONTAINERS_COUNT={count of containers per VM}
      - MIN_CAPACITY_REQUIRED={on demand containers available before creating another VM}
      - ACCESS_KEY={AWS_ACCESS_KEY}
      - SECRET_ACCESS_KEY={AWS_SECRET_KEY}
      - REGION={REGION}
      - POSTGRES_DB=code_server
      - POSTGRES_USER=code_server
      - POSTGRES_PASSWORD=code_server
      - POSTGRES_HOST=db

* Deploy the stack:

  ```bash
  docker stack deploy -c docker-compose.yml code_server
  ```

---

### 5. Access the Application

* Once deployed, access the application in your browser using the **master node's public IP** on port `80`:

  ```
  http://<master_ip>
  ```

---

### 6. Schedule Auto Scale Down via Swagger

* Open the Swagger UI of the application `/swagger`.
* Locate the endpoint for scheduling.
* Add your preferred **auto scale-down schedule time** as per the API instructions.

---

## Notes

* Ensure security groups allow inbound traffic on ports 80, 2377, 7946, and 4789.
* EFS must be in the same VPC and accessible to all nodes.
* Monitor Docker Swarm with `docker node ls` and `docker service ls`.
