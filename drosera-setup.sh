
#!/bin/bash

# --- Color Definitions ---
RED='\e[31m'
YELLOW='\e[33m'
GREEN='\e[32m'
HACKER_GREEN='\033[1;32m'
BOLD='\e[1m'
NC='\e[0m' # No Color

# --- Utility Functions for Colored Output ---
print_error() {
  echo -e "${RED}Error: $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}Warning: $1${NC}"
}

print_success() {
  echo -e "${BOLD}${GREEN}$1${NC}"
}

print_info() {
  echo -e "${BOLD}${HACKER_GREEN}$1${NC}"
}

# --- Banner Method ---
MrXintro() {
  print_info "#####################################################"
  print_info " ███╗   ███╗██████╗        ██╗  ██╗"
  print_info "████╗ ████║██╔══██╗       ╚██╗██╔╝"
  print_info "██╔████╔██║██████╔╝        ╚███╔╝ "
  print_info "██║╚██╔╝██║██╔══██╗        ██╔██╗ "
  print_info "██║ ╚═╝ ██║██║  ██║██╗    ██╔╝ ██╗"
  print_info "╚═╝     ╚═╝╚═╝  ╚═╝╚═╝    ╚═╝  ╚═╝"
  print_info "           Github: http://github.com/iamxlord"
  print_info "           Twitter: http://x.com/iamxlord"
                                  
  print_info "#####################################################"
  print_info ""
}

# --- Function to Install Dependencies ---
install_dependencies() {
  print_info "--- Installing Dependencies ---"
  print_info "Updating and upgrading your system..."
  sudo apt-get update && sudo apt-get upgrade -y
  if [ $? -ne 0 ]; then
    print_error "Failed to update and upgrade system. Exiting."
    exit 1
  fi

  print_info "Installing core dependencies..."
  sudo apt install curl ufw iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip -y
  if [ $? -ne 0 ]; then
    print_error "Failed to install core dependencies. Exiting."
    exit 1
  fi
  print_success "Dependencies installed successfully!"
}

# --- Function to Install Docker ---
install_docker() {
  print_info "--- Installing Docker ---"
  read -p "Do you have a functional Docker installation already? (Y/N): " docker_check_response

  if [[ "$docker_check_response" =~ ^[Nn]$ ]]; then
    print_info "Proceeding with Docker installation..."

    print_info "Removing old Docker packages..."
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

    print_info "Setting up Docker repository..."
    sudo apt-get update
    sudo apt-get install ca-certificates curl gnupg -y
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    print_info "Adding Docker APT repository..."
    echo \
      "deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      \"$(. /etc/os-release && echo "$VERSION_CODENAME")\" stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    print_info "Installing Docker engine..."
    sudo apt update -y && sudo apt upgrade -y
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    if [ $? -ne 0 ]; then
      print_error "Failed to install Docker. Exiting."
      exit 1
    fi

    print_info "Testing Docker installation..."
    sudo docker run hello-world
    if [ $? -eq 0 ]; then
      print_success "Docker successfully installed!"
    else
      print_error "Docker test failed. Please check your Docker installation."
      exit 1
    fi
  else
    print_success "Skipping Docker installation as you indicated it's already installed."
  fi
}

# --- Function to Set Up Trap Environment ---
setup_trap_environment() {
  print_info "--- Setting Up Trap Environment ---"

  print_info "Installing Drosera CLI..."
  curl -L https://app.drosera.io/install | bash
  if [ $? -ne 0 ]; then
    print_error "Failed to install Drosera CLI. Exiting."
    exit 1
  fi
  source "$HOME/.bashrc"
  droseraup
  print_success "Drosera CLI successfully installed!"
}

# --- Function to Install Foundry CLI ---
install_foundry_cli() {
  print_info "--- Installing Foundry CLI ---"
  curl -L https://foundry.paradigm.xyz | bash
  if [ $? -ne 0 ]; then
    print_error "Failed to install Foundry CLI. Exiting."
    exit 1
  fi
  source "$HOME/.bashrc"
  foundryup
  print_success "Foundry CLI successfully installed!"
}

# --- Function to Install Bun ---
install_bun() {
  print_info "--- Installing Bun ---"
  curl -fsSL https://bun.sh/install | bash
  if [ $? -ne 0 ]; then
    print_error "Failed to install Bun. Exiting."
    exit 1
  fi
  source "$HOME/.bashrc"
  print_success "Bun successfully installed!"
}

# --- Function to Deploy Contract & Trap Environments ---
deploy_environments() {
  print_info "--- Deploying Contract & Trap Environments ---"

  print_info "Creating 'my-drosera-trap' directory..."
  mkdir -p my-drosera-trap
  cd my-drosera-trap || { print_error "Failed to create or enter 'my-drosera-trap' directory. Exiting."; exit 1; }
  print_success "Entered 'my-drosera-trap' directory."

  # --- Get GitHub Credentials ---
  print_info ""
  print_info "Now, let's configure your Github identity for drosera."
  local github_email
  local github_username

  read -p "Please enter your GitHub email address: " github_email
  while [[ ! "$github_email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; do
    print_error "Invalid email format. Please try again."
    read -p "Please enter your GitHub email address: " github_email
  done

  read -p "Please enter your GitHub username: " github_username
  while [[ -z "$github_username" ]]; do
    print_error "GitHub username cannot be empty. Please try again."
    read -p "Please enter your GitHub username: " github_username
  done

  git config --global user.email "$github_email"
  git config --global user.name "$github_username"
  print_success "GitHub email and username configured successfully!"

  # --- Initializing Trap ---
  print_info ""
  print_info "--- Initializing Trap ---"
  print_info "Initializing trap with 'forge init'..."
  forge init -t drosera-network/trap-foundry-template
  if [ $? -ne 0 ]; then
    print_error "Failed to initialize trap with 'forge init'. Exiting."
    exit 1
  fi
  print_success "Trap initialized!"

  # --- Compiling Trap ---
  print_info ""
  print_info "--- Compiling Trap ---"
  print_info "Ensuring Bun is available for 'bun install'..."
  curl -fsSL https://bun.sh/install | bash
  source "$HOME/.bashrc"

  print_info "Running 'bun install'..."
  bun install
  if [ $? -ne 0 ]; then
    print_warning "'bun install' failed. Please check for issues. Continuing with forge build."
  else
    print_success "Bun packages installed."
  fi

  print_info "Running 'forge build'..."
  forge build
  if [ $? -ne 0 ]; then
    print_warning "'forge build' encountered issues. Please review the output above. This might include warnings that can be skipped, but please verify."
  else
    print_success "Trap compilation attempted."
  fi
}

# --- Main Script Execution ---
MrXintro

# --- First time running check ---
read -p "Are you running the script for the first time? (Y/N): " first_time_response

if [[ "$first_time_response" =~ ^[Yy]$ ]]; then
  print_info "Proceeding with full installation..."
  install_dependencies
  install_docker
  setup_trap_environment
  install_foundry_cli
  install_bun
  deploy_environments
else
  print_warning "Skipping initial setup. Please ensure all dependencies are met."
  read -p "Do you want to proceed with deploying contract & trap environments? (Y/N): " proceed_deploy
  if [[ "$proceed_deploy" =~ ^[Yy]$ ]]; then
    deploy_environments
  else
    print_info "Script finished without further actions."
    exit 0
  fi
fi

print_info ""
print_info "--- Setup Complete! ---"
print_info "You're almost there! Visit https://github.com/iamxlord/Drosera-Network repository for the rest of the guide."

