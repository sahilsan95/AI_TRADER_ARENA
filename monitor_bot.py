#!/usr/bin/env python3
import os, subprocess, requests

# === CONFIG ===
BOT_ID = int(os.getenv("BOT_ID", "1"))
BOT_REGISTRY = "0x5751727946F90eA235feF74AA989b8145b7b62aE"

TOKEN_A = "0x729b67AA1B2F740DA96D445c365Fc07369600EBb"
TOKEN_B = "0x2FEBa17aaF40Adb4fdb579ac82721Be359DC2782"
QUOTE_TOKEN = "0x6e22CeD53E126Ffb215E633A5b793092dCcfA5eE"

RPC_URL = "https://dream-rpc.somnia.network"
AMM_ADDRESS = "0xC2C8E09E4768Bd4694Ab8Dc66191629383c2f389"

MIN_BALANCE = 100      # alert if value < this
INITIAL_VALUE_FILE = f"initial_value_bot{BOT_ID}.txt"

BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "YOUR_BOT_TOKEN")
CHAT_ID = os.getenv("TELEGRAM_CHAT_ID", "YOUR_CHAT_ID")

# === HELPERS ===
def send_telegram(message):
    """Send a Telegram alert."""
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage"
    requests.post(url, data={"chat_id": CHAT_ID, "text": message})

def get_bot_balance(token_addr):
    """Fetch per-bot token balance from BotRegistry, robustly parse cast output."""
    cmd = [
        "cast", "call", BOT_REGISTRY,
        "balanceOfToken(uint256,address)(uint256)",
        str(BOT_ID), token_addr,
        "--rpc-url", RPC_URL
    ]
    raw = subprocess.check_output(cmd, text=True).strip()
    val_str = raw.split()[0]  # Take only first chunk before any [brackets]
    return (int(val_str, 16) if val_str.startswith("0x") else int(val_str)) / 1e18

def convert_to_quote(token_addr, amount):
    """Convert token holdings to quote token value."""
    if token_addr.lower() == QUOTE_TOKEN.lower():
        return amount
    amt_wei = int(amount * 1e18)
    cmd = [
        "cast", "call", AMM_ADDRESS,
        "getAmountOut(address,address,uint256)",
        token_addr, QUOTE_TOKEN, str(amt_wei),
        "--rpc-url", RPC_URL
    ]
    raw = subprocess.check_output(cmd, text=True).strip()
    val_str = raw.split()[0]
    return (int(val_str, 16) if val_str.startswith("0x") else int(val_str)) / 1e18

def get_current_value():
    """Sum bot's TokenA, TokenB, QuoteToken values in quote denomination."""
    total = 0
    for token in [TOKEN_A, TOKEN_B, QUOTE_TOKEN]:
        bal = get_bot_balance(token)
        val = convert_to_quote(token, bal)
        total += val
    return total

def load_or_create_initial_value(current_value):
    """Persist a baseline portfolio value for ROI tracking."""
    if os.path.exists(INITIAL_VALUE_FILE):
        try:
            with open(INITIAL_VALUE_FILE) as f:
                val = float(f.read().strip())
                if val > 0:
                    return val
        except:
            pass
    # Save new baseline
    with open(INITIAL_VALUE_FILE, "w") as f:
        f.write(f"{current_value:.6f}")
    return current_value

# === MAIN ===
def monitor():
    alerts = []
    cur_val = get_current_value()
    init_val = load_or_create_initial_value(cur_val)
    roi = ((cur_val - init_val) / init_val) * 100 if init_val > 0 else 0

    if cur_val < MIN_BALANCE:
        alerts.append(f"⚠ Bot #{BOT_ID} value critically low: {cur_val:.2f}")

    if alerts:
        send_telegram("\n".join(alerts))

    print(f"[BOT {BOT_ID}] Value={cur_val:.2f}, ROI={roi:.2f}%")

if __name__ == "__main__":
    monitor()
