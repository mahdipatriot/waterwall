#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\e[36m'
NC='\033[0m' # No Color

# Directories and files
WATERWALL_DIR="/root/waterwall"
SERVICE_FILE="/etc/systemd/system/waterwall.service"

# Function to create a new configuration and service for Half Duplex Reverse Reality with mux
create_half_duplex_reverse_reality() {
    echo -e "${YELLOW}"
    echo "========================================="
    echo "  CREATE HALF DUPLEX REVERSE REALITY     "
    echo "========================================="
    echo -e "${NC}"

    echo "Downloading the latest Waterwall zip file..."
    wget -O Waterwall-linux-64.zip https://github.com/radkesvat/WaterWall/releases/latest/download/Waterwall-linux-64.zip

    echo "Unzipping the file..."
    unzip Waterwall-linux-64.zip -d $WATERWALL_DIR
    rm Waterwall-linux-64.zip
    mv $WATERWALL_DIR/Waterwall $WATERWALL_DIR/waterwall
    chmod +x $WATERWALL_DIR/waterwall

    cat <<EOF > $WATERWALL_DIR/core.json
{
    "log": {
        "path": "log/",
        "core": {
            "loglevel": "DEBUG",
            "file": "core.log",
            "console": true
        },
        "network": {
            "loglevel": "DEBUG",
            "file": "network.log",
            "console": true
        },
        "dns": {
            "loglevel": "SILENT",
            "file": "dns.log",
            "console": false
        }
    },
    "dns": {},
    "misc": {
        "workers": 0,
        "ram-profile": "server",
        "libs-path": "libs/"
    },
    "configs": [
        "config.json"
    ]
}
EOF

    echo -e -n "${CYAN}Is this an Iran server or Kharej server? (Iran/Kharej): ${NC}"
    read server_type
    server_type=$(echo "$server_type" | tr '[:upper:]' '[:lower:]')

    if [[ "$server_type" == "iran" ]]; then
        echo -e -n "${CYAN}Enter a secure password: ${NC}"
        read -s secure_password
        echo
        echo -e -n "${CYAN}Enter Kharej server IP: ${NC}"
        read kharej_server_ip

        cat <<EOF > $WATERWALL_DIR/config.json
{
    "name": "reverse_reality_grpc_hd_multiport_server",
    "nodes": [
        {
            "name": "users_inbound",
            "type": "TcpListener",
            "settings": {
                "address": "0.0.0.0",
                "port": [23,65500],
                "nodelay": true
            },
            "next": "header"
        },
        {
            "name": "header",
            "type": "HeaderClient",
            "settings": {
                "data": "src_context->port"
            },
            "next": "bridge2"
        },
        {
            "name": "bridge2",
            "type": "Bridge",
            "settings": {
                "pair": "bridge1"
            }
        },
        {
            "name": "bridge1",
            "type": "Bridge",
            "settings": {
                "pair": "bridge2"
            }
        },
        {
            "name": "reverse_server",
            "type": "ReverseServer",
            "settings": {},
            "next": "bridge1"
        },
        {
            "name": "pbserver",
            "type": "ProtoBufServer",
            "settings": {},
            "next": "reverse_server"
        },
        {
            "name": "h2server",
            "type": "Http2Server",
            "settings": {},
            "next": "pbserver"
        },
        {
            "name": "halfs",
            "type": "HalfDuplexServer",
            "settings": {},
            "next": "h2server"
        },
        {
            "name": "reality_server",
            "type": "RealityServer",
            "settings": {
                "destination": "reality_dest",
                "password": "$secure_password"
            },
            "next": "halfs"
        },
        {
            "name": "kharej_inbound",
            "type": "TcpListener",
            "settings": {
                "address": "0.0.0.0",
                "port": 443,
                "nodelay": true,
                "whitelist": [
                    "$kharej_server_ip/32"
                ]
            },
            "next": "reality_server"
        },
        {
            "name": "reality_dest",
            "type": "TcpConnector",
            "settings": {
                "nodelay": true,
                "address": "telewebion.com",
                "port": 443
            }
        }
    ]
}
EOF
    elif [[ "$server_type" == "kharej" ]]; then
        echo -e -n "${CYAN}Enter a secure password: ${NC}"
        read -s secure_password
        echo
        echo -e -n "${CYAN}Enter Iran server IP: ${NC}"
        read iran_server_ip

        cat <<EOF > $WATERWALL_DIR/config.json
{
    "name": "reverse_reality_grpc_client_hd_multiport_client",
    "nodes": [
        {
            "name": "outbound_to_core",
            "type": "TcpConnector",
            "settings": {
                "nodelay": true,
                "address": "127.0.0.1",
                "port": "dest_context->port"
            }
        },
        {
            "name": "header",
            "type": "HeaderServer",
            "settings": {
                "override": "dest_context->port"
            },
            "next": "outbound_to_core"
        },
        {
            "name": "bridge1",
            "type": "Bridge",
            "settings": {
                "pair": "bridge2"
            },
            "next": "header"
        },
        {
            "name": "bridge2",
            "type": "Bridge",
            "settings": {
                "pair": "bridge1"
            },
            "next": "reverse_client"
        },
        {
            "name": "reverse_client",
            "type": "ReverseClient",
            "settings": {
                "minimum-unused": 16
            },
            "next": "pbclient"
        },
        {
            "name": "pbclient",
            "type": "ProtoBufClient",
            "settings": {},
            "next": "h2client"
        },
        {
            "name": "h2client",
            "type": "Http2Client",
            "settings": {
                "host": "sahab.ir",
                "port": 443,
                "path": "/",
                "content-type": "application/grpc",
                "concurrency": 64
            },
            "next": "halfc"
        },
        {
            "name": "halfc",
            "type": "HalfDuplexClient",
            "next": "reality_client"
        },
        {
            "name": "reality_client",
            "type": "RealityClient",
            "settings": {
                "destination": "reality_dest",
                "password": "$secure_password"
            },
            "next": "halfc"
        },
        {
            "name": "iran_outbound",
            "type": "TcpListener",
            "settings": {
                "address": "0.0.0.0",
                "port": 23,
                "nodelay": true,
                "whitelist": [
                    "$iran_server_ip/32"
                ]
            },
            "next": "reality_client"
        },
        {
            "name": "reality_dest",
            "type": "TcpConnector",
            "settings": {
                "nodelay": true,
                "address": "telewebion.com",
                "port": 443
            }
        }
    ]
}
EOF
    else
        echo -e "${RED}Invalid input. Please enter 'Iran' or 'Kharej'.${NC}"
        return
    fi

    # Create the systemd service file
    cat <<EOF > $SERVICE_FILE
[Unit]
Description=Waterwall Service
After=network.target

[Service]
ExecStart=$WATERWALL_DIR/waterwall $WATERWALL_DIR/core.json
WorkingDirectory=$WATERWALL_DIR
StandardOutput=journal
StandardError=journal
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

    # Enable and start the service
    systemctl daemon-reload
    systemctl enable waterwall.service
    systemctl start waterwall.service

    echo -e "${GREEN}Configuration and service created. (ipv6 is not added yet)${NC}"
    read -p "Press Enter to continue..."
}

# Function to remove the configuration and service
remove_config_service() {
    echo -e "${RED}"
    echo "========================================="
    echo "      REMOVE CONFIGURATION & SERVICE      "
    echo "========================================="
    echo -e "${NC}"

    echo -e -n "${YELLOW}Are you sure you want to remove the Waterwall configuration and service? (yes/no): ${NC}"
    read confirm_remove

    if [[ "$confirm_remove" == "yes" ]]; then
        systemctl stop waterwall.service
        systemctl disable waterwall.service
        rm -rf $WATERWALL_DIR
        rm $SERVICE_FILE

        echo -e "${GREEN}Waterwall configuration and service removed.${NC}"
    else
        echo -e "${YELLOW}Removal cancelled.${NC}"
    fi

    read -p "Press Enter to continue..."
}

# Main menu loop
while true; do
    clear
    echo -e "${CYAN}"
    echo "========================================="
    echo "          WATERWALL CONFIGURATION         "
    echo "========================================="
    echo -e "${NC}"
    echo "1. Create Half Duplex Reverse Reality Configuration"
    echo "2. Remove Waterwall Configuration and Service"
    echo "3. Exit"

    echo -e -n "${YELLOW}Enter your choice (1-3): ${NC}"
    read choice

    case $choice in
        1) create_half_duplex_reverse_reality ;;
        2) remove_config_service ;;
        3) exit ;;
        *) echo -e "${RED}Invalid choice. Please enter a number from 1 to 3.${NC}" ;;
    esac
done
