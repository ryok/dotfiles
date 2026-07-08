# Source / Provenance

This skill is **vendored unmodified** from Anthropic's official skills collection.
It is not original work — do not edit it locally.

- **Upstream**: https://github.com/anthropics/skills — `skills/skill-creator`
- **Commit**: `ef740771ac901e03fbca3ce4e1c453a96010f30a`
- **Fetched**: 2025-12-01
- **License**: Apache-2.0 (see `LICENSE.txt`)

## Why vendored (and not the other skills)

`skill-creator` has no package-manager distribution, so a copy is committed here
to keep dotfiles reproducible on a fresh machine. It is small, stable, and
permissively licensed.

By contrast, `agent-browser` is **not** vendored: its skill ships inside the
`agent-browser` npm package (installed via `Brewfile`), so `install.sh` symlinks
`~/.claude/skills/agent-browser` straight to the package's bundled copy — that
stays current with the package automatically.

## Updating

Re-copy from a fresh clone of anthropics/skills and bump the commit/date above:

```bash
git clone --depth 1 https://github.com/anthropics/skills /tmp/anthropics-skills
rm -rf .config/claude/skills/skill-creator
cp -R /tmp/anthropics-skills/skills/skill-creator .config/claude/skills/skill-creator
# then update Commit/Fetched above
```
