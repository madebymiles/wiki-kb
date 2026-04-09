# Security Reference

## Data classification matrix

| Content type | Compartment | Encryption | API transmission | Example |
|---|---|---|---|---|
| Industry-regulated | `regulated` | git-crypt | **Blocked** | Industry regulatory data |
| Legal/compliance | `regulated` | git-crypt | **Blocked** | Contracts, regulatory |
| Career strategy | `inner-circle` | git-crypt | Permitted | CEO pursuit, board targeting |
| Financial data | `inner-circle` | git-crypt | Permitted | Investment, salary, equity |
| Private assessments | `inner-circle` | git-crypt | Permitted | Opinions about people |
| Investor materials | `inner-circle` | git-crypt | Permitted | Pitch decks, models |
| Family scheduling | `household` | Recommended (git-crypt) | Permitted | School events, children's names, dietary |
| Architecture decisions | `professional` | No | Permitted | Tech stack, patterns |
| Product insights | `professional` | No | Permitted | UX, market signals |
| Operating principles | `professional` | No | Permitted | Build discipline, sequencing |
| Published content | `public` | No | Permitted | Open-source, blog |

## git-crypt setup

```bash
brew install git-crypt
cd /path/to/super-repo
git-crypt init
mkdir -p ~/keys
git-crypt export-key ~/keys/wiki-kb.key   # Store securely, not in repo
```

`.gitattributes`:
```
wiki/**/inner-circle/** filter=git-crypt diff=git-crypt
wiki/**/regulated/** filter=git-crypt diff=git-crypt
wiki/**/household/** filter=git-crypt diff=git-crypt
```

The household line is recommended if your wiki contains children's names, schools, or medical/dietary information. Omit it if your household compartment contains only scheduling data.

Verify: `git-crypt status`
Unlock on new machine: `git-crypt unlock ~/keys/wiki-kb.key`

## Query audit trail

Every `/wiki-query` logs to `wiki/log.md`: timestamp, query text, pages accessed, compartments touched. Compliance-grade access record.

## Quarterly review (30 minutes, align with KPI cadence)

1. Read all inner-circle and regulated pages. Confirm accuracy, classification, relevance.
2. Run `/wiki-lint`. Review compartment audit section. Fix leaks.
3. Run `git-crypt status`. Confirm all sensitive files show `[ENCRYPTED]`.
4. Scan query log for unexpected access to sensitive compartments.
5. Archive or declassify content that is no longer sensitive.

## Credential exclusion

Never compiled, even if present in raw sources: API keys, passwords, SSH keys, database connection strings, OAuth secrets, environment variable values, personal identification numbers.

## Hallucination safeguards

- `source_count: 1` capped at `confidence: medium`. Cannot be presented as established fact.
- `source_count: 2+` required for `confidence: high`.
- `/wiki-challenge` flags decisions resting on single-source claims.
- Confidence decay degrades unchecked claims over 90 days.
- Quarterly human review provides the manual backstop.
