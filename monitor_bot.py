#!/usr/bin/env python3
import os
import subprocess
import requests
import time

# === CONFIG ===
TOKEN_A = "0x729b67AA1B2F740DA96D445c365Fc07369600EBb"
TOKEN_B = "0x2FEBa17aaF40Adb4fdB579ac82721Be359DC2782"
QUOTE_TOKEN = "0x6e22CeD53E126Ffb215E633A5b793092dCcfA5eE"
TRADING_ARENA = "0xDa0b11d93728Fa7F2d0bd2E154b8107FCAFd5B28"
RPC_URL = "https://dream-rpc.somnia.network"
AMM_ADDRESS = "0xC2C8E09E4768Bd4694Ab8Dc66191629383c2f389"  # your AMM address

MIN_BALANCE = 100
INACTIVITY_LIMIT_MIN = 10
HIGH_GAS_LIMIT = 300000

BOT_LOG_PATH = "./bot_loop.log"
INITIAL_VALUE_FILE = "initial_value.txt"

BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "YOUR_BOT_TOKEN")
CHAT_ID = os.getenv("TELEGRAM_CHAT_ID", "YOUR_CHAT_ID")


# === HELPERS ===
def send_telegram(message):
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage"
    payload = {"chat_id": CHAT_ID, "text": message}
    try:
        r = requests.post(url, data=payload)
        if not r.ok:
            print(f"[ERROR] Telegram send failed: {r.text}")
    except Exception as e:
        print(f"[ERROR] Telegram send exception: {e}")


def get_balance(token_address, holder_address):
    try:
        cmd = [
            "cast", "call", token_address,
            "balanceOf(address)(uint256)",
            holder_address, "--rpc-url", RPC_URL
        ]
        raw = subprocess.check_output(cmd, text=True).strip()
        raw_value = raw.split()[0]
        return int(raw_value, 16) / 1e18 if raw_value.startswith("0x") else int(raw_value) / 1e18
    except Exception as e:
        print(f"[ERROR] Balance query failed for {token_address}: {e}")
        return 0


def convert_to_quote(token_address, amount):
    if token_address.lower() == QUOTE_TOKEN.lower():
        return amount
    try:
        amt_wei = int(amount * 1e18)
        cmd = [
            "cast", "call", AMM_ADDRESS,
            "getAmountOut(address,address,uint256)",
            token_address, QUOTE_TOKEN, str(amt_wei),
            "--rpc-url", RPC_URL
        ]
        raw = subprocess.check_output(cmd, text=True).strip()
        raw_value = raw.split()[0]
        return int(raw_value, 16) / 1e18 if raw_value.startswith("0x") else int(raw_value) / 1e18
    except Exception as e:
        print(f"[ERROR] Conversion to quote failed for {token_address}: {e}")
        return 0


def get_current_portfolio_value():
    total_value = 0
    for token, name in [
        (TOKEN_A, "TokenA"),
        (TOKEN_B, "TokenB"),
        (QUOTE_TOKEN, "QuoteToken")
    ]:
        bal = get_balance(token, TRADING_ARENA)
        val = convert_to_quote(token, bal)
        print(f"[INFO] {name} balance: {bal:.6f}, Quote value: {val:.6f}")
        total_value += val
    print(f"[INFO] Current Portfolio Value in QuoteToken: {total_value:.6f}")
    return total_value


def load_or_create_initial_value(current_value):
    if os.path.exists(INITIAL_VALUE_FILE):
        try:
            with open(INITIAL_VALUE_FILE, "r") as f:
                val = float(f.read().strip())
                if val > 0:
                    print(f"[BASELINE] Loaded INITIAL_VALUE from file: {val:.6f}")
                    return val
                else:
                    print("[WARN] Saved INITIAL_VALUE was zero or invalid, recreating...")
        except Exception as e:
            print(f"[ERROR] Could not read {INITIAL_VALUE_FILE}: {e}")
    with open(INITIAL_VALUE_FILE, "w") as f:
        f.write(f"{current_value:.6f}")
    print(f"[BASELINE] INITIAL_VALUE saved to file: {current_value:.6f}")
    return current_value


def parse_bot_log_roi_value():
    """Extract latest Value and ROI from bot_loop.log."""
    roi_val = None
    port_val = None
    if os.path.exists(BOT_LOG_PATH):
        try:
            with open(BOT_LOG_PATH, "r") as f:
                lines = f.readlines()
            for line in reversed(lines[-30:]):
                if "Value:" in line and port_val is None:
                    parts = line.split()
                    try:
                        port_val = float(parts[1]) / 1e18 if parts[1].isdigit() else None
                    except:
                        pass
                if "ROI:" in line and roi_val is None:
                    try:
                        # ROI in logs is in basis points (bps)
                        roi_val = float(line.split()[1]) / 100
                    except:
                        pass
                if roi_val is not None and port_val is not None:
                    break
        except Exception as e:
            print(f"[ERROR] Failed parsing ROI/Value from log: {e}")
    return port_val, roi_val


def check_bot_logs():
    alerts = []
    if not os.path.exists(BOT_LOG_PATH):
        return alerts
    with open(BOT_LOG_PATH, "r") as f:
        lines = f.readlines()
        if not lines:
            return alerts
        last_time = None
        for line in reversed(lines):
            if "blockNumber" in line:
                last_time = time.time()
                break
        if last_time and (time.time() - last_time > INACTIVITY_LIMIT_MIN * 60):
            alerts.append(f"⚠ Inactivity: no trades in last {INACTIVITY_LIMIT_MIN} min")
        for line in lines[-20:]:
            if "execution reverted" in line or "ERC20InsufficientBalance" in line:
                alerts.append("⚠ Trade failure detected: " + line.strip())
            if "gasUsed" in line:
                try:
                    gas = int(line.strip().split()[-1])
                    if gas > HIGH_GAS_LIMIT:
                        alerts.append(f"⚠ High gas usage: {gas}")
                except:
                    pass
    return alerts


# === MAIN ===
def monitor():
    alerts = []

    # Current portfolio value
    current_value = get_current_portfolio_value()

    # Persistent baseline
    initial_value = load_or_create_initial_value(current_value)

    # Manual ROI
    if initial_value > 0:
        roi = ((current_value - initial_value) / initial_value) * 100
        print(f"[INFO] ROI since baseline: {roi:.2f}%")
    else:
        roi = 0
        print("[INFO] ROI since baseline: N/A (baseline zero)")

    # Parse real Value/ROI from bot log
    bot_val, bot_roi = parse_bot_log_roi_value()
    if bot_val is not None and bot_roi is not None:
        print(f"[BOT LOG] Value: {bot_val:.2f} QuoteToken, ROI: {bot_roi:.2f}%")
    else:
        print("[BOT LOG] No recent Value/ROI data found.")

    # Low balance alert
    if current_value < MIN_BALANCE:
        alerts.append(f"⚠ Portfolio total value critically low: {current_value:.2f}")

    # Log checks
    alerts.extend(check_bot_logs())

    # Include bot log ROI in alerts if present
    if bot_val is not None and bot_roi is not None:
        alerts.append(f"ℹ Bot-reported Value: {bot_val:.2f} QToken, ROI: {bot_roi:.2f}%")

    # Send alerts
    if alerts:
        alert_text = "\n".join(alerts)
        print("[ALERT]", alert_text)
        send_telegram(alert_text)
    else:
        print("[OK] All checks passed.")


if __name__ == "__main__":
    monitor()
