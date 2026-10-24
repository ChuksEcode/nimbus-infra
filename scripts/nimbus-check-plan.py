#!/usr/bin/env python3
"""Check plan metadata; never print the raw plan, which can contain secrets."""
import json
import os
import sys

def check(plan, backend_group, backend_account):
    group = backend_group.casefold()
    account = backend_account.casefold()
    blocked = []
    changes = []
    for change in plan.get('resource_changes', []):
        if change.get('mode', 'managed') != 'managed':
            continue
        typ = change.get('type')
        values = change.get('change', {})
        for v in (values.get('before') or {}, values.get('after') or {}):
            name = str(v.get('name', '')).casefold()
            rg = str(v.get('resource_group_name', '')).casefold()
            rid = str(v.get('id', '')).casefold()
            if typ == 'azurerm_resource_group' and name == group:
                blocked.append(change['address'])
            if typ == 'azurerm_storage_account' and (name == account or f'/storageaccounts/{account}' in rid):
                blocked.append(change['address'])
            if typ == 'azurerm_storage_container':
                parent = str(v.get('storage_account_id', '')).casefold()
                parent_name = str(v.get('storage_account_name', '')).casefold()
                if parent_name == account or f'/storageaccounts/{account}' in parent or f'/storageaccounts/{account}' in rid:
                    blocked.append(change['address'])
        actions = values.get('actions', [])
        if actions != ['no-op']:
            changes.append((change['address'], actions))
    return sorted(set(blocked)), changes

if __name__ == '__main__':
    plan = json.load(sys.stdin)
    blocked, changes = check(plan, os.environ['TF_BACKEND_RESOURCE_GROUP'], os.environ['TF_BACKEND_STORAGE_ACCOUNT'])
    if blocked:
        print('Blocked: this project must not manage its own external state backend:')
        print('\n'.join(blocked))
        raise SystemExit(1)
    print('Backend protection check passed. Planned managed resource changes:')
    for address, actions in changes:
        print(f'{address}: {", ".join(actions)}')
    if not changes:
        print('No managed resource changes (outputs may still change).')
