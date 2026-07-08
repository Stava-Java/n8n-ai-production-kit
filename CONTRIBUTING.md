# Contributing

Thanks for wanting to make this kit better. Contributions of every size are
welcome - a typo fix counts.

## Ways to help

- **Report a bug or a confusing step.** Open an issue with the workflow name
  (e.g. PK-03), what you did, and what happened. Screenshots help.
- **Request or share a workflow.** Have a production pattern you think belongs
  in the kit (a new hardening layer, another provider for the cost monitor)?
  Open a "Workflow request" issue or send a PR.
- **Improve the docs.** If a step tripped you up, the docs can be clearer.

## Sending a pull request

1. Fork the repo and create a branch.
2. If you change a workflow, **export the clean JSON** and run the pre-export
   security scanner (PK-07) against it - no real keys, tokens, or emails.
3. Keep sample data fake (use `@example.com` and invented IDs).
4. Update the relevant doc (`docs/`) and add a line to `docs/CHANGELOG.md`.
5. Open the PR and describe what changed and why.

## Ground rules

- Standard n8n nodes only - no custom/community nodes in the core kit.
- Every workflow keeps its on-canvas **Setup Note** and stays runnable on
  n8n Cloud with no external database.
- Be kind. This is a learning-friendly project.
