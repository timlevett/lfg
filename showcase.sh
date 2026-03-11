#!/usr/bin/env bash
# showcase.sh — Simulate 30 minutes of realistic agentic activity across 3 hosts / 10 agents
# Usage: ./showcase.sh [base_url]
#   base_url defaults to http://localhost:5555

set -euo pipefail

BASE="${1:-http://localhost:5555}"
DURATION=1800  # 30 minutes
START_TIME=$(date +%s)

TOOLS=(Bash Read Write Edit Agent WebSearch Grep Glob Think)

# Theme assignments: ThemeName/SpriteIndex
# 11 themes (0-10), spread across 10 agents
PROFILES=(
  "Slimes/0"       # terra agent 0
  "Ghosts/1"       # terra agent 1
  "SpaceInvaders/0" # terra agent 2
  "PacMen/1"       # terra agent 3
  "Mushrooms/0"    # cleo agent 0
  "Jumpman/1"      # cleo agent 1
  "Creepers/0"     # cleo agent 2
  "Frogger/0"      # rio agent 0
  "Qbert/1"        # rio agent 1
  "Kirby/0"        # rio agent 2
)

HOSTS=(terra terra terra terra cleo cleo cleo rio rio rio)

post() {
  curl -sf -X POST "${BASE}/webhook?host=${1}&profile=${2}" \
    -H 'Content-Type: application/json' \
    -d "{\"text\": \"${3}\"}" >/dev/null 2>&1 || true
}

rand_range() {
  local lo=$1 hi=$2
  echo $(( lo + RANDOM % (hi - lo + 1) ))
}

rand_tool() {
  echo "${TOOLS[RANDOM % ${#TOOLS[@]}]}"
}

time_left() {
  local now=$(date +%s)
  (( now - START_TIME < DURATION ))
}

agent_loop() {
  local idx=$1
  local host="${HOSTS[$idx]}"
  local profile="${PROFILES[$idx]}"
  local sid="showcase-${host}-${idx}-$$"

  # Stagger joins over ~2 minutes
  local delay=$(rand_range 0 120)
  sleep "$delay"

  while time_left; do
    # SessionStart
    sid="showcase-${host}-${idx}-${RANDOM}"
    post "$host" "$profile" "SessionStart|${sid}|"

    # Work cycles: 8-20 tool calls per session
    local cycles=$(rand_range 8 20)
    for (( c=0; c<cycles; c++ )); do
      if ! time_left; then break; fi

      local tool=$(rand_tool)

      # PreToolUse
      post "$host" "$profile" "PreToolUse|${sid}|${tool}"
      sleep "$(rand_range 3 8)"

      # ~10% chance of permission request
      if (( RANDOM % 10 == 0 )); then
        post "$host" "$profile" "PermissionRequest|${sid}|${tool}"
        sleep "$(rand_range 5 15)"
      fi

      # PostToolUse
      post "$host" "$profile" "PostToolUse|${sid}|${tool}"
      sleep "$(rand_range 2 5)"
    done

    # SessionEnd
    post "$host" "$profile" "SessionEnd|${sid}|"

    if ! time_left; then break; fi

    # Pause before rejoining
    sleep "$(rand_range 30 60)"
  done
}

# --- Main ---

echo "Showcase: resetting state..."
curl -sf -X POST "${BASE}/reset" >/dev/null 2>&1

echo "Showcase: launching 10 agents across 3 hosts for ${DURATION}s"
echo "  terra: 4 agents  |  cleo: 3 agents  |  rio: 3 agents"
echo "  Press Ctrl-C to stop early"

# Launch all agents in background
for i in $(seq 0 9); do
  agent_loop "$i" &
done

# Wait for all background jobs
wait

echo "Showcase complete."
