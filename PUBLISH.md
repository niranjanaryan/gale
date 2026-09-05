# Publish Gale to Hex.pm and GitHub

Canonical git remote: `https://github.com/niranjanaryan/gale`

This directory currently lives under `elixcoder/gale`. Split or subtree-push
before the first Hex release:

```bash
# from elixcoder/
git subtree split -P gale -b gale-main
# in a new clone of niranjanaryan/gale
git push git@github.com:niranjanaryan/gale.git gale-main:main
```

## Checklist

1. `mix test` and `mix bench` (commit `benchmark/RESULTS.md`)
2. Version in `mix.exs` + `CHANGELOG.md`
3. `mix docs` — skim hexdocs locally
4. `mix hex.build` — tarball has no `_build/`, `deps/`, or `.so`
5. `mix hex.publish` (needs `HEX_API_KEY` or `mix hex.user auth`)
6. `git tag v0.1.0 && git push origin v0.1.0`
7. GitHub repo settings:
   - Sponsors: `.github/FUNDING.yml` (already in tree)
   - About: “Phoenix HTTP/3 (QUIC) adapter”
   - Topics: `elixir`, `phoenix`, `http3`, `quic`, `bandit`
   - Enable Discussions and Security advisories

## Environment

```
HEX_API_KEY=...   # hex.pm
GITHUB_TOKEN=...  # optional release notes
```

Do not commit API keys. GitHub Actions does not publish Hex on this repo
until a `publish` workflow is added on tags.
