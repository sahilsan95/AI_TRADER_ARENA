#!/bin/bash

# === PROMPT FOR BOT IDs ===
read -p "Enter bot ID(s) to trade (space-separated): " -a BOT_IDS
echo "Running for bots: ${BOT_IDS[*]}"

# === CONFIG ===
BOT_REGISTRY=0x5751727946F90eA235feF74AA989b8145b7b62aE
TRADING_ARENA=0xDa0b11d93728Fa7F2d0bd2E154b8107FCAFd5B28

TOKEN_A=0x729b67AA1B2F740DA96D445c365Fc07369600EBb
TOKEN_B=0x2FEBa17aaF40Adb4fdB579ac82721Be359DC2782
QUOTE_TOKEN=0x6e22CeD53E126Ffb215E633A5b793092dCcfA5eE
AMM_ADDRESS=0xC2C8E09E4768Bd4694Ab8Dc66191629383c2f389

AMOUNT_A=100000000000000000000
AMOUNT_B=50000000000000000000
AMOUNT_Q=20000000000000000000

RPC_URL=https://dream-rpc.somnia.network
PK=0x1e28da033d06baf88f7aa6f33079a474e2b9642ba3c8cc1e5e4818e957b36f6d

LOG_FILE=bot_loop.log
MAX_PARALLEL_JOBS=4
MIN_BALANCE_Q=50         # Alert if below this in QuoteToken
ROI_ALERT_UP=10          # Alert if ROI >= this %
ROI_ALERT_DOWN=-10       # Alert if ROI <= this %

TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID}"

NO_DEPOSIT=false
[[ "$1" == "--no-deposit" ]] && NO_DEPOSIT=true

# === HELPERS ===
send_telegram() {
  local msg="$1"
  if [[ -n "$TELEGRAM_BOT_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]]; then
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
      -d "chat_id=${TELEGRAM_CHAT_ID}" \
      -d "text=${msg}" >/dev/null
  fi
}

wei_to_dec() { echo "scale=6; $1 / 1000000000000000000" | bc -l; }

to_quote_val() {
  local token=$1 amount_dec=$2
  [[ "${token,,}" == "${QUOTE_TOKEN,,}" ]] && echo "$amount_dec" && return
  local wei_amount=$(printf "%.0f" "$(echo "$amount_dec * 1e18" | bc -l)")
  local out=$(cast call $AMM_ADDRESS "getAmountOut(address,address,uint256)" $token $QUOTE_TOKEN $wei_amount --rpc-url $RPC_URL)
  local first=$(echo $out | awk '{print $1}')
  [[ $first == 0x* ]] && wei_to_dec $first || wei_to_dec $first
}

get_bot_balance_dec() {
  local bot_id=$1 token=$2
  local out=$(cast call $BOT_REGISTRY "balanceOfToken(uint256,address)(uint256)" $bot_id $token --rpc-url $RPC_URL)
  local first=$(echo $out | awk '{print $1}')
  [[ $first == 0x* ]] && wei_to_dec $first || wei_to_dec $first
}

load_or_create_initial_value() {
  local bot_id=$1 cur_val=$2
  local file="initial_value_bot${bot_id}.txt"
  if [[ -f "$file" ]]; then
    local saved=$(cat "$file")
    (( $(echo "$saved > 0" | bc -l) )) && echo "$saved" && return
  fi
  echo "$cur_val" > "$file"
  echo "$cur_val"
}

save_last_roi() {
  local bot_id=$1 roi=$2
  echo "$roi" > "last_roi_bot${bot_id}.txt"
}

get_last_roi() {
  local bot_id=$1
  [[ -f "last_roi_bot${bot_id}.txt" ]] && cat "last_roi_bot${bot_id}.txt" || echo "0"
}

tick_and_monitor_bot() {
  local bot_id=$1
  echo "    ➤ Ticking Bot $bot_id..."
  if ! cast send $TRADING_ARENA "tick(uint256)" $bot_id --rpc-url $RPC_URL --private-key $PK >> $LOG_FILE 2>&1; then
    send_telegram "⚠ Tick failed for Bot ${bot_id}"
    return
  fi

  balA=$(get_bot_balance_dec $bot_id $TOKEN_A)
  balB=$(get_bot_balance_dec $bot_id $TOKEN_B)
  balQ=$(get_bot_balance_dec $bot_id $QUOTE_TOKEN)

  valA=$(to_quote_val $TOKEN_A $balA)
  valB=$(to_quote_val $TOKEN_B $balB)
  valQ=$balQ
  total_val=$(echo "$valA + $valB + $valQ" | bc -l)

  init_val=$(load_or_create_initial_value $bot_id $total_val)
  roi=$(echo "scale=2; ($total_val - $init_val) / $init_val * 100" | bc -l)

  echo "    Bot $bot_id Balances: TokenA=$balA (${valA}Q), TokenB=$balB (${valB}Q), Quote=$balQ Q"
  echo "    Bot $bot_id Total Value (Quote): $total_val | ROI: ${roi}%"

  (( $(echo "$total_val < $MIN_BALANCE_Q" | bc -l) )) && \
    send_telegram "⚠ Bot ${bot_id} Value Low: ${total_val}Q"

  last_roi=$(get_last_roi $bot_id)
  # Send ROI threshold alerts
  if (( $(echo "$roi >= $ROI_ALERT_UP" | bc -l) && $(echo "$last_roi < $ROI_ALERT_UP" | bc -l) )); then
    send_telegram "📈 Bot ${bot_id} ROI crossed UP threshold: ${roi}%"
  fi
  if (( $(echo "$roi <= $ROI_ALERT_DOWN" | bc -l) && $(echo "$last_roi > $ROI_ALERT_DOWN" | bc -l) )); then
    send_telegram "📉 Bot ${bot_id} ROI crossed DOWN threshold: ${roi}%"
  fi
  save_last_roi $bot_id $roi
}

export -f tick_and_monitor_bot wei_to_dec to_quote_val get_bot_balance_dec load_or_create_initial_value send_telegram get_last_roi save_last_roi
export BOT_REGISTRY TRADING_ARENA TOKEN_A TOKEN_B QUOTE_TOKEN AMM_ADDRESS RPC_URL PK LOG_FILE MIN_BALANCE_Q ROI_ALERT_UP ROI_ALERT_DOWN TELEGRAM_BOT_TOKEN TELEGRAM_CHAT_ID

# === INIT ===
echo "[$(date '+%F %T')] Setting trade limits to 5%"
cast send $TRADING_ARENA "setLimits(uint256,uint256)" 1 500 --rpc-url $RPC_URL --private-key $PK >> $LOG_FILE 2>&1

if ! $NO_DEPOSIT; then
  for bot_id in "${BOT_IDS[@]}"; do
    echo "[$(date '+%F %T')] Approving & Depositing for Bot $bot_id..."
    cast send $TOKEN_A "approve(address,uint256)" $BOT_REGISTRY $AMOUNT_A --rpc-url $RPC_URL --private-key $PK >> $LOG_FILE 2>&1
    cast send $TOKEN_B "approve(address,uint256)" $BOT_REGISTRY $AMOUNT_B --rpc-url $RPC_URL --private-key $PK >> $LOG_FILE 2>&1
    cast send $QUOTE_TOKEN "approve(address,uint256)" $BOT_REGISTRY $AMOUNT_Q --rpc-url $RPC_URL --private-key $PK >> $LOG_FILE 2>&1
    cast send $BOT_REGISTRY "deposit(uint256,address,uint256)" $bot_id $TOKEN_A $AMOUNT_A --rpc-url $RPC_URL --private-key $PK >> $LOG_FILE 2>&1
    cast send $BOT_REGISTRY "deposit(uint256,address,uint256)" $bot_id $TOKEN_B $AMOUNT_B --rpc-url $RPC_URL --private-key $PK >> $LOG_FILE 2>&1
    cast send $BOT_REGISTRY "deposit(uint256,address,uint256)" $bot_id $QUOTE_TOKEN $AMOUNT_Q --rpc-url $RPC_URL --private-key $PK >> $LOG_FILE 2>&1
  done
else
  echo "Skipping deposits (--no-deposit mode)"
fi

# === MAIN LOOP (Parallel) ===
while true; do
  echo "[$(date '+%F %T')] Parallel tick for bots: ${BOT_IDS[*]}"
  running_jobs=0
  for bot_id in "${BOT_IDS[@]}"; do
    tick_and_monitor_bot "$bot_id" &
    ((running_jobs++))
    (( running_jobs >= MAX_PARALLEL_JOBS )) && { wait -n; ((running_jobs--)); }
  done
  wait  
  echo "⏳ Sleeping 30 sec..."
  sleep 30
done >> $LOG_FILE 2>&1
