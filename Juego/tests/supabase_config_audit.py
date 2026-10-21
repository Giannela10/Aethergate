"""Read-only audit; never outputs credentials or matched source text."""
import base64
import json
import os
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
findings = []
extensions = {'.gd', '.json', '.sql', '.md', '.cfg', '.godot', '.tscn', '.tres', '.py', '.ps1', '.env', '.ini', '.toml', '.yaml', '.yml', '.txt', '.log'}
ignored = {'.git', '.godot', 'node_modules', '.venv'}
placeholder = re.compile(r'TU_|YOUR_|EXAMPLE|PLACEHOLDER|REPLACE|<|\$\{|os\.get|config\.get|str\(|func\(|synthetic|fixture', re.I)
for path in ROOT.rglob('*'):
    if not path.is_file() or any(p in ignored for p in path.relative_to(ROOT).parts):
        continue
    if path.suffix.lower() not in extensions and not path.name.startswith('.env'):
        continue
    try:
        text = path.read_text(encoding='utf-8-sig')
    except (UnicodeError, OSError):
        continue
    categories = set()
    if re.search(r'\bsb_secret_[A-Za-z0-9_-]{12,}', text):
        categories.add('secret_api_key')
    if re.search(r'\bGOCSPX-[A-Za-z0-9_-]{10,}', text):
        categories.add('google_client_secret')
    for match in re.finditer(r'\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+', text):
        try:
            part = match.group().split('.')[1]
            payload = json.loads(base64.urlsafe_b64decode(part + '=' * (-len(part) % 4)))
            if payload.get('role') == 'service_role':
                categories.add('privileged_jwt')
        except (ValueError, UnicodeError):
            pass
    for match in re.finditer(r'''(?i)["']?(?:database_password|db_password|pgpassword|google_client_secret|client_secret|supabase_service_role_key)["']?\s*[:=]\s*["']([^"'\r\n]{8,})["']''', text):
        if not placeholder.search(match.group(1)) and match.group(1).strip() not in {'service_role', 'database password'}:
            categories.add('possible_secret_assignment')
    for match in re.finditer(r'postgres(?:ql)?://[^\s:/]+:([^@\s]+)@', text):
        if not placeholder.search(match.group(1)):
            categories.add('database_password_in_url')
    if categories:
        findings.append({'file': path.relative_to(ROOT).as_posix(), 'categories': sorted(categories)})

configs = []
for relative in ['config/auth_config.json', 'config/auth_config.example.json']:
    path = ROOT / relative
    item = {'file': relative, 'exists': path.exists()}
    if path.exists():
        try:
            data = json.loads(path.read_text(encoding='utf-8-sig'))
            item.update(properties=list(data), url_present=bool(data.get('supabase_url')), publishable_present=any(str(data.get(k, '')).startswith('sb_publishable_') for k in ['supabase_publishable_key', 'supabase_anon_key']))
        except (ValueError, UnicodeError):
            item['valid_json'] = False
    configs.append(item)
print(json.dumps({'configs': configs, 'dangerous_credential_findings': findings, 'environment_variable_names': sorted(k for k in os.environ if re.search(r'SUPABASE|DATABASE|PGHOST|PGUSER|PGPASSWORD|GOOGLE.*SECRET|DUOCGAMES_AUTH_CONFIG', k))}, indent=2))
