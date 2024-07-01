#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\e[36m'
NC='\033[0m' # No Color

# Directories and files
CONFIG_DIR="/root/waterwall"
SERVICE_DIR="/etc/systemd/system"
RESET_SCRIPT="/etc/mahdiratholereset.sh"
CRON_FILE="/etc/cron.d/rathole_cron"

# Function to create Waterwall configuration and service
create_waterwall_config() {
    echo -e "${YELLOW}"
    echo "========================================="
    echo "  CREATE CONFIGURATION AND SERVICE       "
    echo "========================================="
    echo -e "${NC}"

    # Check if unzip is installed, install if necessary
    if ! command -v unzip &> /dev/null; then
        echo -e "${YELLOW}Installing unzip...${NC}"
        apt update
        apt install -y unzip
    fi

    # Create folder and download Waterwall
    mkdir -p /root/waterwall
    cd /root/waterwall || exit

    echo -e "${YELLOW}Downloading Waterwall binary...${NC}"
    wget -O Waterwall-linux-64.zip https://github.com/radkesvat/WaterWall/releases/latest/download/Waterwall-linux-64.zip
    unzip Waterwall-linux-64.zip
    rm Waterwall-linux-64.zip
    mv Waterwall waterwall
    chmod +x /root/waterwall/waterwall

    # Download core.json
    echo -e "${YELLOW}Downloading core.json...${NC}"
    wget -O core.json https://raw.githubusercontent.com/mahdipatriot/waterwall/main/core.json

    # Select server type: Iran or Kharej
    echo -e "${YELLOW}Select server type:${NC}"
    echo -e "${CYAN}1. Iran${NC}"
    echo -e "${CYAN}2. Kharej${NC}"
    read -rp "$(echo -e ${CYAN})Enter your choice: $(echo -e ${NC})" server_type

    case $server_type in
        1)
            # Iran server configuration
            read -rp "$(echo -e ${CYAN})Enter secure password: $(echo -e ${NC})" passwd
            read -rp "$(echo -e ${CYAN})Enter Kharej server IP: $(echo -e ${NC})" inja_ip_kharej
            read -rp "$(echo -e ${CYAN})Enter ipv4 or ipv6: $(echo -e ${NC})" ip_version
            read -rp "$(echo -e ${CYAN})Enter SNI: $(echo -e ${NC})" inja_sni
            read -rp "$(echo -e ${CYAN})Enter worker count (8x your Iran Server cores): $(echo -e ${NC})" worker_count

            # Download and customize config.json for Iran server
            wget -O config.json https://raw.githubusercontent.com/mahdipatriot/waterwall/main/halfduplex_reverse_reality_iran
            sed -i "s/\$passwd/$passwd/g" config.json
            sed -i "s/\$inja_ip_kharej/$inja_ip_kharej/g" config.json
            sed -i "s/\$inja_sni/$inja_sni/g" config.json
            sed -i "s/\"workers\": 0,/\"workers\": $worker_count,/g" core.json
            ;;
        2)
            # Kharej server configuration
            read -rp "$(echo -e ${CYAN})Enter secure password: $(echo -e ${NC})" passwd
            read -rp "$(echo -e ${CYAN})Enter Iran server IP: $(echo -e ${NC})" inja_ip_server_iran
            read -rp "$(echo -e ${CYAN})Enter ipv4 or ipv6: $(echo -e ${NC})" ip_version
            read -rp "$(echo -e ${CYAN})Enter SNI: $(echo -e ${NC})" inja_sni
            read -rp "$(echo -e ${CYAN})Enter worker count (8x your Iran Server cores): $(echo -e ${NC})" worker_count

            # Download and customize config.json for Kharej server
            wget -O config.json https://raw.githubusercontent.com/mahdipatriot/waterwall/main/halfuplex_reverse_reality_kharej
            sed -i "s/\$passwd/$passwd/g" config.json
            sed -i "s/\$inja_ip_server_iran/$inja_ip_server_iran/g" config.json
            sed -i "s/\$inja_sni/$inja_sni/g" config.json
            sed -i "s/\"workers\": 0,/\"workers\": $worker_count,/g" core.json
            ;;
        *)
            echo -e "${RED}Invalid option. Exiting...${NC}"
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

    echo -e "${GREEN}Waterwall configuration and service setup complete.${NC}"
    echo -e "${CYAN}Systemd service status:${NC}"
    systemctl status waterwall --no-pager
    read -p "Press Enter to continue..."
}

# Function to remove Waterwall configuration and service
remove_waterwall_config() {
    echo -e "${RED}"
    echo "========================================="
    echo "  REMOVE CONFIGURATION AND SERVICE       "
    echo "========================================="
    echo -e "${NC}"

    # Stop and disable Waterwall service
    systemctl stop waterwall
    systemctl disable waterwall

    # Remove systemd service file
    rm -f /etc/systemd/system/waterwall.service

    # Remove Waterwall directory and files
    rm -rf /root/waterwall

    echo -e "${GREEN}Waterwall configuration and service removed.${NC}"
    read -p "Press Enter to continue..."
}

# Function to show Waterwall service status
show_service_status() {
    echo -e "${CYAN}"
    echo "========================================="
    echo "      SHOW SERVICE STATUS                "
    echo "========================================="
    echo -e "${NC}"

    systemctl status waterwall --no-pager

    read -p "Press Enter to continue..."
}

# Function to restart Waterwall service
restart_waterwall_service() {
    echo -e "${CYAN}"
    echo "========================================="
    echo "      RESTART WATERWALL SERVICE          "
    echo "========================================="
    echo -e "${NC}"

    systemctl restart waterwall

    echo -e "${GREEN}Waterwall service restarted.${NC}"
    read -p "Press Enter to continue..."
}

# Main menu function
main_menu() {
    while true; do
        clear
        echo -e "${GREEN}"
        echo "========================================="
        echo "   MahdiPatrioT waterwall MENU           "
        echo "========================================="
        echo -e "${NC}"

        echo -e "${GREEN}1. Create Configuration and Service${NC}"
        echo -e "${RED}2. Remove Configuration and Service${NC}"
        echo -e "${CYAN}3. Show Service Status${NC}"
        echo -e "${YELLOW}4. Restart Waterwall Service${NC}"
        echo -e "${CYAN}5. Exit${NC}"
        echo ""
        echo -e "${CYAN}GitHub: [mahdipatriot/waterwall](https://github.com/mahdipatriot/waterwall)${NC}"
        echo -e "${CYAN}Source: [radkesvat/WaterWall](https://github.com/radkesvat/WaterWall)${NC}"
        echo ""
        echo -n "Enter your choice: "
        read choice

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
                restart_waterwall_service
                ;;
            5)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Start the main menu
main_menu
