# Release Builds

`build-release.ps1` produces the ZIP that gets uploaded to Gumroad. It:

1. Stages docs (at ZIP root), `workflows/`, and `test-data/`.
2. Validates that every workflow file parses as JSON.
3. Runs the secret/email pattern scan from the pre-export security checklist
   and **refuses to build** if anything matches.
4. Writes `n8n-ai-production-kit-v<version>.zip` into this folder.

```powershell
# From this folder:
.\build-release.ps1              # builds v0.1.0
.\build-release.ps1 -Version 0.2.0
```

Before uploading to Gumroad (non-negotiable, from the product plan):

- [ ] Import the ZIP's workflows into a **clean** n8n instance.
- [ ] Follow README/INSTALL from scratch; fix every missing step.
- [ ] Run PK-00 once, then run PK-07 against the staged workflows one more
      time inside n8n.
- [ ] Bump CHANGELOG.md and the version here, then rebuild.

Built ZIPs are disposable artifacts — do not edit a ZIP by hand; fix the
source and rebuild.
