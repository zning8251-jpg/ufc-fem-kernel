import sys, os
sys.argv = [sys.argv[0]] + sys.argv[1:]
sys.stdout.reconfigure(encoding='utf-8', errors='replace')
sys.stderr.reconfigure(encoding='utf-8', errors='replace')

# Load guardian
guardian_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'arch_guardian.py')
with open(guardian_path, encoding='utf-8') as f:
    code = f.read()
exec(compile(code, guardian_path, 'exec'))
