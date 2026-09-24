# 2009Scape `default.conf` Configuration Reference

This document provides a detailed reference for the `default.conf` configuration file used by the **2009Scape** server.

It documents both:

* The **default values** shipped with 2009Scape.
* Recommended values for a typical personal, development, or production server.

> **Important:** The values under **Default** below are the original 2009Scape defaults. The **Recommended** values are configuration recommendations and are not necessarily the same as the upstream defaults.

---

# Table of Contents

* [Understanding Defaults vs. Recommendations](#understanding-defaults-vs-recommendations)
* [`[server]`](#server)

  * [`log_level`](#log_level)
  * [`secret_key`](#secret_key)
  * [`write_logs`](#write_logs)
  * [`msip`](#msip)
  * [`preload_map`](#preload_map)
  * [`use_auth`](#use_auth)
  * [`persist_accounts`](#persist_accounts)
  * [`noauth_default_admin`](#noauth_default_admin)
  * [`daily_accounts_per_ip`](#daily_accounts_per_ip)
  * [`watchdog_enabled`](#watchdog_enabled)
  * [`connectivity_check_url`](#connectivity_check_url)
  * [`connectivity_timeout`](#connectivity_timeout)
  * [WebSocket Settings](#websocket-settings)
* [`[database]`](#database)

  * [`database_name`](#database_name)
  * [`database_username`](#database_username)
  * [`database_password`](#database_password)
  * [`database_address`](#database_address)
  * [`database_port`](#database_port)
* [`[integrations]`](#integrations)

  * [`grafana_logging`](#grafana_logging)
  * [`grafana_log_path`](#grafana_log_path)
  * [`grafana_log_ttl_days`](#grafana_log_ttl_days)
  * [Discord and OpenRSC Webhooks](#discord-and-openrsc-webhooks)
* [`[world]`](#world)

  * [World Identity](#world-identity)
  * [Development Settings](#development-settings)
  * [World and Membership Settings](#world-and-membership-settings)
  * [Clan Settings](#clan-settings)
  * [Bot Settings](#bot-settings)
  * [Grand Exchange Settings](#grand-exchange-settings)
  * [Gameplay Settings](#gameplay-settings)
  * [PvP and Wilderness](#pvp-and-wilderness)
  * [Random Events](#random-events)
  * [Skills and Progression](#skills-and-progression)
  * [Custom Content](#custom-content)
  * [Player Features](#player-features)
* [`[paths]`](#paths)

  * [`data_path`](#data_path)
  * [`cache_path`](#cache_path)
  * [`store_path`](#store_path)
  * [`save_path`](#save_path)
  * [`configs_path`](#configs_path)
  * [`grand_exchange_data_path`](#grand_exchange_data_path)
  * [Drop Table Paths](#drop-table-paths)
  * [`object_parser_path`](#object_parser_path)
  * [`logs_path`](#logs_path)
  * [`bot_data`](#bot_data)
  * [`eco_data`](#eco_data)
* [Recommended Configuration](#recommended-configuration)
* [Production Configuration](#production-configuration)
* [Important Security Considerations](#important-security-considerations)
* [Backup Recommendations](#backup-recommendations)
* [Quick Reference](#quick-reference)

---

# Understanding Defaults vs. Recommendations

There are two different concepts used throughout this guide.

## Default

**Default** means the value shipped in the standard 2009Scape `default.conf`.

These values are intended to provide a basic development/testing configuration.

The default configuration intentionally leaves several security and convenience features disabled.

For example:

```ini
use_auth = false
persist_accounts = false
debug = true
dev = true
```

These are valid development defaults, but they should not automatically be interpreted as production recommendations.

---

## Recommended

**Recommended** means a suggested configuration for a more usable or secure server.

For example, the default configuration contains:

```ini
use_auth = false
```

while the recommended configuration is:

```ini
use_auth = true
```

This is because password authentication should be enabled when operating a real/public server.

---

# `[server]`

The `[server]` section controls core server behavior, logging, authentication, networking, and WebSocket support.

---

## `log_level`

```ini
log_level = "verbose"
```

**Type:** String
**Default:** `verbose`
**Recommended:** `verbose` for development; `detailed` for a quieter production server
**Restart required:** Yes

### Description

Controls the amount of information written to the server logs.

There are four supported levels:

| Level      | Description                                                    |
| ---------- | -------------------------------------------------------------- |
| `verbose`  | All logs are shown                                             |
| `detailed` | `FINE` logs are hidden                                         |
| `cautious` | `FINE` and `INFO` logs are hidden; warnings and errors remain  |
| `silent`   | `FINE`, `INFO`, and `WARN` logs are hidden; only errors remain |

### `verbose`

```ini
log_level = "verbose"
```

Displays the greatest amount of information.

This is useful when:

* Developing the server
* Debugging scripts
* Investigating crashes
* Troubleshooting networking
* Investigating database problems

### `detailed`

```ini
log_level = "detailed"
```

Hides the most verbose `FINE` messages while retaining more useful operational information.

### `cautious`

```ini
log_level = "cautious"
```

Only shows warnings and errors.

### `silent`

```ini
log_level = "silent"
```

Only displays errors.

### Recommendation

For development, keeping:

```ini
log_level = "verbose"
```

is useful.

For a busy production server, `detailed` or `cautious` can reduce log volume.

---

## `secret_key`

```ini
secret_key = "2009scape_development"
```

**Type:** String
**Default:** `2009scape_development`
**Recommended:** Keep the client and server values synchronized; use a unique secret where appropriate
**Restart required:** Yes

### Description

The secret key is sent by the client during login.

The **client and server must use matching values**.

If the values do not match, the client connection will be refused.

Example:

```ini
secret_key = "2009scape_development"
```

The corresponding client configuration must contain the same key.

### Security

If this server is exposed publicly, avoid treating the development key as a strong secret. Anyone who has access to the client configuration may be able to recover the key.

---

## `write_logs`

```ini
write_logs = true
```

**Type:** Boolean
**Default:** `true`
**Recommended:** `true`
**Restart required:** Yes

### Description

Controls whether logs are written to disk.

When enabled:

```ini
write_logs = true
```

the server writes persistent log files.

The location is controlled by:

```ini
logs_path = "@data/logs"
```

When disabled:

```ini
write_logs = false
```

persistent log files are not written.

### Recommendation

Leave this enabled unless there is a specific reason to disable disk logging.

---

## `msip`

```ini
msip = "127.0.0.1"
```

**Type:** IP address
**Default:** `127.0.0.1`
**Recommended:** `127.0.0.1` for a local installation
**Restart required:** Yes

### Description

Specifies the server/management IP address.

`127.0.0.1` is the IPv4 loopback address and refers to the local machine.

For a server where the relevant services are running on the same machine:

```ini
msip = "127.0.0.1"
```

is normally appropriate.

---

## `preload_map`

```ini
preload_map = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` unless sufficient RAM is available
**Restart required:** Yes

### Description

Controls whether the map is preloaded into memory.

The 2009Scape configuration notes that enabling this option increases memory usage by approximately **2 GB**, but can make game ticks smoother.

### Disabled

```ini
preload_map = false
```

Uses less memory.

### Enabled

```ini
preload_map = true
```

Loads map data ahead of time.

This can improve responsiveness at the cost of increased memory usage.

### Recommendation

For a development server or a machine with limited RAM:

```ini
preload_map = false
```

A dedicated server with plenty of RAM can test:

```ini
preload_map = true
```

to determine whether the smoother game ticks are worthwhile.

---

# Authentication and Account Settings

## `use_auth`

```ini
use_auth = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `true`
**Production:** **Must be `true`**

### Description

Controls whether login passwords are checked.

When enabled:

```ini
use_auth = true
```

the player's supplied password must match the stored password.

Passwords are hashed before being stored.

When disabled:

```ini
use_auth = false
```

the server does not care whether the supplied password is correct.

### Important

The upstream default is intentionally:

```ini
use_auth = false
```

because the default configuration is intended primarily for development.

For a production server:

```ini
use_auth = true
```

should be used.

---

## `persist_accounts`

```ini
persist_accounts = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `true`
**Production:** **Must be `true`**

### Description

Controls whether account-level information is persisted.

Examples include:

* Credits
* Playtime
* Other account-level information

### Important distinction

This setting does **not** control actual player save data.

It does not determine whether things such as the following are saved:

* Skills
* Inventory
* Equipment
* Character progression
* Other gameplay data

Those are handled by the player save system.

### Default

```ini
persist_accounts = false
```

Account-level data is temporary.

### Recommended

```ini
persist_accounts = true
```

Account-level data is persisted.

---

## `noauth_default_admin`

```ini
noauth_default_admin = true
```

**Type:** Boolean
**Default:** `true`
**Recommended:** `false` for public servers
**Restart required:** Yes

### Description

Determines whether players are administrators when authentication is disabled.

This option is primarily relevant when:

```ini
use_auth = false
```

The default development configuration uses:

```ini
use_auth = false
noauth_default_admin = true
```

This can be convenient when developing or testing the server.

### Security warning

Do **not** expose an unauthenticated server publicly while giving unauthenticated users administrator privileges.

For a production server:

```ini
use_auth = true
noauth_default_admin = false
```

is strongly preferable.

---

## `daily_accounts_per_ip`

```ini
daily_accounts_per_ip = 3
```

**Type:** Integer
**Default:** `3`
**Recommended:** Depends on server policy; `9999` removes the practical restriction
**Restart required:** Yes

### Description

Controls the number of different accounts that can be logged into from the same IP address during a day.

The default is:

```ini
daily_accounts_per_ip = 3
```

For example, an IP could normally log into three different accounts under the default limit.

A high value such as:

```ini
daily_accounts_per_ip = 9999
```

effectively removes the practical restriction.

### Considerations

IP-based limits can affect multiple legitimate players who share an Internet connection.

Examples include:

* Families
* Schools
* Dormitories
* Offices
* Public networks
* VPNs
* Carrier-grade NAT

---

## `watchdog_enabled`

```ini
watchdog_enabled = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `true`
**Restart required:** Yes

### Description

Controls whether the server watchdog is enabled.

The watchdog can monitor server operation and help identify situations where the server becomes unresponsive.

### Default

```ini
watchdog_enabled = false
```

### Recommended

```ini
watchdog_enabled = true
```

For a long-running server, enabling the watchdog can provide additional protection and monitoring.

---

## `connectivity_check_url`

```ini
connectivity_check_url = "https://google.com,https://2009scape.org"
```

**Type:** Comma-separated URL list
**Default:** `https://google.com,https://2009scape.org`
**Recommended:** Use reliable endpoints
**Restart required:** Yes

### Description

Specifies URLs used for connectivity checks.

Multiple URLs are separated by commas:

```ini
connectivity_check_url = "https://google.com,https://2009scape.org"
```

Using multiple endpoints can reduce dependence on a single external service.

---

## `connectivity_timeout`

```ini
connectivity_timeout = 500
```

**Type:** Integer
**Unit:** Milliseconds
**Default:** `500`
**Recommended:** `500` or higher depending on network conditions
**Restart required:** Yes

### Description

Controls how long the server waits for a connectivity check.

The default:

```ini
connectivity_timeout = 500
```

means the timeout is 500 milliseconds.

---

# WebSocket Settings

The WebSocket system allows browser-based clients to connect to the server.

The WebSocket transport carries the same raw binary protocol as TCP. Each WebSocket binary frame is treated as a byte chunk.

---

## `websocket_enabled`

```ini
websocket_enabled = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` unless using browser clients
**Restart required:** Yes

### Description

Enables the WebSocket listener.

For normal clients that connect through TCP, this can remain disabled.

Browser clients may require WebSocket support.

---

## `websocket_port`

```ini
websocket_port = 0
```

**Type:** Integer
**Default:** `0`
**Recommended:** `0` unless a fixed port is required
**Restart required:** Yes

### Description

Controls which port the WebSocket listener uses.

When set to:

```ini
websocket_port = 0
```

the server automatically uses:

```text
53594 + world_id
```

For example:

```ini
world_id = "1"
websocket_port = 0
```

results in:

```text
53595
```

A specific port can also be supplied:

```ini
websocket_port = 55000
```

---

## `websocket_tls_enabled`

```ini
websocket_tls_enabled = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `true` when publicly serving browser clients over TLS
**Restart required:** Yes

### Description

Enables TLS encryption for the WebSocket listener.

Without TLS:

```text
ws://
```

With TLS:

```text
wss://
```

For browser clients operating through HTTPS, secure WebSockets are generally appropriate.

---

## `websocket_tls_keystore_path`

```ini
websocket_tls_keystore_path = ""
```

**Type:** Path
**Default:** Empty
**Recommended:** Configure when WebSocket TLS is enabled
**Restart required:** Yes

### Description

Specifies the PKCS#12 keystore containing the TLS certificate and private key.

Example:

```ini
websocket_tls_keystore_path = "certs/dev-wss.p12"
```

---

## `websocket_tls_keystore_password`

```ini
websocket_tls_keystore_password = ""
```

**Type:** String
**Default:** Empty
**Recommended:** Use a password-protected keystore where appropriate
**Restart required:** Yes

### Description

Specifies the password used to open the PKCS#12 keystore.

If the PKCS#12 file was exported with an empty password, this can remain:

```ini
websocket_tls_keystore_password = ""
```

---

# `[database]`

The `[database]` section controls the MySQL/MariaDB connection used by the server.

The supplied default assumes a database server running locally on the standard MySQL port.

---

## `database_name`

```ini
database_name = "global"
```

**Type:** String
**Default:** `global`
**Recommended:** The database containing the 2009Scape schema
**Restart required:** Yes

### Description

Specifies the database/schema the server connects to.

Example:

```ini
database_name = "global"
```

The specified database must contain the required 2009Scape database structure.

---

## `database_username`

```ini
database_username = "root"
```

**Type:** String
**Default:** `root`
**Recommended:** A dedicated database user
**Restart required:** Yes

### Description

Specifies the database username.

The default configuration uses:

```ini
database_username = "root"
```

This is convenient for local development but is not ideal for a production server.

### Recommended production approach

Create a dedicated database account:

```ini
database_username = "2009scape"
```

and grant that account only the permissions it requires.

---

## `database_password`

```ini
database_password = ""
```

**Type:** String
**Default:** Empty
**Recommended:** Strong password for production
**Restart required:** Yes

### Description

Specifies the password for the database account.

The default is empty:

```ini
database_password = ""
```

This is convenient for local development installations.

A production database account should normally have a password.

---

## `database_address`

```ini
database_address = "127.0.0.1"
```

**Type:** IP address/hostname
**Default:** `127.0.0.1`
**Recommended:** `127.0.0.1` for a local database
**Restart required:** Yes

### Description

Specifies the host running the database server.

For a database running on the same computer:

```ini
database_address = "127.0.0.1"
```

For a remote database, an IP address or hostname can be used.

Example:

```ini
database_address = "192.168.1.50"
```

---

## `database_port`

```ini
database_port = "3306"
```

**Type:** Port
**Default:** `3306`
**Recommended:** `3306` unless MySQL/MariaDB uses another port
**Restart required:** Yes

### Description

Specifies the TCP port used by the database.

The standard MySQL/MariaDB port is:

```text
3306
```

---

# `[integrations]`

The `[integrations]` section contains optional integrations with external services.

---

## `grafana_logging`

```ini
grafana_logging = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` unless using Grafana
**Restart required:** Yes

### Description

Enables Grafana-compatible logging.

If Grafana is not being used:

```ini
grafana_logging = false
```

is appropriate.

---

## `grafana_log_path`

```ini
grafana_log_path = "@data/logs"
```

**Type:** Path
**Default:** `@data/logs`
**Recommended:** `@data/logs`
**Restart required:** Yes

### Description

Specifies where Grafana logging data is stored.

With:

```ini
data_path = "data"
```

the following:

```ini
grafana_log_path = "@data/logs"
```

resolves to:

```text
data/logs
```

---

## `grafana_log_ttl_days`

```ini
grafana_log_ttl_days = 7
```

**Type:** Integer
**Unit:** Days
**Default:** `7`
**Recommended:** Depends on required history
**Restart required:** Yes

### Description

Controls how many days of old Grafana log data are retained.

Data older than the configured value is pruned once during server startup.

For example:

```ini
grafana_log_ttl_days = 30
```

would retain approximately 30 days of data.

---

# Discord and OpenRSC Webhooks

The following integrations are included but commented out by default:

```ini
#discord_ge_webhook = "webhook link"
#discord_moderation_webhook = "webhook link"
#openrsc_integration_webhook = "webhook link"
```

These can be configured if the associated integrations are being used.

### `discord_ge_webhook`

Used for supported Grand Exchange Discord notifications.

### `discord_moderation_webhook`

Used for supported moderation Discord notifications.

### `openrsc_integration_webhook`

Used for supported OpenRSC integration.

### Security

Webhook URLs should be treated as secrets.

Do not commit active webhook URLs to a public GitHub repository.

---

# `[world]`

The `[world]` section controls the identity and gameplay behavior of the 2009Scape world.

---

# World Identity

## `name`

```ini
name = "2009Scape"
```

**Type:** String
**Default:** `2009Scape`
**Recommended:** `2009Scape`
**Restart required:** Yes

### Description

Specifies the name of the game world.

The standard world name is:

```ini
name = "2009Scape"
```

This value is also referenced by other configuration features using the `@name` placeholder.

---

## `name_ge`

```ini
name_ge = "2009Scape"
```

**Type:** String
**Default:** `2009Scape`
**Recommended:** Match `name` unless intentionally different
**Restart required:** Yes

### Description

Specifies the name used in Grand Exchange announcements for bots selling items.

The standard configuration uses:

```ini
name_ge = "2009Scape"
```

---

## `world_id`

```ini
world_id = "1"
```

**Type:** String/integer
**Default:** `1`
**Recommended:** Unique ID for the world
**Restart required:** Yes

### Description

Specifies the world number.

The default world is:

```ini
world_id = "1"
```

The world ID is also used by the automatic WebSocket port calculation.

---

## `country_id`

```ini
country_id = "0"
```

**Type:** String/integer
**Default:** `0`
**Recommended:** Appropriate world-list value
**Restart required:** Yes

### Description

Specifies the country/region identifier associated with the world.

---

## `members`

```ini
members = true
```

**Type:** Boolean
**Default:** `true`
**Recommended:** Depends on intended world type
**Restart required:** Yes

### Description

Determines whether the world is treated as a members-enabled world.

---

## `activity`

```ini
activity = "2009Scape Classic."
```

**Type:** String
**Default:** `2009Scape Classic.`
**Recommended:** Accurately describe the world
**Restart required:** Yes

### Description

Text displayed as the world's activity in the world list.

---

## `pvp`

```ini
pvp = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** Depends on world type
**Restart required:** Yes

### Description

Controls whether the world is configured as a PvP world.

---

# Development Settings

## `debug`

```ini
debug = true
```

**Type:** Boolean
**Default:** `true`
**Recommended:** `false` for production
**Restart required:** Yes

### Description

Enables debugging behavior.

The upstream default is:

```ini
debug = true
```

This reflects the fact that the default configuration is primarily intended for development.

For a production server:

```ini
debug = false
```

is recommended.

---

## `dev`

```ini
dev = true
```

**Type:** Boolean
**Default:** `true`
**Recommended:** `false` for production
**Restart required:** Yes

### Description

Enables development-oriented behavior.

The default is:

```ini
dev = true
```

For normal public operation:

```ini
dev = false
```

should be used unless a specific development feature requires otherwise.

---

## `start_gui`

```ini
start_gui = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` for headless servers
**Restart required:** Yes

### Description

Controls whether the server starts with its graphical interface.

For a command-line or dedicated server:

```ini
start_gui = false
```

is appropriate.

---

## `daily_restart`

```ini
daily_restart = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `true` for a long-running production server
**Restart required:** Yes

### Description

Controls whether the server performs its daily restart behavior.

The upstream default is:

```ini
daily_restart = false
```

A production server may benefit from enabling:

```ini
daily_restart = true
```

to establish a predictable restart cycle.

---

# Clan Settings

## `enable_default_clan`

```ini
enable_default_clan = true
```

**Type:** Boolean
**Default:** `true`
**Recommended:** Depends on whether the default clan is configured
**Restart required:** Yes

### Description

Enables a default clan that players can automatically join.

The account must use the same name as the configured world `name`.

With:

```ini
name = "2009Scape"
enable_default_clan = true
```

the relevant account should be named:

```text
2009Scape
```

and have an appropriate clan configured.

---

# Bot Settings

## `enable_bots`

```ini
enable_bots = true
```

**Type:** Boolean
**Default:** `true`
**Recommended:** `true` if using server bots
**Restart required:** Yes

### Description

Enables server bots.

This controls the availability of the server's bot system.

---

## `enable_botting`

```ini
enable_botting = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` unless intentionally allowing botting
**Restart required:** Yes

### Description

Enables supported player botting functionality.

This is separate from:

```ini
enable_bots = true
```

which enables server-controlled bots.

---

## `max_adv_bots`

```ini
max_adv_bots = 100
```

**Type:** Integer
**Default:** `100`
**Recommended:** Based on available CPU and RAM
**Restart required:** Yes

### Description

Controls the maximum number of advanced bots.

Increasing the number of active bots can increase:

* CPU usage
* Memory usage
* Game-world activity
* Database activity

---

# Message of the Week

## `motw_identifier`

```ini
motw_identifier = "0"
```

**Type:** String/integer
**Default:** `0`
**Recommended:** `0` for random selection
**Restart required:** Yes

### Description

Specifies the Message of the Week model ID.

The value `0` indicates random selection.

---

## `motw_text`

```ini
motw_text = "Welcome to @name!"
```

**Type:** String
**Default:** `Welcome to @name!`
**Recommended:** Customize as desired
**Restart required:** Yes

### Description

Specifies the text displayed for the Message of the Week.

The special placeholder:

```text
@name
```

is replaced with the configured world name.

With:

```ini
name = "2009Scape"
```

the message:

```text
Welcome to @name!
```

becomes:

```text
Welcome to 2009Scape!
```

---

# Player Locations

## `new_player_location`

```ini
new_player_location = "3094,3107,0"
```

**Type:** Coordinate string
**Default:** `3094,3107,0`
**Recommended:** Keep the standard location unless intentionally changing the spawn
**Restart required:** Yes

### Description

Specifies the location where new players spawn.

The format is:

```text
X,Y,Plane
```

Example:

```text
3094,3107,0
```

Where:

* `3094` = X coordinate
* `3107` = Y coordinate
* `0` = plane/height level

---

## `home_location`

```ini
home_location = "3222,3218,0"
```

**Type:** Coordinate string
**Default:** `3222,3218,0`
**Recommended:** Keep the standard location unless intentionally changing home
**Restart required:** Yes

### Description

Specifies the destination used for the home teleport.

Format:

```text
X,Y,Plane
```

---

# Grand Exchange Settings

## `autostock_ge`

```ini
autostock_ge = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** Depends on desired economy behavior
**Restart required:** Yes

### Description

Enables automatic Grand Exchange stocking.

---

## `allow_token_purchase`

```ini
allow_token_purchase = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** Depends on desired economy/gameplay
**Restart required:** Yes

### Description

Controls whether supported token purchases are allowed.

---

## `bots_influence_ge_price`

```ini
bots_influence_ge_price = true
```

**Type:** Boolean
**Default:** `true`
**Recommended:** Depends on desired economy
**Restart required:** Yes

### Description

Determines whether bot activity can influence Grand Exchange pricing.

---

## `ge_announcement_limit`

```ini
ge_announcement_limit = 500
```

**Type:** Integer
**Unit:** High Alchemy value
**Default:** `500`
**Recommended:** Depends on desired announcement frequency
**Restart required:** Yes

### Description

Specifies the minimum high-alchemy value required for announcements about bots selling items on the Grand Exchange.

---

## `personalized_shops`

```ini
personalized_shops = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` unless specifically desired
**Restart required:** Yes

### Description

Enables personalized shop behavior.

---

# Gameplay Settings

## `skillcape_perks`

```ini
skillcape_perks = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `true` if desired as an enhanced gameplay feature
**Restart required:** Yes

### Description

Enables skillcape perks.

The default configuration leaves this disabled.

---

## `increased_door_time`

```ini
increased_door_time = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false`
**Restart required:** Yes

### Description

Enables increased door timing.

---

## `enable_doubling_money_scammers`

```ini
enable_doubling_money_scammers = true
```

**Type:** Boolean
**Default:** `true`
**Recommended:** Depends on intended gameplay environment
**Restart required:** Yes

### Description

Controls the supported doubling-money scam gameplay.

This option is enabled in the upstream default configuration.

---

## `jad_practice_enabled`

```ini
jad_practice_enabled = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** Optional
**Restart required:** Yes

### Description

Enables the Jad practice feature.

---

## `enable_global_chat`

```ini
enable_global_chat = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `true` if global chat is desired
**Restart required:** Yes

### Description

Enables global chat functionality.

The upstream default leaves this disabled.

---

## `verbose_cutscene`

```ini
verbose_cutscene = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false`, enable while debugging cutscenes
**Restart required:** Yes

### Description

Enables verbose logging for cutscenes using the newer cutscene system.

This is primarily useful when troubleshooting cutscene behavior.

---

## `show_rules`

```ini
show_rules = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `true` for a public/custom server
**Restart required:** Yes

### Description

Controls whether players are shown the server rules the first time they log in.

For a custom server, enabling this can help communicate:

* Server rules
* Gameplay policies
* Community guidelines
* Custom mechanics

---

## `new_player_announcement`

```ini
new_player_announcement = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `true` if desired
**Restart required:** Yes

### Description

Controls whether the server announces newly arriving players.

---

## `player_commands`

```ini
player_commands = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `true` if the additional commands are desired
**Restart required:** Yes

### Description

Enables inauthentic but non-dangerous commands for regular players.

The default configuration disables these commands.

---

# PvP and Wilderness

## `wild_pvp_enabled`

```ini
wild_pvp_enabled = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `true` if standard Wilderness PvP is desired
**Restart required:** Yes

### Description

Enables Wilderness PvP functionality.

This setting is separate from:

```ini
pvp = false
```

which controls whether the world itself is a PvP world.

---

## `enhanced_deep_wilderness`

```ini
enhanced_deep_wilderness = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` unless intentionally using the enhanced Wilderness system
**Restart required:** Yes

### Description

Enables the enhanced deep Wilderness.

According to the configuration description, the area past the members' fence applies a red skull that increases certain brawler/PvP drop rates.

---

## `wilderness_exclusive_loot`

```ini
wilderness_exclusive_loot = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** Depends on desired Wilderness economy
**Restart required:** Yes

### Description

Enables Wilderness-exclusive loot from:

* Revenants
* Chaos Elemental

Examples include:

* Brawling gloves
* PvP gear

---

## `revenant_population`

```ini
revenant_population = 30
```

**Type:** Integer
**Default:** `30`
**Recommended:** Based on desired Wilderness activity
**Restart required:** Yes

### Description

Specifies the number of Revenants active at a time.

Increasing this value can make the Wilderness more active while potentially increasing server resource usage.

---

# Random Events

## `inauthentic_candlelight_random`

```ini
inauthentic_candlelight_random = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` for a more authentic ruleset
**Restart required:** Yes

### Description

Enables the inauthentic Candlelight random event.

When enabled, it adds an additional normal random event.

---

## `holiday_event_randoms`

```ini
holiday_event_randoms = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** Depends on event policy
**Restart required:** Yes

### Description

Enables holiday random events.

This does not affect normal random events.

---

## `force_halloween_randoms`

```ini
force_halloween_randoms = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` except when intentionally forcing Halloween events
**Restart required:** Yes

### Description

Forces Halloween random events.

Only one forced holiday random should be active at a time.

---

## `force_christmas_randoms`

```ini
force_christmas_randoms = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` except when intentionally forcing Christmas events
**Restart required:** Yes

### Description

Forces Christmas random events.

Only one forced holiday random should be active at a time.

---

## `april_fools_event`

```ini
april_fools_event = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` except during the intended event/testing period
**Restart required:** Yes

### Description

Enables the inauthentic April Fools event.

---

## `force_april_fools`

```ini
force_april_fools = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` except when intentionally forcing the event
**Restart required:** Yes

### Description

Forces the April Fools event.

---

# Skills and Progression

## `runecrafting_formula_revision`

```ini
runecrafting_formula_revision = 530
```

**Type:** Integer
**Default:** `530`
**Recommended:** Match the desired historical ruleset
**Restart required:** Yes

### Description

Specifies which Runecrafting formula revision is used.

The configuration notes:

* Revision `573` introduced probabilistic multiple-rune production.
* Revision `581` extrapolated probabilistic rune production beyond level 99.

The default:

```ini
runecrafting_formula_revision = 530
```

therefore uses the earlier formula behavior.

---

## `xp_rates`

```ini
xp_rates = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `true` if players should choose XP rates on Tutorial Island
**Restart required:** Yes

### Description

Enables the XP-rates option on Tutorial Island.

The default configuration does not expose the XP-rate option.

---

## `ironman`

```ini
ironman = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `true` if Ironman creation should be available
**Restart required:** Yes

### Description

Enables the Ironman option on Tutorial Island.

---

# Custom Content

## `shooting_star_ring`

```ini
shooting_star_ring = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` unless custom content is desired
**Restart required:** Yes

### Description

Enables the custom-content:

* Ancient Blueprint
* Ring of the Star Sprite

This is explicitly identified as custom content.

---

## `second_bank`

```ini
second_bank = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` unless a second bank is desired
**Restart required:** Yes

### Description

Enables the second bank feature.

---

## `boosted_trawler_rewards`

```ini
boosted_trawler_rewards = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` for standard rewards
**Restart required:** Yes

### Description

Enables boosted Fishing Trawler rewards.

The configuration specifically identifies:

* Key halves
* Pirate outfit pieces

as boosted rewards.

---

# `[paths]`

The `[paths]` section determines where 2009Scape stores server data.

A typical directory structure is:

```text
data/
├── cache/
├── configs/
│   └── shared_tables/
├── eco/
├── logs/
├── players/
├── serverstore/
├── botdata/
└── ObjectParser.xml
```

The exact contents can vary depending on the server version and installed data.

---

# The `@data` Variable

Many paths begin with:

```text
@data
```

This is a path variable referring to the value configured by:

```ini
data_path = "data"
```

For example:

```ini
data_path = "data"
logs_path = "@data/logs"
```

resolves to:

```text
data/logs
```

If `data_path` is changed to:

```ini
data_path = "server-data"
```

then:

```ini
logs_path = "@data/logs"
```

automatically resolves to:

```text
server-data/logs
```

This makes it possible to relocate the entire server data directory without changing every individual path.

---

## `data_path`

```ini
data_path = "data"
```

**Type:** Path
**Default:** `data`
**Recommended:** `data` unless a custom directory layout is required
**Restart required:** Yes

### Description

Specifies the root directory containing server data.

Most other paths use `@data` and therefore follow this setting.

---

## `cache_path`

```ini
cache_path = "@data/cache"
```

**Type:** Path
**Default:** `@data/cache`
**Recommended:** Keep under `data_path`
**Restart required:** Yes

### Description

Specifies the location of cache data.

With:

```ini
data_path = "data"
```

the resolved path is:

```text
data/cache
```

---

## `store_path`

```ini
store_path = "@data/serverstore"
```

**Type:** Path
**Default:** `@data/serverstore`
**Recommended:** Keep on persistent storage
**Restart required:** Yes

### Description

Specifies the location of the server's persistent store data.

---

## `save_path`

```ini
save_path = "@data/players"
```

**Type:** Path
**Default:** `@data/players`
**Recommended:** Keep on persistent storage and back it up regularly
**Restart required:** Yes

### Description

Specifies where player save data is stored.

This is one of the most important directories on a server because it contains persistent player information.

---

## `configs_path`

```ini
configs_path = "@data/configs"
```

**Type:** Path
**Default:** `@data/configs`
**Recommended:** `@data/configs`
**Restart required:** Yes

### Description

Specifies the directory containing configuration and server data files.

---

## `grand_exchange_data_path`

```ini
grand_exchange_data_path = "@data/eco"
```

**Type:** Path
**Default:** `@data/eco`
**Recommended:** Persistent storage with backups
**Restart required:** Yes

### Description

Specifies where Grand Exchange and economy data is saved.

---

# Drop Table Paths

The following settings point to XML files containing specific drop tables.

These paths are relative to `@data`.

---

## `rare_drop_table_path`

```ini
rare_drop_table_path = "@data/configs/shared_tables/RDT.xml"
```

**Type:** Path
**Default:** `@data/configs/shared_tables/RDT.xml`
**Restart required:** Yes

### Description

Specifies the Rare Drop Table.

`RDT.xml` is stored in:

```text
data/configs/shared_tables/
```

when using the default `data_path`.

---

## `cele_drop_table_path`

```ini
cele_drop_table_path = "@data/configs/shared_tables/CELEDT.xml"
```

**Type:** Path
**Default:** `@data/configs/shared_tables/CELEDT.xml`
**Restart required:** Yes

### Description

Specifies the Chaos Elemental minor drop table.

---

## `uncommon_seed_drop_table_path`

```ini
uncommon_seed_drop_table_path = "@data/configs/shared_tables/USDT.xml"
```

**Type:** Path
**Default:** `@data/configs/shared_tables/USDT.xml`
**Restart required:** Yes

### Description

Specifies the Uncommon Seed Drop Table.

---

## `herb_drop_table_path`

```ini
herb_drop_table_path = "@data/configs/shared_tables/HDT.xml"
```

**Type:** Path
**Default:** `@data/configs/shared_tables/HDT.xml`
**Restart required:** Yes

### Description

Specifies the Herb Drop Table.

---

## `gem_drop_table_path`

```ini
gem_drop_table_path = "@data/configs/shared_tables/GDT.xml"
```

**Type:** Path
**Default:** `@data/configs/shared_tables/GDT.xml`
**Restart required:** Yes

### Description

Specifies the Gem Drop Table.

---

## `rare_seed_drop_table_path`

```ini
rare_seed_drop_table_path = "@data/configs/shared_tables/RSDT.xml"
```

**Type:** Path
**Default:** `@data/configs/shared_tables/RSDT.xml`
**Restart required:** Yes

### Description

Specifies the Rare Seed Drop Table.

---

## `allotment_seed_drop_table_path`

```ini
allotment_seed_drop_table_path = "@data/configs/shared_tables/ASDT.xml"
```

**Type:** Path
**Default:** `@data/configs/shared_tables/ASDT.xml`
**Restart required:** Yes

### Description

Specifies the Allotment Seed Drop Table.

---

# `object_parser_path`

```ini
object_parser_path = "@data/ObjectParser.xml"
```

**Type:** Path
**Default:** `@data/ObjectParser.xml`
**Restart required:** Yes

### Description

Specifies the XML file containing boot-time object changes.

With the default `data_path`, this resolves to:

```text
data/ObjectParser.xml
```

The file is used to apply supported object changes during server startup.

---

# `logs_path`

```ini
logs_path = "@data/logs"
```

**Type:** Path
**Default:** `@data/logs`
**Recommended:** Keep on persistent storage
**Restart required:** Yes

### Description

Specifies where server log files are written.

With the default:

```ini
data_path = "data"
```

the path resolves to:

```text
data/logs
```

---

# `bot_data`

```ini
bot_data = "@data/botdata"
```

**Type:** Path
**Default:** `@data/botdata`
**Recommended:** Keep on persistent storage if bot data needs to survive restarts
**Restart required:** Yes

### Description

Specifies the location of bot-related data.

---

# `eco_data`

```ini
eco_data = "@data/eco"
```

**Type:** Path
**Default:** `@data/eco`
**Recommended:** Keep on persistent storage and back it up
**Restart required:** Yes

### Description

Specifies the economy data directory.

The default configuration points this to the same location as:

```ini
grand_exchange_data_path = "@data/eco"
```

Therefore both settings resolve to:

```text
data/eco
```

when using the default `data_path`.

---

# Recommended Configuration

The following represents the recommended values from a typical customized 2009Scape configuration.

These are **not the upstream defaults**.

```ini
[server]
log_level = "verbose"
secret_key = "2009scape_development"
write_logs = true
msip = "127.0.0.1"
preload_map = false

use_auth = true
persist_accounts = true
noauth_default_admin = true

daily_accounts_per_ip = 9999
watchdog_enabled = true

connectivity_check_url = "https://google.com,https://2009scape.org"
connectivity_timeout = 500

websocket_enabled = false
websocket_port = 0
websocket_tls_enabled = false
websocket_tls_keystore_path = ""
websocket_tls_keystore_password = ""

[database]
database_name = "global"
database_username = "root"
database_password = ""
database_address = "127.0.0.1"
database_port = "3306"

[integrations]
grafana_logging = false
grafana_log_path = "@data/logs"
grafana_log_ttl_days = 7

[world]
name = "2009Scape"
name_ge = "2009Scape"

debug = false
dev = false
start_gui = false
daily_restart = true

world_id = "1"
country_id = "0"
members = true
activity = "2009Scape Classic."
pvp = false

enable_default_clan = true
enable_bots = true

motw_identifier = "0"
motw_text = "Welcome to @name!"

new_player_location = "3094,3107,0"
home_location = "3222,3218,0"

autostock_ge = false
allow_token_purchase = false
skillcape_perks = true
increased_door_time = false

enable_botting = false
max_adv_bots = 100
enable_doubling_money_scammers = true

wild_pvp_enabled = true
jad_practice_enabled = false
enable_global_chat = true

ge_announcement_limit = 500
enable_castle_wars = false
personalized_shops = false
bots_influence_ge_price = true

verbose_cutscene = false
show_rules = true

revenant_population = 30

i_want_to_cheat = false
better_agility_pyramid_gp = false
better_dfs = false

new_player_announcement = true

inauthentic_candlelight_random = false
holiday_event_randoms = false
force_halloween_randoms = false
force_christmas_randoms = false

april_fools_event = false
force_april_fools = false

runecrafting_formula_revision = 530

enhanced_deep_wilderness = false
wilderness_exclusive_loot = false

xp_rates = true
ironman = true

shooting_star_ring = false
second_bank = false
player_commands = true
boosted_trawler_rewards = false

[paths]
data_path = "data"
cache_path = "@data/cache"
store_path = "@data/serverstore"
save_path = "@data/players"
configs_path = "@data/configs"

grand_exchange_data_path = "@data/eco"

rare_drop_table_path = "@data/configs/shared_tables/RDT.xml"
cele_drop_table_path = "@data/configs/shared_tables/CELEDT.xml"
uncommon_seed_drop_table_path = "@data/configs/shared_tables/USDT.xml"
herb_drop_table_path = "@data/configs/shared_tables/HDT.xml"
gem_drop_table_path = "@data/configs/shared_tables/GDT.xml"
rare_seed_drop_table_path = "@data/configs/shared_tables/RSDT.xml"
allotment_seed_drop_table_path = "@data/configs/shared_tables/ASDT.xml"

object_parser_path = "@data/ObjectParser.xml"

logs_path = "@data/logs"
bot_data = "@data/botdata"
eco_data = "@data/eco"
```

---

# Production Configuration

A production server should pay particular attention to authentication, account persistence, database security, and development options.

At minimum, the following should normally be changed from the upstream development defaults:

```ini
use_auth = true
persist_accounts = true
debug = false
dev = false
```

It is also recommended to use:

```ini
noauth_default_admin = false
```

rather than granting administrative privileges to unauthenticated users.

A production database should preferably use a dedicated database account rather than:

```ini
database_username = "root"
```

For example:

```ini
database_username = "2009scape"
database_password = "YOUR_STRONG_DATABASE_PASSWORD"
```

The database account should have only the permissions required by the server.

---

# Development vs. Production

The most important differences between the supplied defaults and a production-oriented configuration are:

| Setting                 | Default | Recommended | Reason                               |
| ----------------------- | ------: | ----------: | ------------------------------------ |
| `use_auth`              | `false` |      `true` | Password authentication              |
| `persist_accounts`      | `false` |      `true` | Persist account-level information    |
| `noauth_default_admin`  |  `true` |     `false` | Prevent unauthenticated admin access |
| `daily_accounts_per_ip` |     `3` |     Depends | Account/IP policy                    |
| `watchdog_enabled`      | `false` |      `true` | Runtime monitoring                   |
| `debug`                 |  `true` |     `false` | Disable development debugging        |
| `dev`                   |  `true` |     `false` | Disable development behavior         |
| `daily_restart`         | `false` |      `true` | Scheduled maintenance cycle          |
| `skillcape_perks`       | `false` |      `true` | Optional enhanced gameplay           |
| `wild_pvp_enabled`      | `false` |      `true` | Enable Wilderness PvP                |
| `enable_global_chat`    | `false` |      `true` | Enable global chat                   |
| `show_rules`            | `false` |      `true` | Show server rules                    |
| `xp_rates`              | `false` |      `true` | Enable Tutorial Island XP selection  |
| `ironman`               | `false` |      `true` | Enable Ironman creation              |
| `player_commands`       | `false` |      `true` | Enable supported player commands     |

The **Recommended** column is not an official 2009Scape requirement. These values represent a practical customized-server configuration.

---

# Important Security Considerations

## Authentication

For a public server:

```ini
use_auth = true
```

should be used.

Leaving authentication disabled means the server does not verify the correctness of the password.

---

## Unauthenticated Administration

The combination:

```ini
use_auth = false
noauth_default_admin = true
```

is particularly important to understand.

It means the server is operating without password authentication while unauthenticated players can be treated as administrators.

This combination is appropriate only for controlled development/testing environments.

---

## Database Credentials

Avoid using the MySQL/MariaDB `root` account for a public production server when possible.

Instead, create a dedicated account:

```ini
database_username = "2009scape"
database_password = "strong-password"
```

---

## Webhook URLs

Never publish active Discord webhook URLs in a public repository.

If a webhook is accidentally exposed, it should be revoked and replaced.

---

## TLS Keystores

If WebSocket TLS is enabled, protect:

```text
.p12
```

keystore files and their passwords.

Do not commit private TLS credentials to GitHub.

---

# Backup Recommendations

The most important server data should be backed up regularly.

## Player Saves

```text
data/players/
```

This should be considered critical data.

A loss of this directory can result in loss of player progression.

---

## Economy Data

```text
data/eco/
```

This contains economy/Grand Exchange-related information.

Because both:

```ini
grand_exchange_data_path = "@data/eco"
eco_data = "@data/eco"
```

point to the same location, this directory should also be included in backups.

---

## Configuration

Back up:

```text
default.conf
```

as well as customized configuration files under:

```text
data/configs/
```

---

## Suggested Backup Structure

A backup directory could look like:

```text
backups/
├── config/
│   └── default.conf
├── players/
├── economy/
└── configs/
```

For an active server, automated backups are preferable to manual backups.

---

# Quick Reference

## Server

| Setting                 | Default                 | Recommended                |
| ----------------------- | ----------------------- | -------------------------- |
| `log_level`             | `verbose`               | `verbose` / `detailed`     |
| `secret_key`            | `2009scape_development` | Matching client/server key |
| `write_logs`            | `true`                  | `true`                     |
| `msip`                  | `127.0.0.1`             | `127.0.0.1`                |
| `preload_map`           | `false`                 | `false`                    |
| `use_auth`              | `false`                 | `true`                     |
| `persist_accounts`      | `false`                 | `true`                     |
| `noauth_default_admin`  | `true`                  | `false`                    |
| `daily_accounts_per_ip` | `3`                     | Depends                    |
| `watchdog_enabled`      | `false`                 | `true`                     |
| `connectivity_timeout`  | `500`                   | `500`                      |

## Database

| Setting             | Default     | Recommended          |
| ------------------- | ----------- | -------------------- |
| `database_name`     | `global`    | Your database        |
| `database_username` | `root`      | Dedicated user       |
| `database_password` | Empty       | Strong password      |
| `database_address`  | `127.0.0.1` | `127.0.0.1` if local |
| `database_port`     | `3306`      | `3306`               |

## World

| Setting              | Default     | Recommended     |
| -------------------- | ----------- | --------------- |
| `name`               | `2009Scape` | `2009Scape`     |
| `name_ge`            | `2009Scape` | `2009Scape`     |
| `debug`              | `true`      | `false`         |
| `dev`                | `true`      | `false`         |
| `start_gui`          | `false`     | `false`         |
| `daily_restart`      | `false`     | `true`          |
| `world_id`           | `1`         | Unique world ID |
| `members`            | `true`      | Depends         |
| `pvp`                | `false`     | Depends         |
| `enable_bots`        | `true`      | Depends         |
| `enable_botting`     | `false`     | Depends         |
| `wild_pvp_enabled`   | `false`     | Depends         |
| `enable_global_chat` | `false`     | Depends         |
| `show_rules`         | `false`     | `true`          |
| `xp_rates`           | `false`     | Depends         |
| `ironman`            | `false`     | Depends         |
| `player_commands`    | `false`     | Depends         |

## Paths

| Setting                    | Default             |
| -------------------------- | ------------------- |
| `data_path`                | `data`              |
| `cache_path`               | `@data/cache`       |
| `store_path`               | `@data/serverstore` |
| `save_path`                | `@data/players`     |
| `configs_path`             | `@data/configs`     |
| `grand_exchange_data_path` | `@data/eco`         |
| `logs_path`                | `@data/logs`        |
| `bot_data`                 | `@data/botdata`     |
| `eco_data`                 | `@data/eco`         |

---

# Summary

The 2009Scape `default.conf` is primarily a **development-oriented starting configuration**.

Several of its defaults intentionally favor convenience over security or persistence:

```ini
use_auth = false
persist_accounts = false
debug = true
dev = true
daily_restart = false
watchdog_enabled = false
```

For a production server, these settings should be reviewed carefully.

The most important production changes are:

```ini
use_auth = true
persist_accounts = true
noauth_default_admin = false
debug = false
dev = false
```

Other options, such as:

```ini
skillcape_perks
wild_pvp_enabled
enable_global_chat
show_rules
xp_rates
ironman
player_commands
```

are primarily **gameplay decisions** rather than security requirements. Their appropriate values depend on the ruleset you want your 2009Scape world to provide.

The standard world identity is:

```ini
name = "2009Scape"
name_ge = "2009Scape"
```

and paths using `@data` are resolved relative to:

```ini
data_path = "data"
```

making the configuration relatively easy to relocate while keeping the server's cache, player saves, logs, economy data, bot data, and configuration files organized under one data directory.
