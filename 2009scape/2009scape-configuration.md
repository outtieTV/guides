# 2009Scape `default.conf` Configuration Reference

This document provides a detailed reference for the `default.conf` configuration file used by the **2009Scape** server.

The configuration controls:

* Server logging
* Authentication
* Account persistence
* Database connectivity
* WebSocket connectivity
* Optional integrations
* World identity
* Bots
* Grand Exchange behavior
* PvP and Wilderness mechanics
* Skills and progression
* Random events
* Custom gameplay features
* Player saves
* Server logs
* Economy data
* Drop tables
* Other server data

> **Configuration version:** This documentation is based on the `default.conf` structure supplied with the 2009Scape server.
>
> **Important:** Configuration options can change between 2009Scape releases. If an option is added, removed, or renamed upstream, use the `default.conf` included with your version of the server as the authoritative reference.

---

# Table of Contents

* [Configuration Conventions](#configuration-conventions)
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
  * [`websocket_enabled`](#websocket_enabled)
  * [`websocket_port`](#websocket_port)
  * [`websocket_tls_enabled`](#websocket_tls_enabled)
  * [`websocket_tls_keystore_path`](#websocket_tls_keystore_path)
  * [`websocket_tls_keystore_password`](#websocket_tls_keystore_password)
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
  * [Discord/OpenRSC Webhooks](#discordopenrsc-webhooks)
* [`[world]`](#world)

  * [World Identity](#world-identity)
  * [Development Options](#development-options)
  * [Player Settings](#player-settings)
  * [Bot Settings](#bot-settings)
  * [Grand Exchange](#grand-exchange)
  * [PvP and Wilderness](#pvp-and-wilderness)
  * [Gameplay Modifications](#gameplay-modifications)
  * [Random Events](#random-events)
  * [Skills and Progression](#skills-and-progression)
  * [Custom Content](#custom-content)
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
* [Development Configuration](#development-configuration)
* [Production Configuration](#production-configuration)
* [Backup Recommendations](#backup-recommendations)

---

# Configuration Conventions

The configuration uses several basic value types.

| Type       | Example                | Description                   |
| ---------- | ---------------------- | ----------------------------- |
| Boolean    | `true` / `false`       | Enables or disables a feature |
| String     | `"2009Scape"`          | Text or path value            |
| Integer    | `100`                  | Whole-number value            |
| Coordinate | `"3094,3107,0"`        | X, Y, Plane                   |
| Path       | `"@data/logs"`         | File-system path              |
| URL        | `"https://google.com"` | Internet address              |

## Boolean values

Boolean settings generally use:

```ini
true
```

or:

```ini
false
```

For example:

```ini
enable_bots = true
```

---

# `[server]`

The `[server]` section controls core server functionality, logging, authentication, connectivity, and WebSocket support.

---

## `log_level`

```ini
log_level = "verbose"
```

**Type:** String
**Default:** `verbose`
**Recommended:** `verbose` during development; `detailed` or `cautious` for quieter production logs
**Requires restart:** Yes

### Description

Controls the amount of information written to the server log.

Available levels:

| Level      | Behavior                         |
| ---------- | -------------------------------- |
| `verbose`  | Shows all available logs         |
| `detailed` | Hides `FINE` messages            |
| `cautious` | Hides `FINE` and `INFO` messages |
| `silent`   | Shows only errors                |

### Recommended development value

```ini
log_level = "verbose"
```

This is particularly useful while troubleshooting scripts, database problems, networking, or gameplay issues.

### Production considerations

A less verbose level can substantially reduce log volume on a busy server.

---

## `secret_key`

```ini
secret_key = "2009scape_development"
```

**Type:** String
**Default:** `2009scape_development`
**Recommended:** Keep client and server values synchronized
**Requires restart:** Yes

### Description

The secret key is sent by the client during the login process.

The **client and server must have matching secret keys**. If the keys do not match, the connection is refused.

Example:

```ini
secret_key = "2009scape_development"
```

### Important

Changing this value requires the corresponding client configuration to use the same value.

Do not accidentally change the server key without changing the client.

---

## `write_logs`

```ini
write_logs = true
```

**Type:** Boolean
**Default:** `true`
**Recommended:** `true`
**Requires restart:** Yes

### Description

Controls whether server logs are written to disk.

When enabled:

```ini
write_logs = true
```

logs can be examined after the server has stopped.

When disabled:

```ini
write_logs = false
```

the server does not persist its normal logs to disk.

The location of log files is controlled by:

```ini
logs_path = "@data/logs"
```

---

## `msip`

```ini
msip = "127.0.0.1"
```

**Type:** String/IP address
**Default:** `127.0.0.1`
**Recommended:** `127.0.0.1` for a local installation
**Requires restart:** Yes

### Description

Specifies the management/server IP address.

`127.0.0.1` is the IPv4 loopback address and refers to the local machine.

For a normal single-machine installation:

```ini
msip = "127.0.0.1"
```

is generally appropriate.

---

## `preload_map`

```ini
preload_map = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` unless additional memory is available
**Requires restart:** Yes

### Description

Controls whether map data is preloaded into memory.

The configuration notes that enabling this option increases memory usage by approximately **2 GB**, while potentially making game ticks smoother.

### Disabled

```ini
preload_map = false
```

Advantages:

* Lower memory usage
* Lower startup memory requirements
* Better suited to smaller servers

### Enabled

```ini
preload_map = true
```

Advantages:

* More map data is immediately available
* Can reduce map-loading-related delays
* May improve game-tick smoothness

### Recommendation

For a development server or machine with limited RAM:

```ini
preload_map = false
```

For a dedicated server with sufficient memory, testing `true` may be worthwhile.

---

## `use_auth`

```ini
use_auth = true
```

**Type:** Boolean
**Default:** `true`
**Recommended:** `true`
**Requires restart:** Yes

### Description

Controls whether player passwords are actually checked during login.

When enabled:

```ini
use_auth = true
```

the supplied password must match the stored password.

Passwords are hashed before being stored.

When disabled:

```ini
use_auth = false
```

the server does not require the supplied password to be correct.

### Production

**This should be `true` on a production server.**

---

## `persist_accounts`

```ini
persist_accounts = true
```

**Type:** Boolean
**Default:** `true`
**Recommended:** `true`
**Requires restart:** Yes

### Description

Controls whether account-level information is persisted.

This includes information such as:

* Credits
* Playtime
* Other account-level data

### Important distinction

This setting does **not** control normal character save data such as:

* Skills
* Inventory
* Equipment
* Character progression

Those are handled separately by the player save system.

### Production

Use:

```ini
persist_accounts = true
```

for a production server.

---

## `noauth_default_admin`

```ini
noauth_default_admin = true
```

**Type:** Boolean
**Default:** `true`
**Recommended:** `false` for public servers
**Requires restart:** Yes

### Description

Determines whether players are treated as administrators when authentication is disabled.

This option is primarily relevant when:

```ini
use_auth = false
```

A development configuration might use:

```ini
use_auth = false
noauth_default_admin = true
```

This can make testing convenient.

### Security warning

Never combine unrestricted no-authentication access with public Internet access unless you intentionally want every connecting player to receive administrative privileges.

For a production server:

```ini
use_auth = true
noauth_default_admin = false
```

is the safer configuration.

---

## `daily_accounts_per_ip`

```ini
daily_accounts_per_ip = 9999
```

**Type:** Integer
**Default:** `9999` in the supplied configuration
**Recommended:** Depends on server policy
**Requires restart:** Yes

### Description

Controls the maximum number of different accounts that a single IP address may log into during a day.

Example:

```ini
daily_accounts_per_ip = 5
```

would permit five different accounts from the same IP during the applicable period.

A value of:

```ini
daily_accounts_per_ip = 9999
```

effectively makes the restriction extremely high.

### Considerations

This can help limit:

* Large-scale account creation
* Account abuse
* Automated account activity

However, legitimate users behind shared networks may also share an IP address.

---

## `watchdog_enabled`

```ini
watchdog_enabled = true
```

**Type:** Boolean
**Default:** `true`
**Recommended:** `true`
**Requires restart:** Yes

### Description

Enables the server watchdog.

The watchdog monitors server operation and can detect situations where the server becomes unresponsive or unhealthy.

Leaving it enabled is generally appropriate for a long-running server.

---

## `connectivity_check_url`

```ini
connectivity_check_url = "https://google.com,https://2009scape.org"
```

**Type:** Comma-separated URL list
**Default:** Configuration-dependent
**Recommended:** Use reliable external endpoints
**Requires restart:** Yes

### Description

Specifies URLs used to check external connectivity.

Multiple URLs can be supplied by separating them with commas:

```ini
connectivity_check_url = "https://google.com,https://2009scape.org"
```

Using multiple endpoints can help avoid relying entirely on one external service.

---

## `connectivity_timeout`

```ini
connectivity_timeout = 500
```

**Type:** Integer
**Unit:** Milliseconds
**Default:** `500` in the supplied configuration
**Recommended:** `500` or higher for slower networks
**Requires restart:** Yes

### Description

Specifies how long the connectivity check waits for a response.

For example:

```ini
connectivity_timeout = 500
```

represents a 500 millisecond timeout.

Increasing this value gives slower connections more time to respond.

---

# WebSocket Settings

The WebSocket system allows browser-based clients to communicate with the server.

The WebSocket transport carries the same raw binary protocol used by the TCP connection, with WebSocket binary frames treated as byte chunks.

---

## `websocket_enabled`

```ini
websocket_enabled = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` unless using a browser client
**Requires restart:** Yes

### Description

Enables the WebSocket listener.

Disabled:

```ini
websocket_enabled = false
```

Enabled:

```ini
websocket_enabled = true
```

Browser-based clients generally require this transport because browsers cannot establish arbitrary raw TCP connections.

---

## `websocket_port`

```ini
websocket_port = 0
```

**Type:** Integer
**Default:** `0`
**Recommended:** `0` unless a fixed port is required
**Requires restart:** Yes

### Description

Controls the WebSocket listening port.

A value of:

```ini
websocket_port = 0
```

causes the server to calculate the port automatically:

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

A specific port can also be assigned:

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
**Recommended:** `true` for public browser deployments using TLS
**Requires restart:** Yes

### Description

Enables TLS encryption for WebSocket connections.

Disabled:

```ini
websocket_tls_enabled = false
```

uses:

```text
ws://
```

Enabled:

```ini
websocket_tls_enabled = true
```

uses:

```text
wss://
```

For a browser client served from HTTPS, secure WebSockets (`wss://`) are generally required.

---

## `websocket_tls_keystore_path`

```ini
websocket_tls_keystore_path = ""
```

**Type:** String/path
**Default:** Empty
**Recommended:** Required when TLS is enabled
**Requires restart:** Yes

### Description

Specifies the PKCS#12 (`.p12`) keystore containing the certificate and private key used by the WebSocket TLS listener.

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
**Recommended:** Use a protected password when applicable
**Requires restart:** Yes

### Description

Specifies the password used to open the PKCS#12 keystore.

For a PKCS#12 file exported without a password, this can remain empty:

```ini
websocket_tls_keystore_password = ""
```

---

# `[database]`

The `[database]` section controls the SQL database connection.

---

## `database_name`

```ini
database_name = "global"
```

**Type:** String
**Default:** `global` in the supplied configuration
**Recommended:** Database containing the 2009Scape schema
**Requires restart:** Yes

### Description

Specifies the database/schema the server uses.

Example:

```ini
database_name = "global"
```

The database must already exist and contain the required 2009Scape database structure.

---

## `database_username`

```ini
database_username = "root"
```

**Type:** String
**Default:** `root` in the supplied configuration
**Recommended:** Dedicated 2009Scape database account
**Requires restart:** Yes

### Description

Specifies the SQL account used by the server.

The supplied default uses:

```ini
database_username = "root"
```

For production, a dedicated account is preferable.

For example:

```ini
database_username = "2009scape"
```

This limits the privileges available to the application.

---

## `database_password`

```ini
database_password = ""
```

**Type:** String
**Default:** Empty
**Recommended:** Strong password
**Requires restart:** Yes

### Description

Specifies the SQL account password.

Example:

```ini
database_username = "2009scape"
database_password = "strong-password-here"
```

Avoid leaving the database account password empty on a production server.

---

## `database_address`

```ini
database_address = "127.0.0.1"
```

**Type:** IP address/hostname
**Default:** `127.0.0.1`
**Recommended:** `127.0.0.1` for local database
**Requires restart:** Yes

### Description

Specifies the machine running MySQL/MariaDB.

For a local database:

```ini
database_address = "127.0.0.1"
```

For a remote database:

```ini
database_address = "192.168.1.50"
```

---

## `database_port`

```ini
database_port = "3306"
```

**Type:** String/integer port
**Default:** `3306`
**Recommended:** `3306` unless your database uses another port
**Requires restart:** Yes

### Description

Specifies the SQL server's TCP port.

The standard MySQL/MariaDB port is:

```text
3306
```

---

# `[integrations]`

This section contains optional external integrations.

---

## `grafana_logging`

```ini
grafana_logging = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` unless using Grafana logging
**Requires restart:** Yes

### Description

Enables logging intended for Grafana-based monitoring.

If Grafana logging is not being used:

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
**Recommended:** Keep inside the server data directory
**Requires restart:** Yes

### Description

Specifies where Grafana-related logs are stored.

With:

```ini
data_path = "data"
```

the path resolves to:

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
**Requires restart:** Yes

### Description

Controls how long Grafana log data is retained.

Data older than the configured number of days is pruned during server startup.

Example:

```ini
grafana_log_ttl_days = 30
```

keeps approximately 30 days of data.

---

# Discord/OpenRSC Webhooks

The configuration contains optional webhook integrations:

```ini
#discord_ge_webhook = "webhook link"
#discord_moderation_webhook = "webhook link"
#openrsc_integration_webhook = "webhook link"
```

**Type:** URL
**Default:** Disabled/commented out
**Recommended:** Leave disabled unless required
**Requires restart:** Yes

### `discord_ge_webhook`

Can be used for supported Grand Exchange notifications.

### `discord_moderation_webhook`

Can be used for supported moderation notifications.

### `openrsc_integration_webhook`

Can be used for supported OpenRSC integration.

### Security

Webhook URLs should be treated as credentials.

Do not commit active webhook URLs to a public GitHub repository.

---

# `[world]`

The `[world]` section controls the actual game world.

---

# World Identity

## `name`

```ini
name = "2009Scape"
```

**Type:** String
**Default:** `2009Scape`
**Recommended:** `2009Scape` for the standard server name
**Requires restart:** Yes

### Description

Specifies the name of the game world.

The standard/default world name is:

```ini
name = "2009Scape"
```

This name is used by systems that refer to the world.

---

## `name_ge`

```ini
name_ge = "2009Scape"
```

**Type:** String
**Default:** `2009Scape`
**Recommended:** Match `name` unless intentionally different
**Requires restart:** Yes

### Description

Specifies the world name used in Grand Exchange announcements involving bots selling items.

For the standard configuration:

```ini
name = "2009Scape"
name_ge = "2009Scape"
```

---

## `debug`

```ini
debug = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` in production
**Requires restart:** Yes

### Description

Enables debugging functionality.

Useful during development and troubleshooting, but generally unnecessary during normal operation.

---

## `dev`

```ini
dev = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` in production
**Requires restart:** Yes

### Description

Enables development-oriented server behavior.

This should normally remain disabled on a public server.

---

## `start_gui`

```ini
start_gui = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` for headless servers
**Requires restart:** Yes

### Description

Controls whether the server starts its graphical interface.

For command-line/server-hosting environments:

```ini
start_gui = false
```

is generally appropriate.

---

## `daily_restart`

```ini
daily_restart = true
```

**Type:** Boolean
**Default:** `true`
**Recommended:** `true` for long-running servers
**Requires restart:** Yes

### Description

Enables the server's daily restart behavior.

A daily restart can provide a predictable maintenance cycle and help clear accumulated runtime state.

---

## `world_id`

```ini
world_id = "1"
```

**Type:** String/integer
**Default:** `1`
**Recommended:** Unique ID for each world
**Requires restart:** Yes

### Description

Specifies the world number.

For the default world:

```ini
world_id = "1"
```

The world ID can also affect automatically calculated ports.

---

## `country_id`

```ini
country_id = "0"
```

**Type:** String/integer
**Default:** `0`
**Recommended:** Use the appropriate world-list value
**Requires restart:** Yes

### Description

Identifies the country/region associated with the world in world-list metadata.

---

## `members`

```ini
members = true
```

**Type:** Boolean
**Default:** `true` in the supplied configuration
**Recommended:** Depends on world design
**Requires restart:** Yes

### Description

Determines whether the world is treated as a members-enabled world.

---

## `activity`

```ini
activity = "2009Scape Classic."
```

**Type:** String
**Default:** `2009Scape Classic.`
**Recommended:** Describe the world accurately
**Requires restart:** Yes

### Description

Text displayed as the world's activity/status in the world list.

---

# Player Settings

## `enable_default_clan`

```ini
enable_default_clan = true
```

**Type:** Boolean
**Default:** `true`
**Recommended:** Depends on whether the default clan has been configured
**Requires restart:** Yes

### Description

Enables a default clan that players can automatically join.

The configured world name is relevant because the configuration expects an account with the same name as `@name` to have an appropriate clan configured.

For the default configuration:

```ini
name = "2009Scape"
enable_default_clan = true
```

---

## `new_player_location`

```ini
new_player_location = "3094,3107,0"
```

**Type:** Coordinate string
**Default:** `3094,3107,0`
**Recommended:** Desired Tutorial Island/new-player spawn
**Requires restart:** Yes

### Format

```text
X,Y,Plane
```

Example:

```text
3094,3107,0
```

---

## `home_location`

```ini
home_location = "3222,3218,0"
```

**Type:** Coordinate string
**Default:** `3222,3218,0`
**Recommended:** Desired home-teleport destination
**Requires restart:** Yes

### Format

```text
X,Y,Plane
```

---

## `show_rules`

```ini
show_rules = true
```

**Type:** Boolean
**Default:** `true`
**Recommended:** `true`
**Requires restart:** Yes

### Description

Displays the server rules the first time a player logs in.

This is particularly useful for custom servers with additional rules.

---

## `new_player_announcement`

```ini
new_player_announcement = true
```

**Type:** Boolean
**Default:** `true`
**Recommended:** Depends on desired chat behavior
**Requires restart:** Yes

### Description

Controls announcements for newly arriving players.

---

## `enable_global_chat`

```ini
enable_global_chat = true
```

**Type:** Boolean
**Default:** `true`
**Recommended:** `true` if global chat is desired
**Requires restart:** Yes

### Description

Enables the global chat system.

---

## `player_commands`

```ini
player_commands = true
```

**Type:** Boolean
**Default:** `true`
**Recommended:** Depends on server policy
**Requires restart:** Yes

### Description

Enables inauthentic but non-dangerous commands for regular players.

These commands are intended as convenience/custom functionality rather than historical game behavior.

---

# Bot Settings

## `enable_bots`

```ini
enable_bots = true
```

**Type:** Boolean
**Default:** `true`
**Recommended:** `true` if using the bot ecosystem
**Requires restart:** Yes

### Description

Enables server bots.

---

## `enable_botting`

```ini
enable_botting = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` unless intentionally supporting botting
**Requires restart:** Yes

### Description

Enables supported player botting functionality.

This is distinct from:

```ini
enable_bots = true
```

which controls server bots.

---

## `max_adv_bots`

```ini
max_adv_bots = 100
```

**Type:** Integer
**Default:** `100`
**Recommended:** Based on available CPU/RAM
**Requires restart:** Yes

### Description

Sets the maximum number of advanced bots that may be active.

Higher values can increase resource consumption.

---

# Grand Exchange

## `autostock_ge`

```ini
autostock_ge = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** Depends on desired economy behavior
**Requires restart:** Yes

### Description

Enables automatic Grand Exchange stocking behavior.

---

## `allow_token_purchase`

```ini
allow_token_purchase = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** Depends on server design
**Requires restart:** Yes

### Description

Enables supported token-purchase functionality.

---

## `bots_influence_ge_price`

```ini
bots_influence_ge_price = true
```

**Type:** Boolean
**Default:** `true`
**Recommended:** `true` for a bot-driven economy
**Requires restart:** Yes

### Description

Determines whether bot activity contributes to Grand Exchange pricing.

---

## `ge_announcement_limit`

```ini
ge_announcement_limit = 500
```

**Type:** Integer
**Unit:** High-alchemy value
**Default:** `500`
**Recommended:** Depends on desired announcement volume
**Requires restart:** Yes

### Description

Sets the minimum high-alchemy value for bot Grand Exchange sale announcements.

---

## `personalized_shops`

```ini
personalized_shops = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` unless specifically required
**Requires restart:** Yes

### Description

Enables personalized shop behavior.

---

# PvP and Wilderness

## `pvp`

```ini
pvp = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** Depends on world type
**Requires restart:** Yes

### Description

Controls whether the world itself is configured as a PvP world.

---

## `wild_pvp_enabled`

```ini
wild_pvp_enabled = true
```

**Type:** Boolean
**Default:** `true`
**Recommended:** Depends on desired Wilderness behavior
**Requires restart:** Yes

### Description

Enables the supported Wilderness PvP functionality.

This is separate from the overall `pvp` world setting.

---

## `enhanced_deep_wilderness`

```ini
enhanced_deep_wilderness = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` for a more standard ruleset
**Requires restart:** Yes

### Description

Enables the enhanced deep Wilderness.

The configuration describes this as applying a red skull beyond the members' fence and increasing certain brawler/PvP drop rates.

---

## `wilderness_exclusive_loot`

```ini
wilderness_exclusive_loot = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** Depends on desired loot system
**Requires restart:** Yes

### Description

Enables Wilderness-exclusive loot from supported monsters such as Revenants and the Chaos Elemental.

Examples include:

* Brawling gloves
* PvP equipment

---

## `revenant_population`

```ini
revenant_population = 30
```

**Type:** Integer
**Default:** `30`
**Recommended:** Depends on server population
**Requires restart:** Yes

### Description

Controls how many Revenants are active at a time.

Higher values increase Wilderness NPC population and may increase server load.

---

# Gameplay Modifications

## `skillcape_perks`

```ini
skillcape_perks = true
```

**Type:** Boolean
**Default:** `true`
**Recommended:** Depends on desired ruleset
**Requires restart:** Yes

### Description

Enables skillcape perks.

---

## `increased_door_time`

```ini
increased_door_time = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` for standard behavior
**Requires restart:** Yes

### Description

Enables increased door-open timing.

---

## `enable_doubling_money_scammers`

```ini
enable_doubling_money_scammers = true
```

**Type:** Boolean
**Default:** `true`
**Recommended:** Depends on desired world behavior
**Requires restart:** Yes

### Description

Controls the supported doubling-money scam-related gameplay.

---

## `jad_practice_enabled`

```ini
jad_practice_enabled = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` unless used as a training feature
**Requires restart:** Yes

### Description

Enables the Jad practice functionality.

This is useful for players who want to practice against TzTok-Jad without completing a standard Fight Caves run.

---

## `better_agility_pyramid_gp`

```ini
better_agility_pyramid_gp = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` for standard behavior
**Requires restart:** Yes

### Description

Enables the enhanced Agility Pyramid reward.

The configured formula is:

```text
GP = 1000 + ((Agility Level / 99) × 9000)
```

The reward therefore scales with Agility level.

---

## `better_dfs`

```ini
better_dfs = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` for standard behavior
**Requires restart:** Yes

### Description

Changes the Dragonfire Shield special attack cooldown.

When enabled, the documented cooldown is approximately:

```text
30 seconds
```

instead of:

```text
2 minutes
```

---

## `i_want_to_cheat`

```ini
i_want_to_cheat = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` for normal multiplayer servers
**Requires restart:** Yes

### Description

Enables supported cheat functionality.

This is primarily intended for testing, development, or special-purpose environments.

---

## `enable_castle_wars`

```ini
enable_castle_wars = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** Depends on whether Castle Wars is being used
**Requires restart:** Yes

### Description

Enables Castle Wars functionality.

---

# Random Events

## `inauthentic_candlelight_random`

```ini
inauthentic_candlelight_random = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` for a more authentic ruleset
**Requires restart:** Yes

### Description

Adds the Candlelight random event as an additional normal random event.

The configuration explicitly identifies this as inauthentic content.

---

## `holiday_event_randoms`

```ini
holiday_event_randoms = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** Depends on desired event availability
**Requires restart:** Yes

### Description

Enables holiday random events.

---

## `force_halloween_randoms`

```ini
force_halloween_randoms = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` except during testing/event periods
**Requires restart:** Yes

### Description

Forces Halloween random events.

Only one forced holiday random should be enabled at a time.

---

## `force_christmas_randoms`

```ini
force_christmas_randoms = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` except during testing/event periods
**Requires restart:** Yes

### Description

Forces Christmas random events.

---

## `april_fools_event`

```ini
april_fools_event = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` except during event/testing periods
**Requires restart:** Yes

### Description

Enables the April Fools event.

---

## `force_april_fools`

```ini
force_april_fools = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false`
**Requires restart:** Yes

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
**Recommended:** Match the intended historical ruleset
**Requires restart:** Yes

### Description

Determines which Runecrafting formula revision is used.

The configuration notes:

* Revision 573 introduced probabilistic multiple-rune production.
* Revision 581 extrapolated probabilistic rune production beyond level 99.

Therefore, this setting controls an important aspect of Runecrafting production rates.

---

## `xp_rates`

```ini
xp_rates = true
```

**Type:** Boolean
**Default:** `true`
**Recommended:** Depends on desired progression system
**Requires restart:** Yes

### Description

Enables XP-rate selection on Tutorial Island.

---

## `ironman`

```ini
ironman = true
```

**Type:** Boolean
**Default:** `true`
**Recommended:** `true` if Ironman creation is desired
**Requires restart:** Yes

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
**Recommended:** `false` for standard content
**Requires restart:** Yes

### Description

Enables the custom-content Ancient Blueprint and Ring of the Star Sprite.

This is explicitly identified as custom content.

---

## `second_bank`

```ini
second_bank = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** Depends on desired storage system
**Requires restart:** Yes

### Description

Enables a second bank.

---

## `boosted_trawler_rewards`

```ini
boosted_trawler_rewards = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` for standard rewards
**Requires restart:** Yes

### Description

Increases Fishing Trawler rewards.

The configuration specifically mentions:

* Key halves
* Pirate outfit pieces

---

## `verbose_cutscene`

```ini
verbose_cutscene = false
```

**Type:** Boolean
**Default:** `false`
**Recommended:** `false` during normal operation
**Requires restart:** Yes

### Description

Enables verbose logging for cutscenes using the newer cutscene system.

Useful when troubleshooting cutscene behavior.

---

# `[paths]`

The `[paths]` section controls where 2009Scape stores its files.

A typical layout is:

```text
data/
├── cache/
├── configs/
├── eco/
├── logs/
├── players/
├── serverstore/
└── botdata/
```

---

# `@data` Path Variable

The special value:

```text
@data
```

refers to the path specified by:

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

This makes it possible to relocate the entire data directory without changing every individual path.

---

## `data_path`

```ini
data_path = "data"
```

**Type:** Path
**Default:** `data`
**Recommended:** `data` unless using a custom layout
**Requires restart:** Yes

### Description

Defines the root directory for server data.

Most other paths use `@data` so that they automatically follow this setting.

---

## `cache_path`

```ini
cache_path = "@data/cache"
```

**Type:** Path
**Default:** `@data/cache`
**Recommended:** Keep under `data_path`
**Requires restart:** Yes

### Description

Specifies the location of cache data.

---

## `store_path`

```ini
store_path = "@data/serverstore"
```

**Type:** Path
**Default:** `@data/serverstore`
**Recommended:** Keep under `data_path`
**Requires restart:** Yes

### Description

Specifies the server's persistent store directory.

---

## `save_path`

```ini
save_path = "@data/players"
```

**Type:** Path
**Default:** `@data/players`
**Recommended:** Keep on persistent storage and back it up
**Requires restart:** Yes

### Description

Specifies where player save data is stored.

This is one of the most important directories to back up.

---

## `configs_path`

```ini
configs_path = "@data/configs"
```

**Type:** Path
**Default:** `@data/configs`
**Recommended:** `@data/configs`
**Requires restart:** Yes

### Description

Specifies the directory containing server configuration/data files.

---

## `grand_exchange_data_path`

```ini
grand_exchange_data_path = "@data/eco"
```

**Type:** Path
**Default:** `@data/eco`
**Recommended:** Persistent storage
**Requires restart:** Yes

### Description

Specifies where Grand Exchange/economy data is stored.

---

# Drop Table Paths

These settings specify the XML files containing various drop tables.

---

## `rare_drop_table_path`

```ini
rare_drop_table_path = "@data/configs/shared_tables/RDT.xml"
```

**Type:** Path
**Default:** `@data/configs/shared_tables/RDT.xml`
**Requires restart:** Yes

### Description

Specifies the Rare Drop Table (RDT).

---

## `cele_drop_table_path`

```ini
cele_drop_table_path = "@data/configs/shared_tables/CELEDT.xml"
```

**Type:** Path
**Default:** `@data/configs/shared_tables/CELEDT.xml`
**Requires restart:** Yes

### Description

Specifies the Chaos Elemental minor drop table.

---

## `uncommon_seed_drop_table_path`

```ini
uncommon_seed_drop_table_path = "@data/configs/shared_tables/USDT.xml"
```

**Type:** Path
**Default:** `@data/configs/shared_tables/USDT.xml`
**Requires restart:** Yes

### Description

Specifies the Uncommon Seed Drop Table.

---

## `herb_drop_table_path`

```ini
herb_drop_table_path = "@data/configs/shared_tables/HDT.xml"
```

**Type:** Path
**Default:** `@data/configs/shared_tables/HDT.xml`
**Requires restart:** Yes

### Description

Specifies the Herb Drop Table.

---

## `gem_drop_table_path`

```ini
gem_drop_table_path = "@data/configs/shared_tables/GDT.xml"
```

**Type:** Path
**Default:** `@data/configs/shared_tables/GDT.xml`
**Requires restart:** Yes

### Description

Specifies the Gem Drop Table.

---

## `rare_seed_drop_table_path`

```ini
rare_seed_drop_table_path = "@data/configs/shared_tables/RSDT.xml"
```

**Type:** Path
**Default:** `@data/configs/shared_tables/RSDT.xml`
**Requires restart:** Yes

### Description

Specifies the Rare Seed Drop Table.

---

## `allotment_seed_drop_table_path`

```ini
allotment_seed_drop_table_path = "@data/configs/shared_tables/ASDT.xml"
```

**Type:** Path
**Default:** `@data/configs/shared_tables/ASDT.xml`
**Requires restart:** Yes

### Description

Specifies the Allotment Seed Drop Table.

---

# `object_parser_path`

```ini
object_parser_path = "@data/ObjectParser.xml"
```

**Type:** Path
**Default:** `@data/ObjectParser.xml`
**Requires restart:** Yes

### Description

Specifies the XML file containing boot-time object changes.

The server reads this file during startup to apply supported object modifications.

---

# `logs_path`

```ini
logs_path = "@data/logs"
```

**Type:** Path
**Default:** `@data/logs`
**Requires restart:** Yes

### Description

Specifies where server log files are stored.

With:

```ini
data_path = "data"
```

this becomes:

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
**Requires restart:** Yes

### Description

Specifies the directory used for bot-related data.

---

# `eco_data`

```ini
eco_data = "@data/eco"
```

**Type:** Path
**Default:** `@data/eco`
**Requires restart:** Yes

### Description

Specifies the economy data directory.

In the default configuration, this points to the same location as:

```ini
grand_exchange_data_path = "@data/eco"
```

---

# Development Configuration

A development server may intentionally use more permissive settings.

For example:

```ini
[server]
log_level = "verbose"
write_logs = true
use_auth = false
persist_accounts = false
noauth_default_admin = true
preload_map = false
watchdog_enabled = true

[world]
name = "2009Scape"
name_ge = "2009Scape"
debug = true
dev = true
start_gui = false
```

This type of configuration is useful when developing scripts, testing gameplay, or debugging the server.

However, it should **not** be copied directly to a public production server.

---

# Production Configuration

A production server should normally prioritize authentication, persistent data, secure database access, and controlled logging.

A basic example is:

```ini
[server]
log_level = "detailed"
write_logs = true
use_auth = true
persist_accounts = true
noauth_default_admin = false
preload_map = false
watchdog_enabled = true

[database]
database_name = "global"
database_username = "2009scape"
database_password = "YOUR_DATABASE_PASSWORD"
database_address = "127.0.0.1"
database_port = "3306"

[world]
name = "2009Scape"
name_ge = "2009Scape"
debug = false
dev = false
start_gui = false
daily_restart = true
world_id = "1"
```

The exact production configuration should be adapted to the server's intended gameplay rules and infrastructure.

---

# Backup Recommendations

At minimum, regularly back up:

```text
data/players/
```

This contains persistent player save data.

Also consider backing up:

```text
data/eco/
```

which contains economy/Grand Exchange information.

You should also preserve your:

```text
default.conf
```

and any customized files under:

```text
data/configs/
```

A useful backup structure might be:

```text
backups/
├── config/
│   └── default.conf
├── players/
├── economy/
└── configs/
```

---

# Quick Reference

| Setting                    | Type     | Main Purpose                       |
| -------------------------- | -------- | ---------------------------------- |
| `log_level`                | String   | Logging verbosity                  |
| `secret_key`               | String   | Client/server authentication key   |
| `write_logs`               | Boolean  | Persistent server logs             |
| `msip`                     | IP       | Management/server address          |
| `preload_map`              | Boolean  | Preload map into memory            |
| `use_auth`                 | Boolean  | Password authentication            |
| `persist_accounts`         | Boolean  | Persist account-level data         |
| `noauth_default_admin`     | Boolean  | Admin access when auth is disabled |
| `daily_accounts_per_ip`    | Integer  | Account/IP limit                   |
| `watchdog_enabled`         | Boolean  | Server watchdog                    |
| `connectivity_check_url`   | URL list | Internet connectivity testing      |
| `connectivity_timeout`     | Integer  | Connectivity timeout               |
| `websocket_enabled`        | Boolean  | Browser WebSocket support          |
| `websocket_port`           | Integer  | WebSocket port                     |
| `websocket_tls_enabled`    | Boolean  | WebSocket TLS                      |
| `database_name`            | String   | SQL database                       |
| `database_username`        | String   | SQL username                       |
| `database_password`        | String   | SQL password                       |
| `database_address`         | String   | SQL host                           |
| `database_port`            | Port     | SQL port                           |
| `grafana_logging`          | Boolean  | Grafana logging                    |
| `name`                     | String   | World name                         |
| `name_ge`                  | String   | GE announcement world name         |
| `world_id`                 | String   | World number                       |
| `members`                  | Boolean  | Members world                      |
| `pvp`                      | Boolean  | PvP world                          |
| `enable_bots`              | Boolean  | Server bots                        |
| `enable_botting`           | Boolean  | Botting functionality              |
| `wild_pvp_enabled`         | Boolean  | Wilderness PvP                     |
| `revenant_population`      | Integer  | Active Revenants                   |
| `xp_rates`                 | Boolean  | Tutorial Island XP rates           |
| `ironman`                  | Boolean  | Ironman creation                   |
| `second_bank`              | Boolean  | Second bank                        |
| `player_commands`          | Boolean  | Player commands                    |
| `data_path`                | Path     | Root data directory                |
| `cache_path`               | Path     | Cache                              |
| `save_path`                | Path     | Player saves                       |
| `configs_path`             | Path     | Configuration data                 |
| `grand_exchange_data_path` | Path     | Economy/GE data                    |
| `logs_path`                | Path     | Logs                               |
| `bot_data`                 | Path     | Bot data                           |
| `eco_data`                 | Path     | Economy data                       |

---

# Summary

The 2009Scape `default.conf` file provides a centralized way to configure the server without modifying source code.

The most important categories are:

### Server

Controls authentication, logging, networking, watchdog behavior, and WebSockets.

### Database

Controls the MySQL/MariaDB connection.

### Integrations

Controls optional services such as Grafana and webhook integrations.

### World

Controls the actual gameplay rules and available features.

### Paths

Controls where server data, player saves, logs, economy information, bots, cache, and configuration files are stored.

For a standard 2009Scape installation, the world identity should normally remain:

```ini
name = "2009Scape"
name_ge = "2009Scape"
```

while gameplay-specific options can be enabled or disabled depending on the desired server ruleset.

When creating a public server, particular attention should be paid to:

```ini
use_auth = true
persist_accounts = true
noauth_default_admin = false
database_username = "..."
database_password = "..."
```

and to keeping database credentials, TLS keystores, and webhook URLs out of publicly accessible repositories.
