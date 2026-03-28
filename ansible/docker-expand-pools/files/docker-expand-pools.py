#!/usr/bin/env python3
"""Add/update default-address-pools in Docker daemon.json to use /24 subnets."""

import argparse
import json
import os
import sys

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("-y", "--yes", action="store_true", help="Skip confirmation prompt")
args = parser.parse_args()

DAEMON_JSON = os.path.expanduser("~/.docker/daemon.json")

if not os.path.exists(DAEMON_JSON):
    print(f"{DAEMON_JSON} not found. Nothing to do.")
    sys.exit(0)

with open(DAEMON_JSON) as f:
    config = json.load(f)

old = config.get("default-address-pools")
new = [{"base": "172.17.0.0/12", "size": 24}]

if old == new:
    print("Already configured. Nothing to do.")
    sys.exit(0)

if old is not None:
    print(f"Current default-address-pools: {json.dumps(old)}")
else:
    print("No default-address-pools configured (Docker default: /16 subnets, ~15 networks).")

print(f"New default-address-pools:     {json.dumps(new)}")
print(f"This allows ~4000 networks instead of ~15.\n")

if not args.yes:
    resp = input("Apply change? [y/N] ").strip().lower()
    if resp != "y":
        print("Aborted.")
        sys.exit(0)

config["default-address-pools"] = new

with open(DAEMON_JSON, "w") as f:
    json.dump(config, f, indent=2)
    f.write("\n")

print(f"Updated {DAEMON_JSON}")
print("Restart Docker for changes to take effect.")
