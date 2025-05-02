#!/usr/bin/env bash

# Git Environment Setup Script
# Version: 1.0.0
# Author: Amir Khosro Awhadi
# Description: Comprehensive setup for Git configuration, SSH keys, and repository management

# Exit immediately if a command exits with non-zero status
set -e

# Global variables
declare -a REQUIRED_PKGS=("git" "ssh")
declare -A COLOR=(
    ["NC"]='\033[0m'
    ["CYAN"]='\033[1;36m'
    ["YELLOW"]='\033[1;33m'
    ["GRAY"]='\033[0;37m'
    ["GREEN"]='\033[1;32m'
    ["RED"]='\033[1;31m'
    ["BLUE"]='\033[1;34m'
)

# Initialize script
init_script() {
    clear
    display_header
    display_banner
}

# Display script header
display_header() {
    echo -e "${COLOR[CYAN]}================================================================================"
    echo -e "                          GIT ENVIRONMENT SETUP TOOL                          "
    echo -e "================================================================================${COLOR[NC]}"
    echo ""
}

# Display ASCII banner
display_banner() {
    echo -e "${COLOR[GRAY]}···················································································${COLOR[NC]}"
    echo -e "${COLOR[YELLOW]}:   █████████   █████   ███   █████ █████   █████   █████████   ██████████   █████: ${COLOR[NC]}"
    echo -e "${COLOR[YELLOW]}:  ███░░░░░███ ░░███   ░███  ░░███ ░░███   ░░███   ███░░░░░███ ░░███░░░░███ ░░███ : ${COLOR[NC]}"
    echo -e "${COLOR[YELLOW]}: ░███    ░███  ░███   ░███   ░███  ░███    ░███  ░███    ░███  ░███   ░░███ ░███ : ${COLOR[NC]}"
    echo -e "${COLOR[YELLOW]}: ░███████████  ░███   ░███   ░███  ░███████████  ░███████████  ░███    ░███ ░███ : ${COLOR[NC]}"
    echo -e "${COLOR[YELLOW]}: ░███░░░░░███  ░░███  █████  ███   ░███░░░░░███  ░███░░░░░███  ░███    ░███ ░███ : ${COLOR[NC]}"
    echo -e "${COLOR[YELLOW]}: ░███    ░███   ░░░█████░█████░    ░███    ░███  ░███    ░███  ░███    ███  ░███ : ${COLOR[NC]}"
    echo -e "${COLOR[YELLOW]}: █████   █████    ░░███ ░░███      █████   █████ █████   █████ ██████████   █████: ${COLOR[NC]}"
    echo -e "${COLOR[YELLOW]}:░░░░░   ░░░░░      ░░░   ░░░      ░░░░░   ░░░░░ ░░░░░   ░░░░░ ░░░░░░░░░░   ░░░░░ : ${COLOR[NC]}"
    echo -e "${COLOR[GRAY]}···················································································${COLOR[NC]}"
    echo ""
}

# Print formatted message
print_message() {
    local type=$1
    local message=$2
    local symbol=""
    local color=""
    
    case $type in
        "success") symbol="✓"; color=${COLOR[GREEN]} ;;
        "error") symbol="✗"; color=${COLOR[RED]} ;;
        "info") symbol="ℹ"; color=${COLOR[BLUE]} ;;
        "warning") symbol="⚠"; color=${COLOR[YELLOW]} ;;
        *) symbol="•"; color=${COLOR[NC]} ;;
    esac
    
    echo -e "${color}${symbol} ${message}${COLOR[NC]}"
}

# Check and install required packages
check_and_install_packages() {
    print_message "info" "Checking required packages..."
    
    for pkg in "${REQUIRED_PKGS[@]}"; do
        if command -v "$pkg" &> /dev/null; then
            print_message "success" "$pkg is already installed."
        else
            print_message "warning" "$pkg is not installed. Attempting to install..."
            
            if [[ -f /etc/debian_version ]]; then
                sudo apt-get update && sudo apt-get install -y "$pkg"
            elif [[ -f /etc/redhat-release ]]; then
                sudo yum install -y "$pkg"
            elif [[ "$OSTYPE" == "darwin"* ]]; then
                if command -v brew &> /dev/null; then
                    brew install "$pkg"
                else
                    print_message "error" "Homebrew not found. Please install $pkg manually."
                    continue
                fi
            else
                print_message "error" "Unsupported OS. Please install $pkg manually."
                continue
            fi
            
            if command -v "$pkg" &> /dev/null; then
                print_message "success" "$pkg installed successfully."
            else
                print_message "error" "Failed to install $pkg."
            fi
        fi
    done
}

# Configure Git user
configure_git_user() {
    print_message "info" "Checking Git user configuration..."
    
    CURRENT_NAME=$(git config --global user.name || echo "")
    CURRENT_EMAIL=$(git config --global user.email || echo "")
    
    if [[ -z "$CURRENT_NAME" && -z "$CURRENT_EMAIL" ]]; then
        print_message "warning" "No Git user is currently configured."
    else
        echo -e "${COLOR[BLUE]}Current Git user configuration:"
        echo -e "  Name : ${CURRENT_NAME:-Not set}"
        echo -e "  Email: ${CURRENT_EMAIL:-Not set}${COLOR[NC]}"
    fi
    
    read -rp "Do you want to update the Git user configuration? (y/n): " update_choice
    if [[ "$update_choice" =~ ^[Yy]$ ]]; then
        while true; do
            read -rp "Enter your full name: " new_name
            if [[ -n "$new_name" ]]; then
                break
            fi
            print_message "error" "Name cannot be empty."
        done
        
        while true; do
            read -rp "Enter your email address: " new_email
            if [[ -z "$new_email" ]]; then
                print_message "error" "Email cannot be empty."
            elif [[ ! "$new_email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
                print_message "error" "Invalid email format."
            else
                break
            fi
        done
        
        git config --global user.name "$new_name"
        git config --global user.email "$new_email"
        print_message "success" "Git user configuration updated successfully."
    else
        print_message "info" "No changes made to Git user configuration."
    fi
}

# Prompt for SSH key details
prompt_ssh_key_details() {
    echo -e "\n${COLOR[BLUE]}SSH Key Configuration Options:${COLOR[NC]}"
    echo "1. Default location (~/.ssh)"
    echo "2. Custom location"
    
    while true; do
        read -rp "Enter your choice (1/2): " choice
        case $choice in
            1)
                ssh_dir="$HOME/.ssh"
                break
                ;;
            2)
                while true; do
                    read -rp "Enter full path for the SSH key directory: " custom_dir
                    if [[ -d "$custom_dir" ]]; then
                        ssh_dir="$custom_dir"
                        break
                    else
                        read -rp "Directory doesn't exist. Create it? (y/n): " create_dir
                        if [[ "$create_dir" =~ ^[Yy]$ ]]; then
                            mkdir -p "$custom_dir" && ssh_dir="$custom_dir"
                            break
                        fi
                    fi
                done
                break
                ;;
            *)
                print_message "error" "Invalid choice. Please enter 1 or 2."
                ;;
        esac
    done
    
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    
    while true; do
        read -rp "Enter filename for the SSH key (default: id_ed25519): " key_name
        key_name=${key_name:-id_ed25519}
        key_file="$ssh_dir/$key_name"
        
        if [[ -f "$key_file" ]]; then
            print_message "warning" "Key file already exists: $key_file"
            read -rp "Overwrite? (y/n): " overwrite
            [[ "$overwrite" =~ ^[Yy]$ ]] && break
        else
            break
        fi
    done
    
    read -rp "Enter comment for the key (default: git-setup-key): " key_comment
    key_comment=${key_comment:-git-setup-key}
    
    ssh-keygen -t ed25519 -f "$key_file" -C "$key_comment" -N ""
    chmod 600 "$key_file"
    chmod 644 "$key_file.pub"
    
    print_message "success" "SSH key generated successfully!"
    echo -e "\n${COLOR[CYAN]}=== Your new public key ===${COLOR[NC]}"
    cat "$key_file.pub"
    echo -e "${COLOR[CYAN]}===========================${COLOR[NC]}\n"
}

# Create or show SSH key
create_or_show_ssh_key() {
    DEFAULT_SSH_KEY="$HOME/.ssh/id_ed25519"
    
    if [[ -f "$DEFAULT_SSH_KEY" ]]; then
        print_message "info" "Existing SSH key found at: $DEFAULT_SSH_KEY"
        read -rp "Do you want to create a new SSH key? (y/n): " create_new
        
        if [[ "$create_new" =~ ^[Yy]$ ]]; then
            prompt_ssh_key_details
        else
            echo -e "\n${COLOR[CYAN]}=== Your existing public key ===${COLOR[NC]}"
            cat "$DEFAULT_SSH_KEY.pub"
            echo -e "${COLOR[CYAN]}================================${COLOR[NC]}\n"
            ssh_dir="$HOME/.ssh"
            key_file="$DEFAULT_SSH_KEY"
        fi
    else
        prompt_ssh_key_details
    fi
}

# Test SSH authentication
test_ssh_auth() {
    local key_path="$1"
    local attempts=0
    local max_attempts=3
    
    while [[ $attempts -lt $max_attempts ]]; do
        print_message "info" "Testing authentication (attempt $((attempts + 1)) of $max_attempts)..."
        
        if ssh -T -o IdentitiesOnly=yes -i "$key_path" git@github.com 2>&1 | grep -q "successfully authenticated"; then
            print_message "success" "GitHub authentication successful!"
            return 0
        elif ssh -T -o IdentitiesOnly=yes -i "$key_path" git@gitlab.com 2>&1 | grep -q "Welcome to GitLab"; then
            print_message "success" "GitLab authentication successful!"
            return 0
        else
            print_message "error" "Authentication failed."
            ((attempts++))
            
            if [[ $attempts -lt $max_attempts ]]; then
                print_message "info" "Please ensure your public key is added to your Git provider."
                read -rp "Press Enter after you've added the key to retry..."
            fi
        fi
    done
    
    print_message "error" "Could not authenticate after $max_attempts attempts."
    return 1
}

# Clone repositories
clone_repositories() {
    declare -a repos
    declare -A seen_repos
    
    if command -v gh &> /dev/null; then
        read -rp "GitHub CLI detected. List your repos? (y/n): " use_gh
        if [[ "$use_gh" =~ ^[Yy]$ ]]; then
            print_message "info" "Fetching GitHub repositories..."
            mapfile -t gh_repos < <(gh repo list --ssh-url --limit 100 2>/dev/null || true)
            
            if [[ ${#gh_repos[@]} -gt 0 ]]; then
                echo -e "\n${COLOR[BLUE]}Select repositories to clone:${COLOR[NC]}"
                for i in "${!gh_repos[@]}"; do
                    echo "$((i+1)). ${gh_repos[i]}"
                done
                
                while true; do
                    read -rp "Enter numbers separated by commas (or 'all'): " nums
                    
                    if [[ "$nums" == "all" ]]; then
                        repos=("${gh_repos[@]}")
                        break
                    elif [[ "$nums" =~ ^[0-9]+(,[0-9]+)*$ ]]; then
                        IFS=, read -ra indices <<< "$nums"
                        for idx in "${indices[@]}"; do
                            if [[ $idx -gt 0 && $idx -le ${#gh_repos[@]} ]]; then
                                repos+=("${gh_repos[idx-1]}")
                            else
                                print_message "warning" "Invalid index: $idx. Skipping."
                            fi
                        done
                        [[ ${#repos[@]} -gt 0 ]] && break
                    fi
                    print_message "error" "Invalid input. Please try again."
                done
            else
                print_message "warning" "No repositories found via GitHub CLI."
            fi
        fi
    fi
    
    if [[ ${#repos[@]} -eq 0 ]]; then
        echo -e "\n${COLOR[BLUE]}Manual Repository Entry${COLOR[NC]}"
        echo "Enter SSH URLs of repositories to clone (one per line)."
        echo "Press ENTER on empty line to finish:"
        
        while true; do
            read -rp "Repo SSH URL: " repo
            [[ -z "$repo" ]] && break
            
            if [[ "$repo" =~ ^git@[^:]+:[^/]+/.+\.git$ ]]; then
                if [[ -n "${seen_repos[$repo]}" ]]; then
                    print_message "warning" "Duplicate repo detected: $repo. Skipping."
                    continue
                fi
                seen_repos["$repo"]=1
                repos+=("$repo")
            else
                print_message "error" "Invalid URL format. Example: git@github.com:user/repo.git"
            fi
        done
    fi
    
    if [[ ${#repos[@]} -eq 0 ]]; then
        print_message "warning" "No repositories specified for cloning."
        return
    fi
    
    read -rp "Clone all repos to same base path? (y/n): " same_path
    
    if [[ "$same_path" =~ ^[Yy]$ ]]; then
        while true; do
            read -rp "Enter base path (default: ./): " base_path
            base_path=${base_path:-./}
            
            if [[ ! -d "$base_path" ]]; then
                read -rp "Path doesn't exist. Create it? (y/n): " create_path
                if [[ "$create_path" =~ ^[Yy]$ ]]; then
                    mkdir -p "$base_path" || {
                        print_message "error" "Failed to create directory."
                        continue
                    }
                    break
                fi
            else
                break
            fi
        done
        
        for repo in "${repos[@]}"; do
            repo_name=$(basename "$repo" .git)
            dest_path="$base_path/$repo_name"
            
            if [[ -d "$dest_path" ]]; then
                if [[ "$(ls -A "$dest_path")" ]]; then
                    print_message "warning" "Directory $dest_path already exists and is not empty."
                    read -rp "Enter alternative path for this repository: " new_path
                    dest_path="${new_path%/}/$repo_name"
                else
                    print_message "info" "Directory $dest_path exists but is empty. Using it."
                fi
            fi
            
            mkdir -p "$(dirname "$dest_path")"
            print_message "info" "Cloning $repo into $dest_path ..."
            
            if git clone "$repo" "$dest_path"; then
                chown -R "$(id -u):$(id -g)" "$dest_path"
                print_message "success" "Successfully cloned $repo_name"
            else
                print_message "error" "Failed to clone $repo_name"
            fi
        done
    else
        for repo in "${repos[@]}"; do
            repo_name=$(basename "$repo" .git)
            
            while true; do
                read -rp "Enter path for $repo_name (default: ./): " repo_path
                repo_path=${repo_path:-./}
                
                if [[ ! -d "$repo_path" ]]; then
                    read -rp "Path doesn't exist. Create it? (y/n): " create_path
                    if [[ "$create_path" =~ ^[Yy]$ ]]; then
                        mkdir -p "$repo_path" || {
                            print_message "error" "Failed to create directory."
                            continue
                        }
                    else
                        continue
                    fi
                fi
                
                dest_path="$repo_path/$repo_name"
                
                if [[ -d "$dest_path" && "$(ls -A "$dest_path")" ]]; then
                    print_message "warning" "Directory $dest_path already exists and is not empty."
                    continue
                fi
                
                print_message "info" "Cloning $repo into $dest_path ..."
                
                if git clone "$repo" "$dest_path"; then
                    chown -R "$(id -u):$(id -g)" "$dest_path"
                    print_message "success" "Successfully cloned $repo_name"
                    break
                else
                    print_message "error" "Failed to clone $repo_name"
                    read -rp "Try again with different path? (y/n): " try_again
                    [[ "$try_again" =~ ^[Yy]$ ]] || break
                fi
            done
        done
    fi
}

# Run all setup steps
run_all() {
    print_message "info" "Starting complete setup process..."
    
    check_and_install_packages
    configure_git_user
    create_or_show_ssh_key
    
    key_path="${ssh_dir:-$HOME/.ssh}/id_ed25519"
    print_message "info" "Please add the public key to your Git provider:"
    cat "$key_path.pub"
    
    read -rp "Press Enter once you've added the key to continue..."
    
    if test_ssh_auth "$key_path"; then
        clone_repositories
        print_message "success" "🎉 All setup steps completed successfully!"
    else
        print_message "error" "Setup incomplete due to authentication failure."
        exit 1
    fi
}

# Main menu
main_menu() {
    while true; do
        echo -e "\n${COLOR[CYAN]}====== Git Environment Setup Menu ======${COLOR[NC]}"
        echo "1. Check and install required packages"
        echo "2. Configure Git user"
        echo "3. Create new SSH key or show existing"
        echo "4. Test SSH authentication"
        echo "5. Clone repositories"
        echo "6. Run all setup steps"
        echo "7. Exit"
        
        read -rp "Select an option (1-7): " choice
        
        case $choice in
            1) check_and_install_packages ;;
            2) configure_git_user ;;
            3) create_or_show_ssh_key ;;
            4)
                key_path="${ssh_dir:-$HOME/.ssh}/id_ed25519"
                if [[ -f "$key_path" ]]; then
                    test_ssh_auth "$key_path"
                else
                    print_message "error" "No SSH key found. Please create one first."
                fi
                ;;
            5) clone_repositories ;;
            6) run_all ;;
            7)
                print_message "info" "Exiting Git Environment Setup Tool. Goodbye!"
                exit 0
                ;;
            *)
                print_message "error" "Invalid option. Please select 1-7."
                ;;
        esac
    done
}

# Main execution
init_script
main_menu