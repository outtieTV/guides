# Privacy, Security & Anonymity Guide

> **Goal:** Reduce the amount of information that companies, websites, advertisers, network operators, malicious software, and other third parties can collect or use to identify you.
>
> **Important:** Privacy, security, and anonymity are different things. No tool can guarantee complete anonymity. The goal of this guide is to reduce unnecessary exposure and make tracking or identification more difficult.

---

## Table of Contents

* [1. Privacy, Security, and Anonymity](#1-privacy-security-and-anonymity)
* [2. Start With Your Threat Model](#2-start-with-your-threat-model)
* [3. How You Can Be Identified](#3-how-you-can-be-identified)
* [4. Network Privacy](#4-network-privacy)
* [5. Browser Privacy](#5-browser-privacy)
* [6. Accounts and Online Identity](#6-accounts-and-online-identity)
* [7. Operating System Privacy](#7-operating-system-privacy)
* [8. Search, Email, and Communication](#8-search-email-and-communication)
* [9. Cloud Storage and Personal Data](#9-cloud-storage-and-personal-data)
* [10. File and Device Encryption](#10-file-and-device-encryption)
* [11. Tor and Anonymity](#11-tor-and-anonymity)
* [12. Self-Hosting](#12-self-hosting)
* [13. Privacy-Friendly Software](#13-privacy-friendly-software)
* [14. Things That Can De-Anonymize You](#14-things-that-can-de-anonymize-you)
* [15. Common Mistakes](#15-common-mistakes)
* [16. Practical Privacy Checklist](#16-practical-privacy-checklist)
* [17. Suggested Privacy Levels](#17-suggested-privacy-levels)
* [18. Further Reading](#18-further-reading)

---

# 1. Privacy, Security, and Anonymity

These terms are related, but they describe different goals.

### Privacy

**Privacy** means controlling who can collect, access, or use information about you.

Examples:

* Preventing websites from tracking you.
* Preventing your ISP from seeing the contents of HTTPS traffic.
* Keeping personal files out of advertising ecosystems.
* Avoiding unnecessary collection of location data.

### Security

**Security** means protecting systems and information from unauthorized access, modification, or destruction.

Examples:

* Using strong passwords.
* Enabling two-factor authentication.
* Encrypting a laptop.
* Keeping software patched.
* Using a password manager.

### Anonymity

**Anonymity** means preventing activity from being reliably linked to your real-world identity.

For example, a person may be able to browse the Internet without revealing their IP address while still giving themselves away through:

* Logging into a personal account.
* Reusing a username.
* Using the same email address.
* Posting recognizable personal information.
* Having a distinctive writing style.
* Uploading photographs containing identifying information.

A VPN can improve network privacy, but **a VPN by itself does not make you anonymous**.

---

# 2. Start With Your Threat Model

Before installing privacy software, decide what you are actually trying to protect against.

Different people have different requirements.

| Threat                   | Example                                                      |
| ------------------------ | ------------------------------------------------------------ |
| Advertising tracking     | Websites building an advertising profile                     |
| Data brokers             | Companies buying and combining personal information          |
| Website tracking         | Cookies, fingerprinting, analytics                           |
| ISP monitoring           | Your ISP recording connection metadata                       |
| Public Wi-Fi operators   | Network operators monitoring traffic                         |
| Account compromise       | Someone gaining access to your account                       |
| Malware                  | Malicious software stealing information                      |
| Physical theft           | Someone obtaining your laptop or phone                       |
| Targeted surveillance    | A specific person or organization attempting to identify you |
| Local network monitoring | Someone monitoring devices on your LAN                       |
| Data breaches            | A company exposing your information                          |

Your threat model determines how far you need to go.

For ordinary users, preventing advertising tracking and securing accounts may be more useful than attempting to achieve complete anonymity.

---

# 3. How You Can Be Identified

There are many different pieces of information that can be combined to identify or track someone.

## IP Address

Your public IP address can reveal information such as:

* ISP
* Approximate geographic location
* Network or organization
* Sometimes the type of connection

An IP address normally does **not** directly reveal your exact street address to an ordinary website.

A VPN or Tor can prevent the destination website from seeing your normal public IP address.

---

## ISP Logs

Your ISP can potentially observe metadata about your network activity.

HTTPS protects the contents of encrypted connections, but it does not necessarily hide all metadata such as:

* Which IP addresses you connect to
* Connection times
* Amount of traffic
* DNS requests, depending on your configuration

---

## Router and Local Network Logs

Your router or network equipment may keep information such as:

* Connected devices
* MAC addresses
* DNS requests
* DHCP assignments
* Connection times

The exact information depends on the router and its configuration.

---

## Server Logs

Websites commonly record information such as:

* IP address
* Browser information
* Request time
* Requested pages
* Referrer information
* Account information
* Cookies

Even if your IP address is hidden, an account can still identify you.

---

## MAC Addresses

A MAC address identifies a network interface on a local network.

A normal website generally cannot simply read your Wi-Fi/Ethernet MAC address through a web browser.

MAC addresses are more relevant to:

* Local networks
* Wi-Fi networks
* Network administrators
* Device discovery
* Router logs

Modern operating systems also commonly use MAC-address randomization for Wi-Fi scanning or connections.

---

## Browser Fingerprinting

A browser fingerprint combines characteristics of your browser and device to attempt to distinguish you from other users.

Potential fingerprinting information includes:

* Screen characteristics
* Browser features
* Operating system information
* Fonts
* Graphics capabilities
* Time zone
* Language
* Canvas rendering
* WebGL characteristics
* Available APIs

Fingerprinting becomes more useful to trackers when your configuration is unusual.

Test your browser:

**EFF Cover Your Tracks**

https://coveryourtracks.eff.org/

### Important principle

Privacy browsers do not necessarily try to make every user completely unique.

In many cases, the goal is the opposite:

> **Make your browser look similar to many other users.**

---

## Browser Window Size

Browser dimensions can contribute to fingerprinting.

A highly unusual combination of:

* Screen resolution
* Browser dimensions
* Scaling
* Multiple monitors
* Zoom level

may make a browser easier to distinguish.

This is generally only one piece of a larger fingerprint.

---

## Cookies and Persistent Identifiers

Cookies can be used to maintain a recognizable browser session.

Tracking systems may also use other forms of persistent storage or identifiers.

Examples include:

* First-party cookies
* Third-party cookies
* Local storage
* IndexedDB
* Advertising identifiers
* Login/session identifiers

Modern browsers have introduced additional restrictions against third-party tracking, but websites can still collect information through many other mechanisms.

---

## JavaScript

JavaScript allows websites to execute code in your browser.

This enables modern websites to provide functionality, but it can also expose additional browser information and facilitate tracking.

Tools such as **NoScript** can restrict JavaScript, although aggressive blocking can break websites.

---

## Online Behavior

Your behavior can be identifying even when technical identifiers are hidden.

Examples:

* Reusing usernames
* Reusing profile pictures
* Reusing email addresses
* Mentioning your location
* Posting your workplace
* Posting personal photographs
* Following the same communities
* Maintaining recognizable writing habits

Anonymity is therefore partly a **behavioral problem**, not just a technical one.

---

## Writing Style

People can sometimes be recognized through:

* Vocabulary
* Grammar
* Punctuation
* Frequently used phrases
* Writing habits
* Topics discussed

This is sometimes called **stylometry**.

Technical privacy tools cannot completely protect against voluntarily revealing identifying information.

---

## File Metadata

Files can contain metadata that you did not intend to publish.

Examples include:

* EXIF data in photographs
* GPS coordinates
* Camera model
* Creation dates
* Modification dates
* Author information
* Software used to create the document

Before publishing a file, consider whether metadata needs to be removed.

---

## Photographs

Photographs can reveal more than their metadata.

Potential clues include:

* Street signs
* Buildings
* License plates
* Landscapes
* Weather
* Clothing
* Electrical outlets
* Road markings
* Architecture
* Computer screens
* Reflections

A photograph can potentially identify a location even after EXIF metadata has been removed.

---

# 4. Network Privacy

## Use HTTPS

HTTPS encrypts traffic between your browser and the website.

Prefer websites using HTTPS rather than unencrypted HTTP.

Modern browsers generally warn users when connections are insecure.

---

## Use a VPN When Appropriate

A VPN creates an encrypted connection between your device and the VPN provider.

Without a VPN:

```text
You → ISP → Website
```

With a VPN:

```text
You → ISP → VPN → Website
```

The ISP can see that you are connecting to a VPN, while websites generally see the VPN's IP address instead of yours.

### A VPN does NOT automatically provide anonymity

The VPN provider becomes a party you must trust.

Potential considerations include:

* Logging policies
* Jurisdiction
* Payment information
* Account requirements
* Technical implementation
* Independent audits
* Transparency reports

Research the provider rather than assuming that "no logs" automatically means no data exists.

### Example

**Mullvad VPN**

https://mullvad.net/

---

## Public Wi-Fi

Public Wi-Fi introduces additional risks.

Examples:

* Rogue access points
* Network monitoring
* Malicious hotspots
* Poorly configured networks
* Other users attempting local attacks

When using an untrusted network:

* Prefer HTTPS.
* Use a VPN when appropriate.
* Keep your firewall enabled.
* Avoid sensitive activity on suspicious networks.
* Disable automatic connection to unknown Wi-Fi networks.

---

# 5. Browser Privacy

## Choose a Privacy-Conscious Browser

Firefox is a good starting point for users who want extensive privacy controls and customization.

Other privacy-oriented browsers exist, but the important thing is understanding what your browser actually does rather than relying solely on its marketing.

---

## Google Chrome and Incognito Mode

**Incognito/Private Browsing does not mean anonymous browsing.**

Private browsing primarily prevents certain browsing information from being retained locally after the private session ends.

It does **not** mean:

* Websites cannot identify you.
* Your ISP cannot observe network metadata.
* Your employer cannot monitor traffic.
* Google cannot associate activity with you when you are signed into a Google account.
* Other tracking mechanisms cease to exist.

In other words:

> **Incognito protects against some local history exposure; it is not an anonymity system.**

---

## Browser Extensions

### uBlock Origin

Blocks advertisements, trackers, and other unwanted network requests.

https://ublockorigin.com/

### NoScript

Allows users to selectively restrict JavaScript and other active content.

https://noscript.net/

NoScript provides strong control but can make websites considerably more difficult to use.

---

## Avoid Installing Too Many Extensions

Browser extensions themselves require trust.

An extension may potentially:

* Read webpage contents
* Access browsing data
* Modify pages
* Access information on websites

Install only extensions you actually need and periodically review your installed extensions.

---

## HTTPS Everywhere

HTTPS Everywhere was historically useful for forcing HTTPS connections, but modern browsers and websites have largely incorporated similar functionality.

It should not be treated as a required modern privacy extension.

---

# 6. Accounts and Online Identity

One of the easiest ways to destroy anonymity is to log into an account that identifies you.

For example:

```text
Anonymous browsing
       ↓
Login to personal Google account
       ↓
Activity can now be associated with that account
```

A VPN cannot prevent a website from knowing who you are if you voluntarily identify yourself.

---

## Separate Identities

For stronger separation, consider using different:

* Email addresses
* Usernames
* Profile pictures
* Passwords
* Browser profiles
* Accounts

Do not reuse the same username everywhere if anonymity is important.

---

## Password Manager

Use a password manager to create unique passwords for every service.

A compromised password should not allow an attacker to log into every other account.

Use:

* Long unique passwords
* Randomly generated passwords
* Two-factor authentication where available

---

# 7. Operating System Privacy

Your operating system is one of the most trusted pieces of software on your computer.

It can potentially access:

* Files
* Network connections
* Hardware information
* Installed applications
* Location information
* Usage information

Choose an operating system based on your requirements, not simply on whether it is labeled "private."

---

## Linux

Linux distributions provide varying levels of:

* Telemetry
* Default services
* Proprietary software
* Package management
* Configuration control

Debian and other distributions with strong free/open-source software traditions are options worth considering.

### Don't rely on outdated claims

Privacy recommendations should be periodically reviewed.

For example, claims that a particular Linux distribution is inherently unsafe because of an old incident, or that a distribution currently sends specific telemetry based on years-old behavior, should be verified against the current release before being used as a recommendation.

---

## Windows

Windows provides extensive hardware and software compatibility, but users concerned about telemetry and centralized cloud integration may wish to review and disable unnecessary services where practical.

Particular attention should be paid to:

* Microsoft account integration
* Cloud synchronization
* Advertising ID
* Diagnostic data
* Location services
* OneDrive
* Browser synchronization

---

## Apple Devices

Apple's ecosystem provides extensive integration between:

* iPhone
* iPad
* macOS
* iCloud
* Photos
* Contacts
* Messages

This is convenient, but centralized ecosystems can also mean that large amounts of personal information are connected through a single account.

Privacy-conscious users should review which services are enabled rather than assuming that the entire ecosystem must be avoided.

---

# 8. Search, Email, and Communication

## Search Engines

Search engines can potentially learn a great deal from your queries.

Consider privacy-focused alternatives such as:

* DuckDuckGo
* Brave Search
* Startpage
* SearXNG

### Self-hosted SearXNG

SearXNG can aggregate results from multiple search engines without requiring you to interact directly with each provider.

https://docs.searxng.org/

---

# 9. Email

Email is inherently difficult to make completely private because messages may pass through multiple providers.

For a privacy-conscious hosted email provider, consider:

**Proton Mail**

https://proton.me/mail

Remember that encryption does not eliminate metadata such as:

* Sender
* Recipient
* Time
* Message size

---

# 10. Cloud Storage and Personal Data

Large cloud ecosystems can become repositories for enormous amounts of personal information.

Instead of putting everything into a single provider's ecosystem, consider separating services.

For example:

| Service         | Alternative                         |
| --------------- | ----------------------------------- |
| Google Drive    | Nextcloud                           |
| Google Calendar | Nextcloud Calendar                  |
| Google Photos   | Nextcloud Photos                    |
| Google Contacts | Nextcloud Contacts                  |
| Google Messages | Element                             |
| Gmail           | Proton Mail                         |
| Google Search   | DuckDuckGo / Brave Search / SearXNG |
| Chrome          | Firefox                             |

---

## Nextcloud

**Nextcloud** can provide a self-hosted alternative for many common cloud services.

https://nextcloud.com/

Depending on the applications installed, it can provide:

* File storage
* Calendar
* Contacts
* Photo management
* Notes
* Tasks
* Collaboration
* File sharing

### Example

Instead of:

```text
Google Drive
Google Photos
Google Calendar
Google Contacts
```

you can build:

```text
                 Nextcloud
                    │
       ┌────────────┼────────────┐
       ↓            ↓            ↓
    Files        Photos       Calendar
       │                         │
       └────────── Contacts ─────┘
```

### Important

Self-hosting does not automatically mean more secure.

You become responsible for:

* Updates
* Backups
* TLS certificates
* Authentication
* Firewall configuration
* Server security
* Monitoring
* Recovery

Self-hosting trades **provider trust** for **administrator responsibility**.

---

# 11. Messaging

## Element

**Element** is a Matrix client that can be used for encrypted messaging and group communication.

https://element.io/

Matrix is designed as a decentralized communications protocol, meaning you can choose a homeserver rather than necessarily relying on a single centralized service.

For users looking to reduce dependence on centralized messaging ecosystems, Element/Matrix is one option.

---

# 12. Encrypt Cloud Storage

If you must use a third-party cloud provider, consider encrypting sensitive files before uploading them.

## Cryptomator

Cryptomator provides client-side encryption for cloud storage.

https://cryptomator.org/

Conceptually:

```text
Your computer
     │
     ↓
Cryptomator encryption
     │
     ↓
Encrypted files
     │
     ↓
Cloud provider
```

The provider stores encrypted data rather than the original files.

---

# 13. Encrypt Local and External Drives

For sensitive local storage, consider full-disk or container encryption.

## VeraCrypt

https://veracrypt.fr/

Useful for:

* External drives
* USB drives
* Encrypted containers
* Additional encrypted storage

Use a strong, unique password.

A password of 20+ characters can be a reasonable target when using a high-quality passphrase, but **password length alone does not guarantee security**.

A randomly generated password or a strong multi-word passphrase is preferable to something predictable.

---

# 14. Tor and Anonymity

## What Tor Does

Tor routes traffic through multiple relays.

Simplified:

```text
You
 ↓
Tor Guard
 ↓
Tor Relay
 ↓
Tor Exit
 ↓
Website
```

The destination website sees the Tor exit node rather than your normal IP address.

---

## Tor Browser

For anonymous web browsing, use the official Tor Browser rather than attempting to configure an ordinary browser to "use Tor."

https://www.torproject.org/

Tor Browser is specifically designed to reduce fingerprinting and other sources of identification.

---

## Do Not Log Into Personal Accounts

If you use Tor and then immediately log into an account containing your real identity, the website knows who you are.

For example:

```text
Tor + anonymous account
        ↓
Potentially anonymous activity

Tor + personal Google account
        ↓
Google knows which account is performing the activity
```

Tor protects network-level identity; it cannot stop you from identifying yourself.

---

## Tor Exit Nodes

Traffic leaving Tor through an exit node can be observed by the destination network unless it is otherwise encrypted.

Therefore:

> **Use HTTPS.**

Tor does not replace HTTPS.

The fact that multiple users share the same Tor exit node does not, by itself, identify one user as another user.

---

# 15. Amnesic Operating Systems

## Tails

Tails is a live operating system designed around privacy and anonymity.

https://tails.net/

It can run from removable media without installing the operating system normally onto the computer's internal drive.

Tails is useful when you want a separate environment for privacy-sensitive activities.

However, it is not magic. You can still identify yourself through:

* Accounts
* Files
* Writing
* Behavior
* Personal information
* Unsafe applications

---

# 16. Self-Hosting

Self-hosting can reduce dependence on large centralized providers.

Examples include:

* Nextcloud
* SearXNG
* Matrix
* Personal email
* Password managers
* File storage
* Media servers

A self-hosted service gives you greater control over your data.

However:

> **Self-hosting improves control, not automatically security.**

A poorly secured server can be considerably more dangerous than a reputable managed service.

If you self-host:

* Keep software updated.
* Use HTTPS.
* Use strong authentication.
* Disable unnecessary services.
* Keep offline backups.
* Use a firewall.
* Monitor logs.
* Avoid exposing unnecessary ports.
* Use separate service accounts.
* Consider two-factor authentication.

---

# 17. Things That Can De-Anonymize You

The following should be considered when attempting to maintain anonymity:

| Category               | How it can identify you                                        |
| ---------------------- | -------------------------------------------------------------- |
| IP address             | Can reveal ISP and approximate location                        |
| ISP metadata           | Can reveal connection destinations and timing                  |
| Router logs            | Can associate devices with network activity                    |
| Server logs            | Can associate requests with IPs and accounts                   |
| Browser fingerprint    | Can distinguish unusual browser configurations                 |
| Cookies                | Can maintain persistent identifiers                            |
| JavaScript             | Can expose additional browser/device information               |
| Account logins         | Directly associate activity with an identity                   |
| Reused usernames       | Connect otherwise separate identities                          |
| Reused email addresses | Connect accounts together                                      |
| Writing style          | Can potentially identify an author                             |
| Photographs            | Can reveal people, locations, or objects                       |
| File metadata          | Can reveal author, device, GPS, and timestamps                 |
| Search history         | Can reveal interests and potentially identity                  |
| Browser history        | Can reveal activity locally                                    |
| Bookmarks              | Can reveal interests and habits                                |
| Saved forms            | May contain personal information                               |
| Malware                | Can bypass many privacy protections                            |
| Keyloggers             | Can capture passwords and communications                       |
| Physical access        | Can expose locally stored information                          |
| Cloud accounts         | Can centralize large amounts of personal information           |
| Payment records        | Can directly associate purchases with identity                 |
| Social graphs          | Contacts and relationships can identify users                  |
| Unique behavior        | Timing and activity patterns can be identifying                |
| Public Wi-Fi           | Network operators may observe activity                         |
| VPN provider           | Becomes another party you must trust                           |
| Tor mistakes           | Personal accounts or identifying behavior can defeat anonymity |

---

# 18. Common Mistakes

## "I use a VPN, so I'm anonymous."

Not necessarily.

A VPN primarily changes who can see your network traffic and which IP address websites see.

You can still identify yourself through an account, browser fingerprint, payment information, or behavior.

---

## "I use Incognito, so nobody can track me."

No.

Private browsing primarily limits locally stored browsing information.

It does not make you anonymous.

---

## "I use Tor, so I can log into my normal accounts anonymously."

No.

The account itself can identify you.

---

## "Open source automatically means secure."

No.

Open source allows code to be inspected, but security also depends on:

* Code quality
* Maintenance
* Updates
* Configuration
* Dependency security
* User behavior

---

## "Self-hosting means nobody can access my data."

No.

Your server can be compromised.

Self-hosting means **you control the server and its data**, but you also become responsible for securing it.

---

## "More privacy extensions are always better."

Not necessarily.

A large collection of unusual browser extensions can:

* Increase attack surface
* Break websites
* Make your browser configuration more unusual
* Require trusting more third parties

Use the smallest set of tools that meets your requirements.

---

# 19. Practical Privacy Checklist

## Basic Privacy

* [ ] Use a modern, maintained browser.
* [ ] Enable HTTPS.
* [ ] Install a reputable content blocker such as uBlock Origin.
* [ ] Review browser privacy settings.
* [ ] Disable unnecessary third-party cookies.
* [ ] Use a password manager.
* [ ] Use unique passwords.
* [ ] Enable two-factor authentication.
* [ ] Review app permissions.
* [ ] Keep software updated.

---

## Network Privacy

* [ ] Use a VPN when appropriate.
* [ ] Research the VPN provider's logging and privacy policies.
* [ ] Avoid untrusted public Wi-Fi when possible.
* [ ] Use HTTPS.
* [ ] Consider encrypted DNS.
* [ ] Keep your router firmware updated.
* [ ] Change default router credentials.

---

## Account Privacy

* [ ] Avoid unnecessary accounts.
* [ ] Separate identities when appropriate.
* [ ] Do not reuse usernames everywhere.
* [ ] Do not reuse profile pictures.
* [ ] Use separate email addresses for different purposes.
* [ ] Review old accounts and delete ones you no longer need.

---

## File Privacy

* [ ] Remove unnecessary EXIF metadata.
* [ ] Check documents for author information.
* [ ] Encrypt sensitive files.
* [ ] Encrypt external drives.
* [ ] Maintain backups.
* [ ] Securely delete sensitive files when appropriate.

---

## Cloud Privacy

Consider replacing or reducing dependence on:

* [ ] Google Drive
* [ ] Google Photos
* [ ] Google Calendar
* [ ] Google Contacts

Possible alternative:

* [ ] Nextcloud

If using third-party cloud storage:

* [ ] Encrypt sensitive data before uploading it.
* [ ] Consider Cryptomator.

---

## Communication Privacy

* [ ] Use encrypted messaging where appropriate.
* [ ] Consider Element/Matrix.
* [ ] Use a privacy-conscious email provider.
* [ ] Consider Proton Mail.
* [ ] Avoid putting sensitive information into ordinary SMS.

---

# 20. Suggested Privacy Levels

Not everyone needs the same setup.

## Level 1 — Basic Privacy

Good for ordinary Internet users.

```text
Firefox
   +
uBlock Origin
   +
Password Manager
   +
2FA
   +
HTTPS
   +
Software Updates
```

Focus on preventing common tracking and account compromise.

---

## Level 2 — Increased Privacy

For users who want to reduce dependence on large advertising ecosystems.

```text
Firefox
   +
uBlock Origin
   +
Privacy-focused search engine
   +
VPN
   +
Separate email addresses
   +
Nextcloud
   +
Encrypted backups
```

---

## Level 3 — Strong Privacy

For users with more significant privacy requirements.

```text
Privacy-focused OS
        +
Tor Browser
        +
Carefully separated identities
        +
Encrypted storage
        +
Encrypted communications
        +
Minimal personal information
```

At this level, **operational security becomes extremely important**.

A technical mistake can undo an otherwise sophisticated setup.

---

# 21. Privacy vs. Convenience

There is no completely free privacy solution.

Centralized services are often convenient because someone else handles:

* Backups
* Updates
* Availability
* Infrastructure
* Security
* Recovery

Self-hosting provides more control but requires more work.

Similarly:

| More Convenience       | More Control                      |
| ---------------------- | --------------------------------- |
| Google Drive           | Nextcloud                         |
| Google Photos          | Nextcloud Photos                  |
| Google Calendar        | Nextcloud Calendar                |
| Google Contacts        | Nextcloud Contacts                |
| Chrome Sync            | Local browser profiles            |
| Hosted services        | Self-hosted services              |
| Ordinary cloud storage | Client-side encrypted storage     |
| Centralized messaging  | Federated/decentralized messaging |

The correct choice depends on what you value and what threats you are attempting to mitigate.

---

# 22. Recommended Tools

| Purpose                     | Tool                                |
| --------------------------- | ----------------------------------- |
| VPN                         | Mullvad                             |
| Anonymous browsing          | Tor Browser                         |
| Privacy-focused live OS     | Tails                               |
| Browser                     | Firefox                             |
| Content blocking            | uBlock Origin                       |
| Script control              | NoScript                            |
| Search                      | DuckDuckGo / Brave Search / SearXNG |
| Email                       | Proton Mail                         |
| Cloud storage               | Nextcloud                           |
| Cloud encryption            | Cryptomator                         |
| Drive encryption            | VeraCrypt                           |
| Messaging                   | Element / Matrix                    |
| Browser fingerprint testing | EFF Cover Your Tracks               |

Always verify the current status of a project before adopting it. Privacy software can change ownership, policies, development status, or default behavior over time.

---

# 23. Final Principles

If you remember nothing else from this guide, remember these:

### 1. Minimize the data you create.

The easiest data to protect is data that was never collected.

### 2. Don't put everything under one identity.

Separating accounts and identities can make correlation more difficult.

### 3. Don't trust a privacy tool blindly.

A VPN, browser, operating system, or messaging application becomes another piece of software that you must trust.

### 4. Encryption protects data; it doesn't necessarily hide metadata.

Who you communicate with, when you communicate, and how much data is transferred can still matter.

### 5. Anonymity is partly behavioral.

A VPN or Tor cannot prevent you from identifying yourself.

### 6. Security comes before anonymity.

A compromised computer can potentially bypass many privacy measures.

### 7. Keep everything updated.

An outdated privacy tool is still vulnerable software.

### 8. Back up important data.

Privacy is not useful if a hardware failure destroys your only copy.

### 9. Use the least complicated setup that meets your threat model.

Complexity creates opportunities for mistakes.

### 10. There is no such thing as perfect anonymity.

The goal is to **reduce unnecessary exposure and make unwanted tracking, profiling, and identification more difficult.**
