#!/usr/bin/env python3
import subprocess

# Config (use the same as your monitor script)
TOKEN_A = "0x729b67AA1B2F740DA96D445c365Fc07369600EBb"
TOKEN_B = "0x2FEBa17aaF40Adb4fdB579ac82721Be359DC2782"
QUOTE_TOKEN = "0x6e22CeD53E126Ffb215E633A5b793092dCcfA5eE"
TRADING_ARENA = "0xDa0b11d93728Fa7F2d0bd2E154b8107FCAFd5B28"
RPC_URL = "https://dream-rpc.somnia.network"
AMM_ADDRESS = "0xC2C8E09E4768Bd4694Ab8Dc66191629383c2f389"  # Set your AMM contract address here

def get_balance(token_address, holder_address):
    try:
        cmd = [
            "cast", "call", token_address,
            "balanceOf(address)(uint256)",
            holder_address,
            "--rpc-url", RPC_URL
        ]
        raw = subprocess.check_output(cmd, text=True).strip()
        return int(raw.split()[0]) / 1e18
    except Exception as e:
        print(f"Balance query failed for {token_address}: {e}")
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
        # Parse hex string to int with base 16
        return int(raw, 16) / 1e18
    except Exception as e:
        print(f"[ERROR] Conversion to quote failed for {token_address}: {e}")
        return 0


def main():
    total_value = 0
    for token in [TOKEN_A, TOKEN_B, QUOTE_TOKEN]:
        bal = get_balance(token, TRADING_ARENA)
        quote_val = convert_to_quote(token, bal)
        print(f"Balance {token}: {bal:.6f}, Value in quote token: {quote_val:.6f}")
        total_value += quote_val
    print(f"\nCurrent Portfolio Value in Quote Token: {total_value:.6f}")

if __name__ == "__main__":
    main()
