#!/usr/bin/env python3
"""Encrypt then authenticate saved plans; verify authentication before decryption."""
import hashlib
import hmac
import os
from pathlib import Path
import subprocess
import sys

def run(mode):
    secret = os.environ.get('TF_PLAN_ENCRYPTION_KEY', '')
    try:
        key = bytes.fromhex(secret)
    except ValueError:
        raise SystemExit('TF_PLAN_ENCRYPTION_KEY must be a random 64-character hexadecimal value.')
    if len(secret) != 64 or len(key) != 32:
        raise SystemExit('TF_PLAN_ENCRYPTION_KEY must be a random 64-character hexadecimal value.')
    auth_key = hmac.new(key, b'nimbus-terraform-plan-auth-v1', hashlib.sha256).digest()
    encrypted, tag = Path('tfplan.enc'), Path('tfplan.mac')
    args = ['openssl', 'enc', '-aes-256-cbc', '-pbkdf2', '-iter', '200000', '-pass', 'env:TF_PLAN_ENCRYPTION_KEY']
    if mode == 'encrypt':
        subprocess.run(args + ['-salt', '-in', 'tfplan', '-out', str(encrypted)], check=True)
        tag.write_text(hmac.new(auth_key, encrypted.read_bytes(), hashlib.sha256).hexdigest())
    elif mode == 'decrypt':
        expected = hmac.new(auth_key, encrypted.read_bytes(), hashlib.sha256).hexdigest()
        if not hmac.compare_digest(tag.read_text().strip(), expected):
            raise SystemExit('Saved-plan authentication failed. Rerun all jobs with the correct encryption secret.')
        subprocess.run(args + ['-d', '-in', str(encrypted), '-out', 'tfplan'], check=True)
    else:
        raise SystemExit('Use encrypt or decrypt.')

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) == 2 else '')
