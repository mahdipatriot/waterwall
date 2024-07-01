#!/bin/bash

# Function to create Waterwall configuration and service
create_waterwall_config() {
    clear
    echo "Creating Waterwall Configuration and Service..."

    # Check if unzip is installed, install if necessary
    if ! command -v unzip &> /dev/null; then
        echo "Installing unzip..."
        apt update
        apt install -y unzip
    fi

    # Create folder and download Waterwall
    mkdir -p /root/waterwall
    cd /root/waterwall || exit

    echo "Downloading Waterwall binary..."
    wget -O Waterwall-linux-64.zip https://github.com/radkesvat/WaterWall/releases/latest/download/Waterwall-linux-64.zip
    unzip Waterwall-linux-64.zip
    rm Waterwall-linux-64.zip
    mv Waterwall waterwall
    chmod +x /root/waterwall/waterwall

    # Download core.json
    echo "Downloading core.json..."
    wget -O core.json https://raw.githubusercontent.com/mahdipatriot/waterwall/main/core.json

    # Select server type: Iran or Kharej
    echo "Select server type:"
    echo "1. Iran"
    echo "2. Kharej"
    read -rp "Enter your choice: " server_type

    case $server_type in
        1)
            # Iran server configuration
            read -rp "Enter secure password: " passwd
            read -rp "Enter Kharej server IP: " inja_ip_kharej
            read -rp "Enter ipv4 or ipv6: " ip_version
            read -rp "Enter SNI: " inja_sni

            # Download and customize config.json for Iran server
            wget -O config.json https://raw.githubusercontent.com/mahdipatriot/waterwall/main/halfduplex_reverse_reality_iran
            sed -i "s/\$passwd/$passwd/g" config.json
            sed -i "s/\$inja_ip_kharej/$inja_ip_kharej/g" config.json
            sed -i "s/\$inja_sni/$inja_sni/g" config.json
            ;;
        2)
            # Kharej server configuration
            read -rp "Enter secure password: " passwd
            read -rp "Enter Iran server IP: " inja_ip_server_iran
            read -rp "Enter ipv4 or ipv6: " ip_version
            read -rp "Enter SNI: " inja_sni

            # Download and customize config.json for Kharej server
            wget -O config.json https://raw.githubusercontent.com/mahdipatriot/waterwall/main/halfuplex_reverse_reality_kharej
            sed -i "s/\$passwd/$passwd/g" config.json
            sed -i "s/\$inja_ip_server_iran/$inja_ip_server_iran/g" config.json
            sed -i "s/\$inja_sni/$inja_sni/g" config.json
            ;;
        *)
            echo "Invalid option. Exiting..."
            exit 1
            ;;
    esac

    # Create systemd service
    cat > /etc/systemd/system/waterwall.service <<EOF
[Unit]
Description=Waterwall Service
After=network.target

[Service]
ExecStart=/root/waterwall/waterwall
WorkingDirectory=/root/waterwall
StandardOutput=journal
StandardError=journal
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

    # Reload and start service
    systemctl daemon-reload
    systemctl start waterwall
    systemctl enable waterwall

    echo "Waterwall configuration and service setup complete."
    echo "Systemd service status:"
    systemctl status waterwall --no-pager
}

# Function to remove Waterwall configuration and service
remove_waterwall_config() {
    clear
    echo "Removing Waterwall Configuration and Service..."

    read -rp "Are you sure you want to remove /root/waterwall and related systemd service? (yes/no): " answer
    case $answer in
        yes)
            systemctl stop waterwall
            systemctl disable waterwall
            rm -rf /root/waterwall
            rm /etc/systemd/system/waterwall.service
            echo "Waterwall configuration and service removed."
            ;;
        *)
            echo "Removal aborted."
            ;;
    esac
}

# Function to show Waterwall service status
show_service_status() {
    clear
    echo "Waterwall Service Status:"
    systemctl status waterwall --no-pager
}

# Function to restart Waterwall service
restart_service() {
    clear
    echo "Restarting Waterwall Service..."
    systemctl restart waterwall
    echo "Waterwall Service restarted."
}

# Main menu function
main_menu() {
    clear
    echo "MahdiPatrioT WATERFALL MENU"
    echo "1. Create Configuration and Service"
    echo "2. Remove Configuration and Service"
    echo "3. Show Service Status"
    echo "4. Restart Service"
    echo "5. Exit"

    read -rp "Enter your choice: " choice
    case $choice in
        1)
            create_waterwall_config
            ;;
        2)
            remove_waterwall_config
            ;;
        3)
            show_service_status
            ;;
        4)
            restart_service
            ;;
        5)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
}

# Loop to display main menu until user exits
while true; do
    main_menu
    read -rp "Press Enter to return to the main menu."
done
