#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------
# List of repository URLs (one per line).  Wiki pages are omitted
# because they are not git repositories.
# ------------------------------------------------------------------
repos=(
    https://github.com/mod-playerbots/mod-playerbots
    https://github.com/outtietv/BGQueueChecker
    https://github.com/BytesGalore/mod-no-hearthstone-cooldown
    https://github.com/DustinHendrickson/mod-ollama-chat
    https://github.com/DustinHendrickson/mod-player-bot-guildhouse
    https://github.com/DustinHendrickson/mod-player-bot-level-brackets
    https://github.com/Gozzim/mod-npc-spectator
    https://github.com/TerraByte-tbwps/mod-aoe-loot
    https://github.com/outtieTV/mod-challenge-modes-hotfix
    https://github.com/ZhengPeiRu21/mod-individual-progression
    https://github.com/ZhengPeiRu21/mod-leech
    https://github.com/ZhengPeiRu21/mod-reagent-bank
    https://github.com/abbodi1406/vcredist
    https://github.com/abracadaniel22/mod-fly-anywhere
    https://github.com/azerothcore/mod-1v1-arena
    https://github.com/azerothcore/mod-account-achievements
    https://github.com/azerothcore/mod-account-mounts
    https://github.com/azerothcore/mod-auto-revive
    https://github.com/azerothcore/mod-autobalance
    https://github.com/azerothcore/mod-better-item-reloading
    https://github.com/azerothcore/mod-boss-announcer
    https://github.com/azerothcore/mod-breaking-news-override
    https://github.com/azerothcore/mod-cfbg
    https://github.com/azerothcore/mod-desertion-warnings
    https://github.com/azerothcore/mod-duel-reset
    https://github.com/azerothcore/mod-dynamic-xp
    https://github.com/azerothcore/mod-emblem-transfer
    https://github.com/azerothcore/mod-fireworks-on-level
    https://github.com/azerothcore/mod-guildhouse
    https://github.com/azerothcore/mod-individual-xp
    https://github.com/azerothcore/mod-instance-reset
    https://github.com/azerothcore/mod-low-level-rbg
    https://github.com/azerothcore/mod-money-for-kills
    https://github.com/azerothcore/mod-morphsummon
    https://github.com/azerothcore/mod-npc-beastmaster
    https://github.com/azerothcore/mod-npc-buffer
    https://github.com/azerothcore/mod-npc-enchanter
    https://github.com/azerothcore/mod-npc-free-professions
    https://github.com/azerothcore/mod-npc-talent-template
    https://github.com/azerothcore/mod-phased-duels
    https://github.com/azerothcore/mod-pvp-titles
    https://github.com/azerothcore/mod-pvp-zones
    https://github.com/azerothcore/mod-queue-list-cache
    https://github.com/azerothcore/mod-quick-teleport
    https://github.com/azerothcore/mod-racial-trait-swap
    https://github.com/azerothcore/mod-random-enchants
    https://github.com/azerothcore/mod-rdf-expansion
    https://github.com/azerothcore/mod-reward-played-time
    https://github.com/azerothcore/mod-server-auto-shutdown
    https://github.com/azerothcore/mod-skip-dk-starting-area
    https://github.com/azerothcore/mod-solo-lfg
    https://github.com/azerothcore/mod-top-arena
    https://github.com/azerothcore/mod-transmog
    https://github.com/azerothcore/mod-war-effort
    https://github.com/azerothcore/mod-who-logged
    https://github.com/dunjeon/mod-TimeIsTime
    https://github.com/hallgaeuer/mod-dynamic-loot-rates
    https://github.com/hermensbas/mod_weather_vibe
    https://github.com/justin-kaufmann/mod-changeablespawnrates
    https://github.com/kjack9/mod-dead-means-dead
    https://github.com/noisiver/mod-junk-to-gold
    https://github.com/noisiver/mod-learnspells
    https://github.com/silviu20092/mod-improved-bank
)

# ------------------------------------------------------------------
# Clone each repository into the current directory
# ------------------------------------------------------------------
for url in "${repos[@]}"; do
    # Ensure the URL ends with .git for `git clone`
    if [[ "$url" != *.git ]]; then
        url="${url}.git"
    fi

    echo "Cloning $url ..."
    git clone "$url"
done

echo "All repositories have been cloned."
