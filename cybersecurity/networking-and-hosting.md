# Networking & Hosting Guide

A practical guide to reverse proxies, HTTPS certificates, port-block workarounds, VPN and mesh networking, Dynamic DNS, comparisons, troubleshooting, and common networking terminology.

This guide is intended primarily for **self-hosting, homelabs, game servers, remote access, and small personal networks**.

---

## Table of Contents

* [Introduction](#introduction)
* [Understanding the Pieces](#understanding-the-pieces)
* [Docker SWAG and Let's Encrypt](#docker-swag-and-lets-encrypt)
* [Using DNS Validation](#using-dns-validation)
* [Port Eighty Workarounds with PageKite](#port-eighty-workarounds-with-pagekite)
* [VPN and Mesh Networking](#vpn-and-mesh-networking)
* [Radmin VPN](#radmin-vpn)
* [Hamachi](#hamachi)
* [Tailscale](#tailscale)
* [Tailscale Exit Nodes](#tailscale-exit-nodes)
* [NordVPN Meshnet](#nordvpn-meshnet)
* [VPN and Mesh Comparison](#vpn-and-mesh-comparison)
* [Dynamic DNS](#dynamic-dns)
* [Dynu](#dynu)
* [No-IP](#no-ip)
* [Dynamic DNS Comparison](#dynamic-dns-comparison)
* [Choosing the Right Solution](#choosing-the-right-solution)
* [Security Considerations](#security-considerations)
* [Troubleshooting](#troubleshooting)
* [Pros and Cons](#pros-and-cons)
* [Glossary](#glossary)

---

# Introduction

Running services from a home connection often requires several networking components working together.

A typical self-hosting setup might look like this:

```text
                         Internet
                             |
                             |
                     Public IP Address
                             |
                      Home Router
                             |
              +--------------+--------------+
              |                             |
           Port 443                      VPN / Mesh
              |                             |
              v                             v
        Reverse Proxy                 Remote Devices
          (SWAG)                       / Tailscale
              |
       +------+------+------+
       |      |      |      |
     Nextcloud Game   Web   Other
               Server Server Services
```

The individual technologies solve different problems:

| Technology          | Main purpose                                               |
| ------------------- | ---------------------------------------------------------- |
| **SWAG**            | Reverse proxy and HTTPS                                    |
| **Let's Encrypt**   | Free TLS/SSL certificates                                  |
| **DNS-01**          | Proves domain ownership through DNS                        |
| **PageKite**        | Tunnels inbound web traffic through an outbound connection |
| **Tailscale**       | Private mesh networking                                    |
| **Radmin VPN**      | Virtual LAN networking                                     |
| **Hamachi**         | Virtual LAN networking                                     |
| **NordVPN Meshnet** | Private device-to-device networking                        |
| **Dynu**            | Dynamic DNS                                                |
| **No-IP**           | Dynamic DNS                                                |

A common mistake is treating these technologies as interchangeable. They are not.

For example:

* **Dynamic DNS does not open ports.**
* **A reverse proxy does not replace a VPN.**
* **A VPN does not automatically provide a public website.**
* **A TLS certificate does not make an insecure application secure.**
* **An exit node is not automatically a commercial VPN server.**

---

# Understanding the Pieces

Before configuring anything, it helps to understand the difference between **DNS, port forwarding, reverse proxies, VPNs, and tunnels**.

## DNS

DNS translates a hostname into an IP address.

For example:

```text
cloud.example.com
        |
        v
203.0.113.50
```

DNS does **not** forward traffic to your computer.

If your ISP changes your public IP address, the DNS record needs to be updated.

This is where Dynamic DNS becomes useful.

---

## Port Forwarding

Port forwarding tells your router where incoming traffic should go.

Example:

```text
Internet
   |
   | TCP 443
   v
Router
   |
   | TCP 443
   v
192.168.1.100
```

For a typical HTTPS server:

```text
TCP 443 -> 192.168.1.100:443
```

For HTTP:

```text
TCP 80 -> 192.168.1.100:80
```

---

## Reverse Proxy

A reverse proxy accepts incoming connections and forwards them to internal services.

For example:

```text
https://cloud.example.com
            |
            v
        SWAG :443
            |
            v
   Nextcloud container :443/80
```

The reverse proxy can also handle:

* TLS certificates
* HTTP → HTTPS redirects
* multiple hostnames
* authentication
* access restrictions
* WebSocket proxying
* security headers

---

## VPN

A VPN creates an encrypted network connection between devices or networks.

Instead of exposing:

```text
RDP :3389
SSH :22
SMB :445
```

to the public Internet, you can connect through a private VPN and access the services through their private VPN addresses.

This can substantially reduce the number of publicly exposed services.

---

## Tunnel

A tunnel creates a connection from one network to another, often through an intermediary.

A useful property of some tunneling services is that the connection can be initiated **outbound** from your network.

That can help when:

* inbound port 80 is blocked
* inbound connections are unavailable
* you are behind certain NAT configurations

PageKite is an example of this type of technology.

---

# Docker SWAG and Let's Encrypt

[SWAG](https://docs.linuxserver.io/images/docker-swag/) stands for **Secure Web Application Gateway**.

It combines:

* Nginx
* reverse-proxy functionality
* Certbot
* Let's Encrypt/ZeroSSL support
* Fail2ban
* automated certificate management

LinuxServer currently recommends the `lscr.io/linuxserver/swag` image.

SWAG is particularly useful when hosting multiple services:

```text
cloud.example.com
mail.example.com
game.example.com
media.example.com
```

all through one public server.

---

## Basic SWAG Setup

A modern Compose configuration can look like this:

```yaml
services:
  swag:
    image: lscr.io/linuxserver/swag:latest
    container_name: swag

    cap_add:
      - NET_ADMIN

    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
      - URL=example.com
      - SUBDOMAINS=www,cloud
      - VALIDATION=http

    ports:
      - "80:80"
      - "443:443"

    volumes:
      - ./config:/config

    restart: unless-stopped
```

Adjust the following values:

```text
PUID
PGID
TZ
URL
SUBDOMAINS
```

to match your system.

---

## Router Configuration

If using HTTP validation, forward both ports:

```text
TCP 80  -> SWAG host :80
TCP 443 -> SWAG host :443
```

For example:

```text
Internet
   |
   +---- TCP 80 ----> 192.168.1.100:80
   |
   +---- TCP 443 ---> 192.168.1.100:443
```

SWAG's documentation specifically requires port 80 to be reachable from the Internet when using HTTP validation.

---

## DNS Configuration

Suppose your public IP is:

```text
203.0.113.50
```

You could create:

```text
example.com        A     203.0.113.50
cloud.example.com  A     203.0.113.50
```

Or use a CNAME:

```text
cloud.example.com  CNAME  example.com
```

Your exact DNS setup depends on your DNS provider.

---

## Start SWAG

From the directory containing `docker-compose.yml`:

```bash
docker compose up -d
```

Check the logs:

```bash
docker logs -f swag
```

Or:

```bash
docker compose logs -f swag
```

---

## Certificate Generation

On the first startup, SWAG will attempt to obtain the certificate.

With HTTP validation:

```text
Let's Encrypt
     |
     | HTTP challenge
     v
example.com:80
     |
     v
Router
     |
     v
SWAG
```

If validation succeeds, the certificate is stored inside:

```text
/config/etc/letsencrypt/
```

The exact certificate paths depend on the SWAG configuration.

---

## Automatic Renewal

You normally **do not need to create a custom `renew.sh` script**.

SWAG includes certificate management and automatically checks certificates for renewal. Current documentation states that certificates are checked regularly and renewed when appropriate.

Check the logs if renewal fails:

```bash
docker logs swag
```

and:

```text
config/log/letsencrypt/
```

---

# Using DNS Validation

DNS validation is often preferable when port 80 cannot be exposed.

Instead of Let's Encrypt connecting to:

```text
http://example.com/.well-known/acme-challenge/...
```

Let's Encrypt verifies a DNS record.

The basic process is:

```text
SWAG
 |
 | Create TXT record
 v
DNS Provider
 |
 | DNS lookup
 v
Let's Encrypt
```

SWAG supports many DNS providers through Certbot plugins.

---

## DNS Validation Advantages

DNS validation is particularly useful when:

* port 80 is blocked
* you do not want to expose port 80
* you need a wildcard certificate
* your service is not directly reachable from the Internet

Wildcard certificates are especially useful:

```text
*.example.com
```

which can cover:

```text
cloud.example.com
media.example.com
game.example.com
mail.example.com
```

---

## Example Cloudflare Configuration

A typical configuration looks like:

```yaml
environment:
  - URL=example.com
  - SUBDOMAINS=wildcard
  - VALIDATION=dns
  - DNSPLUGIN=cloudflare
```

The DNS provider credentials are then configured under:

```text
/config/dns-conf/
```

Do **not** put API tokens directly into a publicly committed GitHub repository.

Use a secret, protected environment file, or another secure credential mechanism.

---

## HTTP Validation vs DNS Validation

| Feature                       | HTTP-01 | DNS-01      |
| ----------------------------- | ------- | ----------- |
| Requires port 80              | Yes     | No          |
| Requires DNS API credentials  | No      | Usually yes |
| Wildcard certificates         | No      | Yes         |
| Simple setup                  | Yes     | Moderate    |
| Useful behind blocked port 80 | No      | Yes         |
| Requires DNS provider support | No      | Yes         |

### General rule

Use **HTTP validation** when you can easily expose port 80.

Use **DNS validation** when port 80 is unavailable or when you need wildcard certificates.

---

# Port Eighty Workarounds with PageKite

Some ISPs, networks, or hosting environments make inbound port 80 difficult or impossible to use.

One possible workaround is a tunneling service such as PageKite.

The basic concept is:

```text
Internet
    |
    v
PageKite
    |
    | outbound tunnel
    v
Your server
```

Instead of requiring a direct inbound connection to your machine, the local machine establishes an outbound connection.

---

## Installing PageKite

Download PageKite:

```bash
curl -O https://pagekite.net/pk/pagekite.py
```

Make it executable:

```bash
chmod +x pagekite.py
```

---

## Starting a Basic HTTP Kite

For a local web service listening on port 80:

```bash
./pagekite.py 80 yourname.pagekite.me
```

Replace:

```text
yourname
```

with the PageKite hostname you are using.

---

## Important Limitation

PageKite is a **tunneling service**, not a replacement for DNS, a VPN, or a reverse proxy.

A possible architecture is:

```text
Internet
    |
    v
PageKite
    |
    v
Local web server
    |
    v
Application
```

If you need a conventional public HTTPS service with your own domain and certificate, you should also consider whether your reverse-proxy and certificate architecture is appropriate.

---

## When PageKite Makes Sense

PageKite can be useful when:

* inbound port 80 is unavailable
* router configuration is limited
* you need temporary external access
* you want an outbound tunnel rather than inbound port forwarding

It is less attractive when you have:

* full router control
* a public IP
* working ports 80/443
* a normal reverse-proxy setup

In that situation, direct HTTPS through a reverse proxy is generally simpler.

---

# VPN and Mesh Networking

There are several ways to connect computers as though they were on the same private network.

This is particularly useful for:

* game servers
* remote administration
* SSH
* RDP
* file sharing
* development
* accessing home services
* private multiplayer sessions

---

# Radmin VPN

[Radmin VPN](https://www.radmin-vpn.com/) is a free virtual LAN product designed to connect computers across the Internet as though they were on a local network.

It is officially advertised as free software with 256-bit AES encryption.

A typical setup looks like:

```text
Computer A
     |
     | Internet
     |
Radmin VPN network
     |
     | Internet
     |
Computer B
```

---

## Basic Setup

Install Radmin VPN on each computer.

Create a network on one machine:

```text
Network name:
MyPrivateNetwork

Password:
<secure-password>
```

Join the network from the other machines.

The computers will receive virtual network addresses.

You can then use the virtual IP address for supported applications.

---

## Advantages

* Free
* Simple interface
* Designed for virtual LAN use
* Useful for games that expect LAN connectivity
* Supports Windows 10/11

---

## Disadvantages

* More Windows-focused than some alternatives
* Depends on Radmin's infrastructure
* Not self-hosted
* Less flexible than a general-purpose mesh networking solution

### Important correction

Radmin VPN should **not** be described as "self-hosted."

The software creates the virtual network, but the service itself is not equivalent to running your own VPN coordination infrastructure.

---

# Hamachi

[LogMeIn Hamachi](https://www.vpn.net/) provides virtual LAN networking.

It is commonly used for:

* multiplayer games
* remote LAN access
* small private networks
* legacy applications

---

## Basic Concept

```text
Computer A
    |
Hamachi
    |
Virtual LAN
    |
Hamachi
    |
Computer B
```

Applications can then communicate using the Hamachi-assigned address.

---

## Advantages

* Mature product
* Easy GUI
* Widely recognized
* Useful for LAN-style applications
* Cross-platform support exists, although features can vary by platform

---

## Disadvantages

* Free usage is limited compared with completely unrestricted alternatives
* Requires a third-party service
* Can introduce additional latency
* Some older applications may behave unpredictably over virtual adapters

---

# Tailscale

Tailscale is a mesh VPN based on WireGuard.

Instead of manually configuring:

```text
Port forwarding
Static routes
Firewall rules
VPN servers
```

Tailscale can create a private network between participating devices.

Example:

```text
          Tailscale Network
        /        |         \
       /         |          \
 Windows       Linux       Phone
 PC             Server
       \         |          /
        \        |         /
          Private Mesh
```

---

## Basic Installation

Install Tailscale on each device and authenticate them to the same tailnet.

After joining, devices receive Tailscale addresses, commonly in the:

```text
100.x.x.x
```

range.

You can then access services using their Tailscale IP addresses.

For example:

```bash
ssh user@100.x.x.x
```

---

## Why Tailscale Is Useful for Self-Hosting

Instead of exposing:

```text
SSH :22
RDP :3389
SMB :445
```

to the public Internet, you can keep them private and access them over Tailscale.

This can be especially useful for:

* homelabs
* NAS systems
* SSH
* RDP
* development machines
* remote administration

---

# Tailscale Exit Nodes

An **exit node** allows a Tailscale client to route its general Internet traffic through another device.

For example:

```text
Laptop
   |
   | Tailscale
   v
Home Server
   |
   | Normal Internet connection
   v
Internet
```

Tailscale explicitly describes an exit node as a device that routes non-Tailscale traffic for other devices.

---

## Important: Exit Node vs NordVPN

A common misconception is:

```text
Tailscale + NordVPN = NordVPN exit node
```

This is not automatically true.

A Tailscale exit node is normally **another device that you control**.

For example:

```text
Laptop
   |
Tailscale
   |
Home Server
   |
Home ISP
   |
Internet
```

The public IP would normally be the home server's Internet connection.

To use a commercial VPN connection as the exit path, the machine acting as the exit node would need to be configured appropriately so its Internet traffic is routed through that VPN.

---

## Enabling a Linux Exit Node

Tailscale's current documentation requires IP forwarding on Linux.

For systems using `/etc/sysctl.d/`:

```bash
echo 'net.ipv4.ip_forward = 1' | \
sudo tee -a /etc/sysctl.d/99-tailscale.conf

echo 'net.ipv6.conf.all.forwarding = 1' | \
sudo tee -a /etc/sysctl.d/99-tailscale.conf

sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
```

Then advertise the machine as an exit node using Tailscale.

The exact approval and ACL requirements depend on your tailnet configuration.

---

## Using an Exit Node

On a Linux client:

```bash
sudo tailscale set --exit-node=<exit-node-ip>
```

To allow local LAN access:

```bash
sudo tailscale set \
  --exit-node=<exit-node-ip> \
  --exit-node-allow-lan-access=true
```

To stop using the exit node:

```bash
sudo tailscale set --exit-node=
```

---

# NordVPN Meshnet

NordVPN Meshnet provides a private network between devices.

NordVPN currently describes Meshnet as a feature that allows devices to connect privately, access devices remotely, transfer files, and route traffic through another device.

A simple example:

```text
PC
 |
 +---- Meshnet ---- Laptop
 |
 +---- Meshnet ---- Phone
```

---

## Meshnet vs Normal NordVPN

These are different concepts.

### Normal NordVPN connection

```text
Your PC
   |
NordVPN server
   |
Internet
```

### Meshnet

```text
Your PC
   |
Private Meshnet
   |
Your other device
```

Meshnet is therefore more comparable to a mesh VPN than to simply connecting to a conventional VPN server.

---

# VPN and Mesh Comparison

| Feature                     | Radmin VPN         | Hamachi                 | Tailscale                  | NordVPN Meshnet                     |
| --------------------------- | ------------------ | ----------------------- | -------------------------- | ----------------------------------- |
| Primary purpose             | Virtual LAN        | Virtual LAN             | Mesh VPN                   | Private device mesh                 |
| WireGuard                   | No                 | No                      | Yes                        | Uses NordVPN technology             |
| Easy GUI                    | Yes                | Yes                     | Yes                        | Yes                                 |
| Self-hosted                 | No                 | No                      | Coordination is hosted     | No                                  |
| Remote administration       | Good               | Good                    | Excellent                  | Good                                |
| Gaming/LAN use              | Good               | Good                    | Good                       | Good                                |
| Subnet routing              | Limited            | Limited                 | Yes                        | Limited                             |
| Exit-node capability        | No                 | No                      | Yes                        | Yes, via supported routing features |
| Public web hosting          | No                 | No                      | No                         | No                                  |
| Port forwarding replacement | Often              | Often                   | Often                      | Often                               |
| Best suited for             | Simple virtual LAN | Legacy/LAN applications | Homelabs and remote access | Nord ecosystem users                |

---

# Dynamic DNS

Dynamic DNS, or **DDNS**, solves a different problem from VPNs.

Suppose your ISP assigns:

```text
203.0.113.50
```

today.

Tomorrow it might change to:

```text
203.0.113.72
```

Without DDNS:

```text
example.com -> old IP
```

With DDNS:

```text
example.com -> updated IP
```

A DDNS client detects the change and updates the DNS record.

---

## How DDNS Works

```text
Home Router
     |
     | Detects public IP
     v
DDNS Client
     |
     | Update
     v
DDNS Provider
     |
     v
hostname.example.com
```

---

## DDNS Does Not Solve NAT

This is important.

DDNS does **not** automatically make a server reachable.

You may still need:

* port forwarding
* firewall rules
* a public IP
* IPv6 configuration
* a tunnel
* or a VPN/mesh solution

For example:

```text
DDNS
  |
  v
example.ddns.net
  |
  v
Public IP
  |
  X
Port blocked
```

The hostname resolves correctly, but the service is still unreachable.

---

# Dynu

[Dynu](https://www.dynu.com/) provides Dynamic DNS and related DNS services.

Dynu currently offers a free Dynamic DNS service and states that its free service does not expire simply because the account is free.

It can be useful for:

* home servers
* game servers
* remote administration
* self-hosting
* changing residential IP addresses

---

## Basic Dynu Workflow

Create a Dynu hostname, for example:

```text
myserver.dynu.net
```

Configure a Dynamic DNS client or router to update the hostname.

Then:

```text
myserver.dynu.net
        |
        v
Current public IP
```

---

# No-IP

[No-IP](https://www.noip.com/) also provides Dynamic DNS.

Its current free plan provides a hostname and dynamic DNS updates, but free hostnames must be confirmed every 30 days.

---

## Basic No-IP Workflow

Create a hostname:

```text
myserver.ddns.net
```

Install the No-IP Dynamic Update Client or configure your router if supported.

The client keeps the hostname synchronized with your public IP.

---

# Dynamic DNS Comparison

| Feature                      | Dynu                                 | No-IP                          |
| ---------------------------- | ------------------------------------ | ------------------------------ |
| Free plan                    | Yes                                  | Yes                            |
| Free service expiration      | No account expiration                | Hostname requires confirmation |
| Dynamic updates              | Yes                                  | Yes                            |
| Custom domains               | Supported with appropriate DNS setup | Depends on plan                |
| Router support               | Depends on router                    | Widely supported               |
| Good for homelabs            | Yes                                  | Yes                            |
| Good for basic remote access | Yes                                  | Yes                            |

No-IP's current free service is limited to **one hostname** and requires confirmation every 30 days.

Dynu's free service has fewer of those account-maintenance restrictions, although its exact hostname and DNS-record limits depend on the account level.

---

# Choosing the Right Solution

The easiest way to choose a technology is to start with the problem rather than the product.

## I Want to Host a Website

Use:

```text
Domain
  |
DNS
  |
Router
  |
SWAG
  |
Application
```

Recommended components:

* DNS
* Port forwarding
* SWAG
* Let's Encrypt

---

## My ISP Blocks Port Eighty

Consider:

```text
DNS validation
```

for certificates.

If you also need to expose a web service without normal inbound connectivity, consider a tunneling service such as PageKite.

---

## I Want Private Remote Access

Use:

```text
Tailscale
```

or another VPN/mesh VPN.

Example:

```text
Laptop
   |
Tailscale
   |
Home Server
```

No public SSH/RDP port is necessarily required.

---

## I Want to Play a LAN Game With Friends

Consider:

```text
Radmin VPN
Hamachi
Tailscale
NordVPN Meshnet
```

The correct choice depends on the game and operating systems involved.

---

## I Have a Changing Public IP

Use:

```text
Dynamic DNS
```

Examples:

```text
Dynu
No-IP
```

---

## I Want to Hide My Home Services From the Public Internet

A mesh VPN is often preferable:

```text
Internet
   |
Tailscale
   |
Private Service
```

instead of:

```text
Internet
   |
Port 3389
   |
RDP
```

---

# Security Considerations

## Do Not Expose Services Unnecessarily

Avoid exposing administrative services directly to the Internet unless there is a specific reason.

Examples include:

```text
SSH
RDP
SMB
database ports
Docker APIs
management interfaces
```

Prefer:

```text
VPN
+
private service
```

where practical.

---

## Use HTTPS

For public web applications:

```text
HTTP
 |
 v
HTTPS
```

Use a trusted certificate authority such as Let's Encrypt.

---

## Protect DNS API Credentials

Never commit credentials such as:

```text
Cloudflare API tokens
Dynu credentials
DNS provider passwords
VPN credentials
```

to GitHub.

Use:

```text
.env
```

and add it to:

```text
.gitignore
```

For example:

```gitignore
.env
*.secret
secrets/
```

---

## Use Least-Privilege API Tokens

If your DNS provider supports scoped API tokens, give the token only the permissions it needs.

For example:

```text
DNS zone read
DNS record edit
```

is preferable to:

```text
Full account administration
```

---

## Check Your Firewall

A working port forward does not mean the service is secure.

Check:

```text
Router firewall
Host firewall
Docker firewall/network
Application authentication
Reverse proxy configuration
```

---

# Troubleshooting

## SWAG Certificate Fails

Check:

```bash
docker logs swag
```

Look for:

```text
challenge
DNS
connection
certificate
```

Also verify:

```text
DNS -> correct public IP
```

For HTTP validation:

```text
TCP 80 -> SWAG
TCP 443 -> SWAG
```

For DNS validation:

```text
DNS API credentials
DNSPLUGIN
DNS propagation
```

SWAG's logs under `/config/log/letsencrypt` are particularly useful when certificate renewal fails.

---

## Port 80 Is Blocked

First determine whether the problem is:

```text
ISP blocking
Router configuration
Firewall
CGNAT
Incorrect port forwarding
```

If HTTP validation cannot work, switch to:

```text
DNS-01
```

for certificate issuance.

If the web service itself cannot accept inbound connections, consider a tunnel.

---

## DDNS Is Updating but the Server Is Still Unreachable

Check these separately:

```text
1. Does DNS resolve correctly?
2. Is the public IP correct?
3. Is the port forwarded?
4. Is the host firewall allowing it?
5. Is the service listening?
6. Is the ISP blocking the port?
7. Are you behind CGNAT?
```

A successful DNS lookup does not prove that the service is reachable.

---

## Tailscale Device Cannot Connect

Check:

```bash
tailscale status
```

Verify:

* both devices are logged into the expected tailnet
* both devices are online
* firewall rules allow the application
* the service is listening on the expected interface
* ACL/grant rules permit the connection

---

## Tailscale Exit Node Does Not Work

Check:

```text
IP forwarding
Exit-node advertisement
Admin approval
ACL/grant rules
Client exit-node selection
```

Tailscale's current documentation also notes that exit-node use requires the client to explicitly opt in, and the tailnet configuration may need to grant Internet-routing permission.

---

## Radmin VPN Peer Is Not Reachable

Check:

* both clients are online
* both machines are connected to the same Radmin network
* Windows Firewall is not blocking the application
* the application is listening on the Radmin adapter
* the game/service supports virtual LAN adapters

Do not blindly disable Windows Firewall permanently.

Instead, create an appropriate firewall rule when possible.

---

## Hamachi Has High Latency

Possible causes include:

* relay connections
* NAT configuration
* Wi-Fi congestion
* ISP routing
* virtual adapter issues
* overloaded endpoints

Test direct connectivity and compare it with a normal Internet connection.

---

## No-IP Hostname Stopped Working

For free No-IP hostnames, check whether the hostname needs its periodic confirmation.

Free hostnames currently require confirmation every 30 days.

---

# Pros and Cons

## SWAG

### Pros

* Free and open-source container image
* Nginx reverse proxy
* Automatic certificate management
* Let's Encrypt support
* DNS validation support
* Wildcard certificate support
* Fail2ban integration
* Excellent fit for Docker homelabs

### Cons

* Requires some Nginx knowledge for advanced configurations
* Initial configuration can be intimidating
* Incorrect proxy configuration can cause confusing errors
* Public services still need to be secured individually

---

## PageKite

### Pros

* Can work through restrictive inbound networks
* Uses outbound connectivity
* Useful for temporary or unusual hosting environments
* Avoids some router configuration requirements

### Cons

* Adds a third-party intermediary
* Adds another dependency
* Can add latency
* Not necessary for normal public hosting when ports 80/443 work
* Does not replace a reverse proxy or VPN

---

## Radmin VPN

### Pros

* Free
* Simple
* Easy virtual LAN experience
* Useful for gaming
* Low configuration overhead

### Cons

* Not self-hosted
* More limited than a general-purpose mesh VPN
* Primarily aimed at virtual LAN use
* Windows-focused

---

## Hamachi

### Pros

* Mature
* Easy to configure
* Familiar to many gamers
* Useful for virtual LAN applications

### Cons

* Free usage is limited
* Third-party dependency
* Performance can vary
* Less flexible than modern mesh VPN solutions

---

## Tailscale

### Pros

* WireGuard-based
* Excellent for homelabs
* Easy device enrollment
* NAT traversal
* Private addressing
* Exit nodes
* Subnet routers
* Tailscale SSH
* Good cross-platform support

### Cons

* Depends on Tailscale's coordination infrastructure for the normal hosted setup
* Advanced ACL configuration requires learning Tailscale concepts
* Some advanced features depend on plan level
* Not intended to replace a public reverse proxy

---

## NordVPN Meshnet

### Pros

* Easy for existing NordVPN users
* Private device networking
* Remote access
* Traffic routing capabilities
* File-transfer capabilities

### Cons

* Tied to the NordVPN ecosystem
* Less flexible than a dedicated self-hosted networking stack
* Not a replacement for a public reverse proxy
* Troubleshooting is more dependent on the provider's software

NordVPN currently documents Meshnet as a private device-networking feature and continues to provide Meshnet configuration documentation.

---

## Dynu

### Pros

* Free tier
* No requirement for a paid subscription for basic DDNS
* Dynamic DNS support
* Useful for homelabs
* API available

### Cons

* Advanced DNS features may require a paid membership
* Requires client/router configuration
* Does not provide connectivity by itself

---

## No-IP

### Pros

* Long-established service
* Easy setup
* Widely supported by routers
* Free Dynamic DNS option
* Dynamic Update Client

### Cons

* Free plan is limited to one hostname
* Free hostname requires confirmation every 30 days
* Some advanced DNS functionality requires paid services

---

# Overall Comparison

| Solution        | Main Job      | Public Hosting | Private Access | DDNS |   Tunnel | Difficulty  |
| --------------- | ------------- | -------------: | -------------: | ---: | -------: | ----------- |
| SWAG            | Reverse proxy |            Yes |             No |   No |       No | Medium      |
| Let's Encrypt   | Certificates  |            Yes |             No |   No |       No | Easy–Medium |
| PageKite        | Tunnel        |            Yes |        Limited |   No |      Yes | Easy        |
| Radmin VPN      | Virtual LAN   |             No |            Yes |   No |  Yes-ish | Easy        |
| Hamachi         | Virtual LAN   |             No |            Yes |   No |  Yes-ish | Easy        |
| Tailscale       | Mesh VPN      |             No |            Yes |   No | VPN mesh | Easy–Medium |
| NordVPN Meshnet | Device mesh   |             No |            Yes |   No |     Mesh | Easy        |
| Dynu            | DDNS          |     Indirectly |             No |  Yes |       No | Easy        |
| No-IP           | DDNS          |     Indirectly |             No |  Yes |       No | Easy        |

---

# Example Self-Hosting Architectures

## Public Website

```text
Internet
   |
   | HTTPS :443
   v
Router
   |
   v
SWAG
   |
   +---- Nextcloud
   |
   +---- Jellyfin
   |
   +---- Website
   |
   +---- Other services
```

---

## Private Homelab

```text
Internet
   |
   v
Tailscale
   |
   +---- Desktop
   |
   +---- Laptop
   |
   +---- Server
   |
   +---- Phone
```

No public service ports are required for the private services.

---

## Public Website + Private Administration

This is often a useful hybrid design:

```text
                    Internet
                       |
                      :443
                       |
                     SWAG
                       |
              +--------+--------+
              |                 |
          Public Web        Public App
              
                      

Private Administration
         |
      Tailscale
         |
   +-----+------+
   |            |
 Server       Desktop
```

The public-facing applications use HTTPS, while administration services remain accessible only through the VPN.

---

## Dynamic IP + Public Website

```text
ISP
 |
 | Dynamic public IP
 v
Router
 |
 +---- DDNS updater
 |        |
 |        v
 |   example.dynu.net
 |
 +---- TCP 443
          |
          v
         SWAG
          |
          v
       Services
```

---

# Glossary

## ACME

**Automatic Certificate Management Environment.**

The protocol used by certificate authorities such as Let's Encrypt to automate certificate issuance and renewal.

---

## ACL

**Access Control List.**

A set of rules defining which devices or users can communicate with which resources.

---

## CNAME

A DNS record that aliases one hostname to another hostname.

Example:

```text
cloud.example.com -> example.com
```

---

## CGNAT

**Carrier-Grade NAT.**

A system where an ISP places multiple customers behind shared public IP addresses.

CGNAT can prevent traditional inbound port forwarding.

---

## DDNS

**Dynamic DNS.**

A service that automatically updates a hostname when your public IP changes.

---

## DNS

**Domain Name System.**

The system that translates names such as:

```text
example.com
```

into addresses such as:

```text
203.0.113.50
```

---

## DNS-01

An ACME certificate validation method that proves domain ownership through a DNS TXT record.

It can be used to obtain wildcard certificates.

---

## Exit Node

A device that routes another device's Internet traffic through itself.

Example:

```text
Laptop -> Tailscale -> Home Server -> Internet
```

---

## HTTP-01

An ACME certificate validation method where the certificate authority accesses a challenge over HTTP.

It normally requires port 80 to be reachable.

---

## HTTPS

**HTTP Secure.**

HTTP traffic protected by TLS.

Normally uses:

```text
TCP 443
```

---

## ISP

**Internet Service Provider.**

The company providing your Internet connection.

Examples include cable, fiber, DSL, and cellular providers.

---

## Mesh VPN

A VPN architecture where devices can communicate directly with one another instead of requiring all traffic to pass through a central VPN server.

---

## NAT

**Network Address Translation.**

A technology that allows private IP addresses to communicate through a public IP address.

---

## Port Forwarding

A router rule that forwards incoming traffic from the public Internet to a device on the private network.

---

## Reverse Proxy

A server that accepts incoming requests and forwards them to backend applications.

---

## SWAG

**Secure Web Application Gateway.**

The LinuxServer container providing Nginx, reverse-proxy functionality, certificate management, and additional security tooling.

---

## TLS

**Transport Layer Security.**

The encryption protocol used by HTTPS.

---

## Tailnet

The private network created by Tailscale.

---

## Tunnel

A network connection that encapsulates traffic and transports it through another connection or service.

---

## VPN

**Virtual Private Network.**

A technology that creates an encrypted network connection between systems or networks.

---

## Wildcard Certificate

A TLS certificate that covers multiple subdomains.

Example:

```text
*.example.com
```

can cover:

```text
cloud.example.com
media.example.com
game.example.com
```

---

# Final Recommendations

For a typical modern homelab, these technologies work well together rather than competing directly:

```text
                     Internet
                        |
                    Dynamic DNS
                        |
                    Router :443
                        |
                      SWAG
                        |
       +----------------+----------------+
       |                |                |
   Nextcloud         Website          Other Apps
       
       
       Private administration
                 |
              Tailscale
                 |
        +--------+--------+
        |        |        |
      Server    PC      Laptop
```

A practical division of responsibilities is:

| Requirement                             | Technology                       |
| --------------------------------------- | -------------------------------- |
| Public HTTPS                            | SWAG                             |
| TLS certificates                        | Let's Encrypt                    |
| Wildcard certificates                   | DNS-01                           |
| Dynamic public IP                       | Dynu / No-IP                     |
| Private remote access                   | Tailscale                        |
| Virtual LAN gaming                      | Radmin VPN / Hamachi / Tailscale |
| Private device mesh                     | Tailscale / NordVPN Meshnet      |
| Internet traffic through another device | Tailscale Exit Node              |
| Restricted inbound connectivity         | Tunnel such as PageKite          |

The most important concept is to **use each technology for the problem it is designed to solve**. DDNS, reverse proxies, VPNs, tunnels, and certificates complement one another; they generally do not replace one another.

---

## Useful Official Documentation

* [LinuxServer SWAG Documentation](https://docs.linuxserver.io/images/docker-swag/)
* [Tailscale Exit Nodes Documentation](https://tailscale.com/docs/features/exit-nodes)
* [Tailscale Exit Node Setup](https://tailscale.com/docs/features/exit-nodes/how-to/setup)
* [Radmin VPN](https://www.radmin-vpn.com/)
* [NordVPN Meshnet Documentation](https://support.nordvpn.com/hc/en-us/articles/20278389297041-Guide-for-Meshnet-users)
* [Dynu](https://www.dynu.com/)
* [No-IP](https://www.noip.com/)
* [PageKite](https://pagekite.net/)

---

**Happy self-hosting!**
