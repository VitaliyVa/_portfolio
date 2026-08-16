# Playable Ads Portfolio

Live: https://vitaliyva.github.io/_portfolio/

## Deploy

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\deploy.ps1
```

`main` is rebuilt from scratch and force-pushed as **a single commit** every time.
That is deliberate: `play/` is ~34 MB, so a normal commit history would grow by
that much on every rebuild. With a squashed branch the repo size stays flat.

GitHub Pages: **Settings -> Pages -> Deploy from a branch -> `main` / `root`**.

## Layout

| path | what |
|---|---|
| `index.html` | gallery, live demos run in-page |
| `cv.html` | CV, print to PDF from the browser |
| `play/` | hardened single-file builds (host-locked) |
| `shots/` | card previews |
| `playables.json` | project manifest |

## Hardened builds

`play/*.html` are compressed, XOR-encrypted and bound to the deploy host.
Regenerate after changing a source build:

```
python <path-to>/portfolio/harden.py --hosts vitaliyva.github.io localhost 127.0.0.1
```

They will not run from `file://` or another domain - that is intentional.
