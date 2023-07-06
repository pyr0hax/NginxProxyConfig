#Author: Jaco van Zyl
#Email: jvanzyl5@outlook.com
#!/bin/bash

# Function to check if a directory exists
is_directory_available() {
    [ -d "$1" ]
}

# Function to pause script execution
pause() {
    local message="${1:-Press any key to continue...}"
    read -rsp "$message" -n1 key
    echo
}

# Check if certbot and python3-certbot-nginx are already installed
if dpkg -s "certbot" >/dev/null 2>&1 && dpkg -s "python3-certbot-nginx" >/dev/null 2>&1; then
    echo "certbot and python3-certbot-nginx are already installed."
else
    # Install certbot and python3-certbot-nginx
    sudo apt install -y certbot python3-certbot-nginx
fi

# Prompt the user for input
read -p "Enter the proxy address (e.g., example.com): " proxy_address
read -p "Enter the target address (e.g., http://localhost:8000): " target_address

# Determine the configuration file names and paths
sites_available_dir="/etc/nginx/sites-available"
sites_enabled_dir="/etc/nginx/sites-enabled"
base_config_file="reverse_proxy"
config_file="$sites_available_dir/$base_config_file.conf"
counter=2

echo "The script will temporarily modify the permissons of the NginX sites-available and sites-enabled directories."
pause "Press any key to continue..."

sudo chmod 777 $sites_available_dir
sudo chmod 777 $sites_enabled_dir

echo "$sites_available_dir and $sites_enabled_dir has been given full permission so that files can be written to it by script"
pause


# Check if the sites-available directory exists
if ! is_directory_available "$sites_available_dir"; then
    echo "Directory $sites_available_dir does not exist. Please make sure NGINX is installed correctly."
    exit 1
fi

# Check if the sites-enabled directory exists
if ! is_directory_available "$sites_enabled_dir"; then
    echo "Directory $sites_enabled_dir does not exist. Please make sure NGINX is installed correctly."
    exit 1
fi

# Check if the base configuration file already exists
while [ -e "$config_file" ]; do
    config_file="$sites_available_dir/${base_config_file}_$counter.conf"
    counter=$((counter + 1))
done

# Generate the NGINX configuration file
if cat > "$config_file" << EOF
server {
    listen 80;
    server_name $proxy_address;

    location / {
        proxy_pass $target_address;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF
then
    echo "NGINX configuration file has been generated at $config_file."

    # Create a symbolic link in sites-enabled
    if ln -s "$config_file" "$sites_enabled_dir/$(basename "$config_file")"
    then
        echo "A symbolic link has been created in $sites_enabled_dir."

        # Restart NGINX to apply the configuration
        if sudo service nginx restart >/dev/null 2>&1
        then
            echo "NGINX has been restarted to apply the configuration."
        else
            echo "Failed to restart NGINX. Please make sure NGINX is installed correctly."
            exit 1
        fi
    else
        echo "Failed to create symbolic link. Please check the permissions of $sites_enabled_dir."
        exit 1
    fi
else
    echo "Failed to generate NGINX configuration file. Please check the permissions of $sites_available_dir."
    exit 1
fi

echo "The script will now run Certbot to make your site secured."
pause "Press any key to continue..."

sudo certbot --nginx -d $proxy_address --email email@example.com --agree-tos --redirect

echo "The script will now set the permissions back to 755."
pause "Press any key to continue..."

sudo chmod 755 $sites_available_dir
sudo chmod 755 $sites_enabled_dir

sudo nginx -t
sudo service nginx restart