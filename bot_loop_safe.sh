#!/bin/bash

# === CONFIG ===
BOT_ID=1
BOT_REGISTRY=0x5751727946F90eA235feF74AA989b8145b7b62aE
TRADING_ARENA=0xDa0b11d93728Fa7F2d0bd2E154b8107FCAFd5B28
LEADERBOARD=0x581c414663bbaf0257c024433da937b3431EDe68

TOKEN_A=0x729b67AA1B2F740DA96D445c365Fc07369600EBb
TOKEN_B=0x2FEBa17aaF40Adb4fdB579ac82721Be359DC2782
QUOTE_TOKEN=0x6e22CeD53E126Ffb215E633A5b793092dCcfA5eE

AMOUNT_A=100000000000000000000   # 100 tokenA
AMOUNT_B=50000000000000000000    # 50 tokenB
AMOUNT_Q=20000000000000000000    # 20 quoteToken

RPC_URL=https://dream-rpc.somnia.network
PK=0x1e28da033d06baf88f7aa6f33079a474e2b9642ba3c8cc1e5e4818e957b36f6d

# === Set lower max trade limits ===
echo "⏳ Setting max trade limits to 500 bps (5%)"
cast send $TRADING_ARENA "setLimits(uint256,uint256)" 1 500 --rpc-url $RPC_URL --private-key $PK

# === 1. Approve tokens ===
echo "🔑 Approving tokens..."
cast send $TOKEN_A "approve(address,uint256)" $BOT_REGISTRY $AMOUNT_A --rpc-url $RPC_URL --private-key $PK
cast send $TOKEN_B "approve(address,uint256)" $BOT_REGISTRY $AMOUNT_B --rpc-url $RPC_URL --private-key $PK
cast send $QUOTE_TOKEN "approve(address,uint256)" $BOT_REGISTRY $AMOUNT_Q --rpc-url $RPC_URL --private-key $PK

# === 2. Deposit tokens to BotRegistry ===
echo "💰 Depositing to Bot $BOT_ID..."
cast send $BOT_REGISTRY "deposit(uint256,address,uint256)" $BOT_ID $TOKEN_A $AMOUNT_A --rpc-url $RPC_URL --private-key $PK
cast send $BOT_REGISTRY "deposit(uint256,address,uint256)" $BOT_ID $TOKEN_B $AMOUNT_B --rpc-url $RPC_URL --private-key $PK
cast send $BOT_REGISTRY "deposit(uint256,address,uint256)" $BOT_ID $QUOTE_TOKEN $AMOUNT_Q --rpc-url $RPC_URL --private-key $PK

# === 3. Tick loop ===
while true; do
  echo "⚡ Running tick for Bot $BOT_ID..."
  cast send $TRADING_ARENA "tick(uint256)" $BOT_ID --rpc-url $RPC_URL --private-key $PK

  echo "📊 --- Balances ---"
  echo "TokenA: $(cast call $BOT_REGISTRY 'balanceOfToken(uint256,address)(uint256)' $BOT_ID $TOKEN_A --rpc-url $RPC_URL)"
  echo "TokenB: $(cast call $BOT_REGISTRY 'balanceOfToken(uint256,address)(uint256)' $BOT_ID $TOKEN_B --rpc-url $RPC_URL)"
  echo "Quote:  $(cast call $BOT_REGISTRY 'balanceOfToken(uint256,address)(uint256)' $BOT_ID $QUOTE_TOKEN --rpc-url $RPC_URL)"

  echo "💹 --- Leaderboard ---"
  echo "Value: $(cast call $LEADERBOARD 'botValue(uint256)(uint256)' $BOT_ID --rpc-url $RPC_URL)"
  echo "ROI:   $(cast call $LEADERBOARD 'roiBpsOf(uint256)(int256)' $BOT_ID --rpc-url $RPC_URL)"

  echo "⏳ Sleeping 30 sec..."
  sleep 30
done
