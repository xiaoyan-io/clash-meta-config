# Repository Guidelines

## Project Structure & Module Organization
- `update_meta_config.py`: pulls daily node subscriptions, merges them with local YAML, and writes `clash-meta-config.yaml` plus timestamped archives in `history/`.
- `config/base.yaml`: core Clash Meta runtime settings (ports, DNS, geo assets).
- `config/groups.yaml`: proxy group definitions; the script auto-fills proxy lists using downloaded node names.
- `config/rules.yaml`: routing rules appended to the generated config.
- `clash-meta-config.yaml`: generated output; not hand-edited.

## Build, Test, and Development Commands
- Install deps: `pip install "pyyaml" "requests"` (use a virtualenv if modifying code).
- Generate config: `python3 update_meta_config.py` (downloads subscriptions, writes `clash-meta-config.yaml`, rotates `history/` to 30 files).
- Spot-check result: `head -n 5 clash-meta-config.yaml` to confirm timestamp and top-level keys; `ls history | tail` to confirm archive creation.

## Coding Style & Naming Conventions
- Python: follow PEP 8, 4-space indents, snake_case for names, f-strings for interpolation, and keep log prints concise.
- YAML: 2-space indents; keep existing key order and emoji group names; avoid tabs.
- Prefer small, focused functions; fail fast with clear error messages when subscriptions or files are missing.

## Testing Guidelines
- No automated tests yet; verify changes by running `python3 update_meta_config.py` and ensuring it succeeds without tracebacks.
- Validate generated YAML loads: `python3 -c "import yaml; yaml.safe_load(open('clash-meta-config.yaml'))"`; rerun if it raises.
- If editing routing/groups, manually confirm expected group names appear under `proxy-groups` and `rules` in the output.

## Commit & Pull Request Guidelines
- Use concise, present-tense summaries (e.g., `feat: adjust proxy groups`, `fix: guard missing subscription data`).
- In PRs, describe what changed, why, and how you validated (commands run, manual checks); link related issues if any.
- Include before/after snippets for YAML changes when relevant, and note any impact on generated output or history retention.

## Security & Configuration Tips
- Do not commit personal secrets or subscription URLs; only use the predefined sources in `SUB_URLS`.
- If adding new endpoints or geo assets, prefer HTTPS and short timeouts; keep `MAX_HISTORY` reasonable to avoid disk bloat.
- When troubleshooting, avoid running the downloader repeatedly in a tight loop to limit upstream load and rate limits.
