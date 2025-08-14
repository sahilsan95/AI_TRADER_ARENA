#!/usr/bin/env python3
import subprocess
import sys

# === CONFIG ===
BOT_ID = int(sys.argv[1]) if len(sys.argv) > 1 else 1  # allow CLI param
BOT_REGISTRY = "0x5751727946F90eA235feF74AA989b8145b7b62aE"

TOKEN_A = "0x729b67AA1B2F740DA96D445c365Fc07369600EBb"
TOKEN_B = "0x2FEBa17aaF40Adb4fdb579ac82721Be359DC2782"
QUOTE_TOKEN = "0x6e22CeD53E126Ffb215E633A5b793092dCcfA5eE"

RPC_URL = "https://dream-rpc.somnia.network"
AMM_ADDRESS = "0xC2C8E09E4768Bd4694Ab8Dc66191629383c2f389"  # AMM

def get_bot_balance(token_addr):
    """Get token balance FROM BotRegistry for this bot."""
    cmd = [
        "cast", "call", BOT_REGISTRY,
        "balanceOfToken(uint256,address)(uint256)",
        str(BOT_ID), token_addr,
        "--rpc-url", RPC_URL
    ]
    raw = subprocess.check_output(cmd, text=True).strip()
    val_str = raw.split()[0]  # Take only first chunk before space
    if val_str.startswith("0x"):
        return int(val_str, 16) / 1e18
    else:
        return int(val_str) / 1e18


def convert_to_quote(token_addr, amount):
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
    if val_str.startswith("0x"):
        return int(val_str, 16) / 1e18
    else:
        return int(val_str) / 1e18


def main():
    total_value = 0
    for token, name in [(TOKEN_A, "TokenA"), (TOKEN_B, "TokenB"), (QUOTE_TOKEN, "QuoteToken")]:
        bal = get_bot_balance(token)
        val = convert_to_quote(token, bal)
        print(f"{name} bal: {bal:.6f} → value in Q: {val:.6f}")
        total_value += val
    print(f"\nTotal Bot #{BOT_ID} Value in QuoteToken: {total_value:.6f}")

if __name__ == "__main__":
    main()
