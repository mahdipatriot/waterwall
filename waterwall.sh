#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\e[36m'
NC='\033[0m' # No Color

# Ensure unzip is installed
if ! command -v unzip &> /dev/null; then
    echo -e "${YELLOW}unzip not found, installing...${NC}"
    apt update
    apt install -y unzip
fi

# Create /root/waterwall directory
mkdir -p /root/waterwall
cd /root/waterwall

# Download the latest Waterwall zip file
echo -e "${CYAN}Downloading the latest Waterwall zip file...${NC}"
wget -O Waterwall-linux-64.zip https://github.com/radkesvat/WaterWall/releases/latest/download/Waterwall-linux-64.zip

# Unzip the downloaded file
echo -e "${CYAN}Unzipping the file...${NC}"
unzip Waterwall-linux-64.zip
rm Waterwall-linux-64.zip
mv Waterwall waterwall

# Create core.json
cat <<EOF > core.json
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

# Ask if the server is Iran or Kharej
while true; do
    echo -e "${YELLOW}"
    echo "Is this an Iran server or Kharej server? (Iran/Kharej): "
    read server_type
    server_type=$(echo "$server_type" | tr '[:upper:]' '[:lower:]')

    if [[ "$server_type" == "iran" ]]; then
        read -sp "Enter a secure password: " secure_password
        echo
        read -p "Enter Kharej server IP: " kharej_server_ip
        read -p "Is the Kharej server IP IPv6 or IPv4? (IPv6/IPv4): " ip_version

        cat <<EOF > config.json
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
        break
    elif [[ "$server_type" == "kharej" ]]; then
        read -sp "Enter a secure password: " secure_password
        echo
        read -p "Enter Iran server IP: " iran_server_ip

        cat <<EOF > config.json
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
                "sni": "sahab.ir",
                "password": "$secure_password"
            },
            "next": "outbound_to_iran"
        },
        {
            "name": "outbound_to_iran",
            "type": "TcpConnector",
            "settings": {
                "nodelay": true,
                "address": "$iran_server_ip",
                "port": 443
            }
        }
    ]
}
EOF
        break
    else
        echo -e "${RED}Invalid input. Please specify 'Iran' or 'Kharej'.${NC}"
    fi
done

# Create systemd service
cat <<EOF > /etc/systemd/system/waterwall.service
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

# Enable and start the service
systemctl daemon-reload
systemctl enable waterwall.service
systemctl start waterwall.service

# Check the status of the service
if systemctl is-active --quiet waterwall.service; then
    echo -e "${GREEN}Waterwall service is running successfully.${NC}"
else
    echo -e "${RED}Waterwall service failed to start. Please check the logs for details.${NC}"
fi

echo -e "${CYAN}Configuration completed.${NC}"
