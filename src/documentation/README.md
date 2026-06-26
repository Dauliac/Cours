# Technical Documentation: A Cross-Disciplinary Approach

<!-- vale off -->

- auto-gen TOC;
  {:toc}

<!-- vale on -->

______________________________________________________________________

## Introduction to Technical Documentation

<!-- header: 'Technical Documentation' -->

<!-- footer: 'Julien Dauliac -- ynov.casualty925@passfwd.com' -->

<!-- headingDivider: 3 -->

<!-- colorPreset: sunset -->

<!-- paginate: true -->

### Why Documentation Matters

Documentation is an essential component of a project's lifecycle.
Without it, knowledge lives only in people's heads — and when they leave, the knowledge leaves with them.

Good documentation serves four purposes:

- **Knowledge transfer** — new team members ramp up faster
- **Maintenance** — understanding *why* decisions were made helps evolve systems safely
- **Developer experience** — clear docs reduce friction and frustration
- **User experience** — users can self-serve instead of filing support tickets

______________________________________________________________________

### Types of Documentation

Not all documentation is the same. At a high level, projects need:

| Type | Audience | Purpose |
|------|----------|---------|
| **User documentation** | End users | How to use the product |
| **API documentation** | Integrators | Contract and behaviour of interfaces |
| **Architecture documentation** | Engineers | System design and decisions |
| **Operational documentation** | Operators / SREs | Runbooks, deployment, monitoring |
| **Contributor documentation** | Contributors | How to set up, develop, and submit changes |

______________________________________________________________________

## Structuring Knowledge

The hardest part of documentation is not writing — it is organising.
Two methods stand out for structuring knowledge effectively.

### Diátaxis

[Diátaxis](https://diataxis.fr/) is a framework based on a simple insight: documentation serves practitioners in a domain of skill, and what they need changes based on two dimensions:

1. **Action vs Cognition** — are they doing something or understanding something?
2. **Acquisition vs Application** — are they learning or working?

These two axes create exactly four documentation types:

```
                    ACQUISITION          APPLICATION
                  (learning)            (working)
              ┌────────────────────┬────────────────────┐
   ACTION     │                    │                    │
   (doing)    │    TUTORIALS       │   HOW-TO GUIDES    │
              │                    │                    │
              ├────────────────────┼────────────────────┤
   COGNITION  │                    │                    │
   (thinking) │   EXPLANATION      │    REFERENCE       │
              │                    │                    │
              └────────────────────┴────────────────────┘
```

#### Tutorials (learning by doing)

The teacher is responsible for the learner's success.
Every step must work. One path only, no alternatives.
Focus on doing, not explaining.

**Language**: "We will create...", "First, do X. Now, do Y.", "Notice that..."

#### How-To Guides (working to achieve goals)

Assume competence. The reader knows what they want — help them get there.
Address real-world complexity with conditionals ("If X, do Y").

**Language**: "This guide shows you how to...", "To achieve W, do Z"

#### Reference (facts while working)

Describe, don't instruct. Be austere and authoritative.
Structure mirrors the product architecture. Completeness matters.

**Language**: "X is available as Y", "Sub-commands are: A, B, C"

#### Explanation (understanding concepts)

Answer "why". Talk about the subject from multiple angles.
Permit opinion. Provide context and bigger picture.

**Language**: "The reason for X is...", "Some prefer W. This can be effective, but..."

> **Key principle**: keep these four types separate. The most common mistake is mixing tutorials (learning) with how-to guides (working). If content serves multiple needs, split it and link between documents.

______________________________________________________________________

### Zettelkasten

[Zettelkasten](https://zettelkasten.de/) is a knowledge management method based on interconnected atomic notes.
Each note captures one idea and links to related notes, building a web of knowledge over time.

This approach is useful for:

- Research and critical thinking
- Building a personal knowledge base
- Discovering connections between ideas that were not obvious

While Diátaxis structures project documentation, Zettelkasten structures personal knowledge. They are complementary.

______________________________________________________________________

## Community Standard Files

Open-source projects (and increasingly internal ones) follow a set of **community standard files** that live at the repository root. These files form the "social contract" of a project — they tell contributors, users, and machines how to interact with the codebase.

### The Essential Files

| File | Purpose |
|------|---------|
| `README.md` | First impression. What this project is, how to install it, how to use it |
| `CONTRIBUTING.md` | How to contribute: setup, conventions, PR process, code style |
| `CODE_OF_CONDUCT.md` | Behavioural expectations for participants |
| `LICENSE` | Legal terms under which the code is distributed |
| `CHANGELOG.md` | What changed in each release (see [Keep a Changelog](https://keepachangelog.com/)) |
| `SECURITY.md` | How to report security vulnerabilities responsibly |
| `.github/ISSUE_TEMPLATE/` | Structured templates for bug reports and feature requests |
| `.github/PULL_REQUEST_TEMPLATE.md` | Checklist and structure for pull requests |

GitHub, GitLab, and Forgejo all recognise these files and surface them in the UI. A project without them looks abandoned.

______________________________________________________________________

### CONTRIBUTING.md in Depth

The `CONTRIBUTING.md` file is the single most important file for project health after `README.md`. It answers:

- **How do I set up the development environment?** (prerequisites, tools, commands)
- **What conventions do you follow?** (commit messages, branch naming, code style)
- **How do I submit a change?** (fork/branch workflow, PR checklist, review process)
- **How do I run the tests?** (unit, integration, linting)
- **What should I not do?** (anti-patterns, out-of-scope changes)

A good `CONTRIBUTING.md` reduces friction for first-time contributors and enforces consistency across the team.

#### Example structure

```markdown
# Contributing to <project>

## Prerequisites
- Nix (see [install guide](./nix/INSTALL.md))
- direnv

## Getting started
1. Clone the repo
2. Run `direnv allow`
3. Run `task build`

## Conventions
- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/)
- Code is formatted with `treefmt`

## Submitting changes
1. Create a feature branch from `main`
2. Make your changes
3. Run `task check` to validate
4. Open a pull request
```

______________________________________________________________________

## AI-Assisted Documentation: The New Standard

The rise of AI coding agents (Claude Code, Copilot, Cursor, Aider) has created a new category of documentation: **files that instruct machines** rather than humans.

These files are not optional extras — they are becoming as fundamental as `README.md` was in 2015.

### AGENTS.md: The Cross-Tool Standard

[AGENTS.md](https://agents.md/) is an open standard for guiding AI coding agents. Proposed by OpenAI in August 2025 through collaboration with Google, Cursor, Factory, and Sourcegraph, it is now governed by the **Agentic AI Foundation (AAIF)** under the **Linux Foundation**.

The format is plain Markdown, intentionally schema-free. The AAIF spec defines optional fields (`allowed_tools`, `disallowed_tools`, `agent_instructions`, `output_format`, `environment`) but tools read what they understand and skip the rest.

By mid-2026, AGENTS.md is read natively by 30+ tools: OpenAI Codex, Gemini CLI, Google Jules, Devin, Cursor, Windsurf, GitHub Copilot, Warp, Zed, and more. It is adopted by over 60,000 repositories.

#### Research evidence

An [ETH Zurich empirical study](https://arxiv.org/html/2601.20404v2) on 10 repositories and 124 pull requests measured the impact of AGENTS.md files:

| Metric | With AGENTS.md | Without |
|--------|---------------|---------|
| Output tokens | **-20%** (mean) | baseline |
| Wall-clock time | **-28.6%** (median) | baseline |
| Total tokens | **-9.9%** (mean) | baseline |

Critical finding: **LLM-generated context files reduced task success rates** in 5 of 8 settings while increasing inference costs by 20–23%. Human-curated files delivered ~4% success rate improvement. The takeaway: always write these files by hand.

#### The landscape of agent instruction files

Different AI tools started with their own formats, but the ecosystem is converging:

| Format | Tool | Location | Status |
|--------|------|----------|--------|
| `AGENTS.md` | Cross-tool standard | Repo root + subdirs | Open standard (AAIF / Linux Foundation) |
| `CLAUDE.md` | Claude Code | Repo root + subdirs + `~/.claude/` | Anthropic-specific, richer memory model |
| `.cursor/rules/*.mdc` | Cursor | `.cursor/rules/` | Cursor-only, glob-scoped activation |
| `.github/copilot-instructions.md` | GitHub Copilot | `.github/` | GitHub-specific |
| `.windsurfrules` | Windsurf | Repo root | Migrating toward AGENTS.md |

The trend is clear: **AGENTS.md is becoming the universal format**, with tool-specific files layered on top for features unique to each agent.

#### What to include

An effective AGENTS.md contains **what the agent cannot infer from code alone**:

1. **One-line project description** — acts like a role-based prompt
2. **Tech stack** — framework, language, versions, database
3. **Commands** — the exact invocations for build, test, lint, deploy (not the conventional ones — the actual ones)
4. **Architecture** — the 3–5 directories that matter and what each does
5. **Conventions** — patterns that linters cannot catch (naming, module boundaries, import ordering)
6. **Boundaries** — what the agent should never do (modify generated files, skip tests, etc.)

The key principle is **non-inferability**: include only details the agent cannot figure out by reading the code. ETH Zurich found that architectural overviews did not reduce navigation time — removing an Architecture section while keeping commands, constraints, and non-standard patterns produces the same agent behaviour at lower token cost. Non-standard tooling (pixi, custom build systems, unusual package managers) delivers the highest ROI because these tools are underrepresented in LLM training data.

#### Effective patterns

**Definition of Done** — eliminates false completion claims:

```markdown
## Definition of Done
A task is complete when ALL of the following pass:
1. `task lint` exits 0
2. `task test` exits 0
3. `task typecheck` exits 0
4. Commit message follows: `type(scope): description`
```

**Escalation rules** — prevents destructive workarounds when the agent is stuck:

```markdown
## When Blocked
- Tests fail after 3 attempts: stop and report the error
- Missing dependency: check requirements first, do not install without asking
- Never: delete files to resolve errors, force push, skip tests
```

**Decision log** — prevents agents from suggesting already-rejected alternatives:

```markdown
## Architecture Decisions
- mdBook over Docusaurus (Markdown-native, fast builds)
- Nix over Docker for dev environments (reproducibility)
- Do NOT suggest switching these.
```

**Task-organised sections** — reduces irrelevant context parsing:

```markdown
## When Writing Code
- Run `task lint` after every file change

## When Reviewing Code
- Check: `task security-scan`

## When Releasing
- Update version in `flake.nix`
```

#### Hooks vs instructions

Anthropic draws a clear distinction:

- **CLAUDE.md instructions** are *advisory*. The agent may not follow them, especially as context grows.
- **Hooks** are *deterministic*. Scripts that run automatically at specific points (before/after tool use, session start). Guaranteed to execute.

**Rule of thumb**: if an action must happen every time with zero exceptions (run a formatter after every edit, block writes to a protected directory), use a hook. If it is guidance, use CLAUDE.md.

#### Best practices

**Keep it short.** Aim for under 200 lines. Research shows that all frontier LLMs lose accuracy as input grows — some dropping from 95% to 60% past a threshold. For every line, ask: *"Would removing this cause the agent to make mistakes?"* If not, cut it.

**Commands over prose.** Lead with exact commands, not explanations. Setup first, testing second, deployment third, debugging last.

```markdown
# Good: actionable
## Test
- `task test` — run all tests
- `task test -- -run TestAuth` — run a single test

# Bad: vague
## Testing
Please make sure all tests pass before committing.
```

**Don't duplicate the linter.** If `treefmt` enforces formatting and `eslint` enforces style, do not repeat those rules in AGENTS.md. LLMs are slow and expensive at jobs a linter does instantly and deterministically. Use **hooks** instead — they run automatically and catch mistakes before they are committed.

**Use progressive disclosure.** Do not inline everything. Reference deeper docs by path — the agent pulls them only when relevant:

```markdown
## Architecture
See [docs/architecture.md](./docs/architecture.md) for the full diagram.
The key directories are:
- `src/` — source code
- `tests/` — test suites
- `infra/` — Terraform modules
```

**Review it regularly.** Stale information actively poisons context. If your AGENTS.md says authentication logic lives in `src/auth/` and that directory was renamed to `src/identity/`, the agent will confidently look in the wrong place. Treat AGENTS.md like CI config — require PR reviews for changes.

**Start with `/init`, then rewrite.** Most AI tools offer a scaffolding command (`/init` in Claude Code) that analyses your codebase to detect build systems, test frameworks, and patterns. Use it as a foundation, then rewrite by hand.

#### Hierarchy and scoping

AGENTS.md files follow a **nearest-file-wins** rule. Place them at different levels of your repository:

```
repo/
├── AGENTS.md              # Root: global defaults
├── CLAUDE.md              # Claude Code (can import AGENTS.md)
├── packages/
│   ├── api/
│   │   └── AGENTS.md      # API-specific conventions
│   └── frontend/
│       └── AGENTS.md      # Frontend-specific conventions
```

Agents concatenate files from root to leaf, with **closer files appearing later** so they override earlier guidance. This lets different parts of a monorepo have different rules without conflict.

For Claude Code specifically, `CLAUDE.md` supports three tiers:

1. **User-level** (`~/.claude/CLAUDE.md`) — personal preferences across all projects
2. **Project-level** (repo root) — project conventions
3. **Subdirectory-level** — scoped overrides

> **Bridging AGENTS.md and CLAUDE.md**: Claude Code does not natively read `AGENTS.md`. The workaround is to create a `CLAUDE.md` whose first line is `@AGENTS.md` — an import directive that pulls in the shared file. This way, both Claude Code and every other agent read the same instructions.

#### Anti-patterns

| Anti-pattern | Why it fails | Fix |
|-------------|-------------|-----|
| **Vague instructions** ("be careful", "write clean code") | No actionable command, no threshold to meet | Specific: "Run `task lint` before committing" |
| **Prose paragraphs** | LLMs skip or misinterpret long narrative | Bullet points with exact commands |
| **Contradictory priorities** | Agent oscillates between conflicting rules (ICLR 2026: -42% resolve rate) | Rank priorities explicitly |
| **Including secrets** | Leaked to anyone with repo access, cached in AI context | Use environment variables and `.env` files |
| **Documenting file paths that change** | Stale paths poison context more than no paths | Reference by pattern (`src/**/test_*.py`) or keep paths updated |
| **Too long (500+ lines)** | Causes "agentic drift" — agent starts strong then becomes incoherent | Under 200 lines; split into subdirectory files |
| **Human documentation instead of agent operations** | Agents need commands, not explanations | Write for a machine: what to run, what to check, what is "done" |
| **Auto-generating the file** | ETH Zurich: LLM-generated files reduced success in 5/8 settings, +20% cost | Always curate by hand; use `/init` only as a starting point |
| **Marking everything IMPORTANT** | Overuse dilutes emphasis; agent treats nothing as important | Reserve emphasis for truly non-negotiable rules |
| **Never updating** | Instructions drift as code evolves; stale info actively misleads | Review in PRs like code; prune when rules no longer apply |

#### Continuous improvement loop

A powerful pattern is to ask the AI agent itself to improve the AGENTS.md:

> "Summarise what you learned this session and suggest improvements to AGENTS.md."

This creates a feedback loop where the agent helps refine its own instructions based on actual usage — what commands it needed to discover, what conventions it got wrong, what context was missing.

______________________________________________________________________

### Model Context Protocol (MCP)

The [Model Context Protocol](https://modelcontextprotocol.io/) (MCP) is an open standard that defines how AI agents connect to external tools and data sources. Think of it as **USB-C for AI** — a universal plug that lets any agent talk to any service.

#### The problem MCP solves

Without MCP, every AI tool builds its own integrations:

```
Before MCP:
  Claude Code ──custom──> GitHub
  Claude Code ──custom──> Jira
  Copilot     ──custom──> GitHub
  Copilot     ──custom──> Jira
  Cursor      ──custom──> GitHub
  ...

With MCP:
  Claude Code ──MCP──┐
  Copilot     ──MCP──┤──> MCP Server (GitHub)
  Cursor      ──MCP──┘    MCP Server (Jira)
                           MCP Server (Datadog)
```

#### How MCP works

MCP follows a client-server architecture:

- **MCP Host** — the AI application (Claude Code, an IDE plugin)
- **MCP Client** — maintains a 1:1 connection with a server
- **MCP Server** — exposes capabilities (tools, resources, prompts)

Servers can provide three types of capabilities:

| Capability | Description | Example |
|------------|-------------|---------|
| **Tools** | Actions the AI can invoke | `git_commit`, `create_jira_issue` |
| **Resources** | Data the AI can read | File contents, database records |
| **Prompts** | Pre-built prompt templates | Code review checklist, PR description |

#### MCP in practice

An MCP configuration for Claude Code lives in `.claude/settings.json` or the project's configuration:

```json
{
  "mcpServers": {
    "git": {
      "command": "mcp-server-git",
      "args": ["--repository", "."]
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@context7/mcp"]
    }
  }
}
```

With this configuration, the AI agent can:

- Read git history, create branches, make commits
- Fetch up-to-date library documentation instead of relying on training data

#### Why MCP matters for documentation

MCP servers like [Context7](https://context7.com/) solve a fundamental documentation problem: **AI models have a training cutoff**. When a library releases a new version, the AI's knowledge is stale. MCP lets the agent fetch current documentation on demand, ensuring accurate and up-to-date guidance.

______________________________________________________________________

### Skills

Skills are **reusable prompt packages** that extend AI agents with specialised domain knowledge. They are to AI agents what libraries are to programming languages.

A skill encapsulates:

- **Domain expertise** — best practices, patterns, anti-patterns
- **Workflow** — step-by-step procedures for common tasks
- **Conventions** — project or organisation-specific rules
- **Tool orchestration** — which tools to use and when

#### Example: a documentation skill

A Diátaxis documentation skill might contain:

- The four documentation types and their characteristics
- Language patterns appropriate for each type
- A workflow for evaluating and improving existing documentation
- Common mistakes to avoid

When activated, the AI agent applies this knowledge automatically — it does not need to be re-explained every session.

#### Skills vs AGENTS.md

| Aspect | AGENTS.md | Skills |
|--------|-----------|--------|
| **Scope** | One repository | Cross-repository |
| **Content** | Project-specific facts | Domain expertise and workflows |
| **Activation** | Automatic (agent reads on start) | On demand (invoked when relevant) |
| **Maintained by** | Repository owners | Skill authors (can be shared) |

They are complementary: `AGENTS.md` tells the agent *about this project*, skills tell the agent *how to do things well*.

______________________________________________________________________

## Documentation Types and Evolution

### ADR (Architectural Decision Records)

An [ADR](https://adr.github.io/) captures a single architectural decision: the context, the decision, and the consequences.

Why ADRs matter:

- They answer "**why** was this done this way?" — the question every new team member asks
- They prevent relitigating decisions that were already carefully considered
- They create a transparent, searchable decision trail

#### ADR format

```markdown
# ADR-001: Use mdBook for course documentation

## Status
Accepted

## Context
We need a documentation tool that supports Markdown, Mermaid diagrams,
and can be extended with preprocessors.

## Decision
We will use mdBook with custom preprocessors.

## Consequences
- Positive: Markdown-native, fast builds, extensible
- Negative: Less mature plugin ecosystem than Docusaurus
```

### Tech Radar

A [Tech Radar](https://www.thoughtworks.com/radar) is a living document that tracks the technologies a team or organisation uses, evaluates, or rejects.

It categorises technologies into rings:

- **Adopt** — proven, use by default
- **Trial** — worth trying on real projects
- **Assess** — interesting, explore in side projects
- **Hold** — do not start new work with this

The radar prevents technology sprawl and makes technical choices visible to the whole organisation.

### EventStorming

[EventStorming](https://www.eventstorming.com/) is a collaborative workshop format for modelling business processes. Participants use sticky notes to map out domain events, commands, and aggregates.

It produces documentation as a side effect: the resulting event map is itself a powerful architectural diagram that captures business flows.

______________________________________________________________________

## Best Practices for Writing Documentation

### Clarity and Structure

- Use simple, precise language — write for someone who has never seen the project
- Organise content into coherent sections with clear headings
- Use tables for structured data, code blocks for commands and config
- Keep paragraphs short — three to five sentences maximum

### Consistency and Uniformity

- Adhere to a style guide (or create one)
- Use automated validation tools:
  - [Vale](https://github.com/errata-ai/vale) — prose linter with customisable rules
  - [Doc Detective](https://doc-detective.com/) — automated documentation testing
  - [markdownlint](https://github.com/DavidAnson/markdownlint) — Markdown style enforcement

### Writing Style Techniques

How you write matters as much as what you write. Style affects comprehension, trust, and how quickly a reader can act on information.

#### Active voice vs passive voice

Active voice makes sentences shorter, clearer, and more direct. Passive voice obscures who does what.

| Passive (avoid) | Active (prefer) |
|-----------------|-----------------|
| "The configuration file is read by the application" | "The application reads the configuration file" |
| "Errors are logged when a request is failed" | "The server logs errors when a request fails" |
| "The tests should be run before committing" | "Run the tests before committing" |

**When passive is acceptable**: when the actor is irrelevant or unknown ("Logs are rotated daily", "The bug was introduced in v2.3").

#### Use imperative mood for instructions

In tutorials and how-to guides, tell the reader what to do — do not describe what they might do.

| Descriptive (avoid) | Imperative (prefer) |
|---------------------|---------------------|
| "You can start the server by running..." | "Start the server:" |
| "The user should then open the file..." | "Open the file:" |
| "It is possible to configure X by..." | "To configure X:" |

#### Second person ("you") vs third person

Use **"you"** when addressing the reader directly. Avoid the detached third person ("the user", "the developer", "one").

| Third person (avoid) | Second person (prefer) |
|----------------------|------------------------|
| "The developer must install Nix" | "You must install Nix" |
| "One can verify the setup by running..." | "Verify the setup by running:" |

Exception: reference documentation often uses neutral third person because it describes the system, not the reader.

#### Present tense vs future tense

Write in present tense. Documentation describes how things **are**, not how they will be.

| Future (avoid) | Present (prefer) |
|----------------|------------------|
| "The command will create a new directory" | "The command creates a new directory" |
| "The server will respond with a 200 status" | "The server responds with a 200 status" |
| "This will fail if the file does not exist" | "This fails if the file does not exist" |

#### Sentence length and complexity

- Aim for **15–25 words** per sentence
- One idea per sentence
- Break long sentences at natural conjunctions ("and", "but", "because")
- If a sentence has more than one comma, consider splitting it

| Too long | Better |
|----------|--------|
| "The server reads the configuration file on startup, validates all required fields, logs any missing values, and exits with an error code if the configuration is invalid." | "The server reads the configuration file on startup. It validates all required fields and logs any missing values. If the configuration is invalid, it exits with an error code." |

#### Avoid nominalisations

A nominalisation turns a verb into a noun, making prose bloated and vague.

| Nominalised (avoid) | Direct (prefer) |
|---------------------|-----------------|
| "Perform an installation of..." | "Install..." |
| "Make a modification to..." | "Modify..." |
| "Carry out the execution of..." | "Run..." |
| "Conduct an investigation into..." | "Investigate..." |

#### Hedging and weasel words

Remove words that weaken your statements without adding precision.

| Hedged (avoid) | Direct (prefer) |
|----------------|-----------------|
| "It is generally recommended to..." | "We recommend..." |
| "This can potentially cause..." | "This causes..." |
| "It should be noted that..." | (just state the fact) |
| "Basically, the system..." | "The system..." |

#### Parallel structure

When listing items, use the same grammatical structure for each.

| Not parallel | Parallel |
|--------------|----------|
| "The tool can: lint code, running tests, and the formatting of files" | "The tool can: lint code, run tests, and format files" |
| "Prerequisites: install Nix, Docker should be running, you need Git" | "Prerequisites: install Nix, start Docker, install Git" |

#### Terminology consistency

Pick one term and stick with it. Do not alternate between synonyms.

| Inconsistent | Consistent |
|-------------|------------|
| "container" / "Docker image" / "image" (interchangeably) | "container image" (everywhere) |
| "repo" / "repository" / "codebase" | "repository" (everywhere) |
| "CLI" / "command line" / "terminal" | "command line" (everywhere, or define abbreviation once) |

#### Documentation-specific patterns

| Pattern | When to use | Example |
|---------|-------------|---------|
| **Admonitions** | Warnings, tips, important notes | `> **Warning**: This deletes all data.` |
| **Code fences with language** | Any command or code | ` ```bash ` not ` ``` ` |
| **Placeholder syntax** | Values the reader must replace | `<your-api-key>` or `${PROJECT_NAME}` |
| **Cross-references** | Linking related concepts | `See [ADR-001](./adr/001.md) for context` |
| **Changelog-style** | Describing what changed | "Added", "Changed", "Removed", "Fixed" |

### Documentation as Code

Treat documentation like source code:

- **Version controlled** — documentation lives in Git alongside the code it describes
- **Reviewed** — documentation changes go through pull requests
- **Tested** — link checkers, prose linters, and build checks run in CI
- **Automated** — generation from source code, diagrams from code, API docs from schemas

This ensures documentation stays in sync with the codebase.

______________________________________________________________________

## Accessibility in Documentation

### Why Make Documentation Accessible?

- Inclusion for all users, including those with visual or motor impairments
- Compliance with standards (e.g., [WCAG 2.1](https://www.w3.org/WAI/WCAG21/quickref/))
- Better documentation for everyone — accessible writing is clearer writing

### Practices

- Use semantic headings (`#`, `##`, `###`) in proper hierarchy
- Provide alt text for images
- Ensure sufficient colour contrast
- Use descriptive link text (not "click here")
- Test with screen readers

______________________________________________________________________

## Automating Documentation

### Generation from Source Code

Good code documentation is extracted, not written separately:

- [rustdoc](https://doc.rust-lang.org/rustdoc/) — generates documentation from Rust doc comments, including runnable examples
- [Javadoc](https://docs.oracle.com/javase/8/docs/technotes/tools/windows/javadoc.html) / [KDoc](https://kotlinlang.org/docs/kotlin-doc.html) — JVM documentation generation
- [Swagger / OpenAPI](https://swagger.io/) — generates API documentation from specifications

### Interactive Documentation

- [mdBook cmd-run](https://github.com/FauconFan/mdbook-cmdrun) — executes commands within documentation and embeds their output
- [VHS](https://github.com/charmbracelet/vhs) — records terminal sessions as GIFs for visual tutorials
- [Mermaid](https://mermaid.js.org/) — generates diagrams from text, embedded directly in Markdown

### Repository Linting

Automate quality checks in CI:

```yaml
# Example: linkcheck in CI
tasks:
  check:
    cmds:
      - mdbook build  # linkcheck runs as a renderer
      - vale src/      # prose linting
```

______________________________________________________________________

## Tools and Platforms

### Documentation Generators

| Tool | Language | Strengths |
|------|----------|-----------|
| [mdBook](https://rust-lang.github.io/mdBook/) | Rust / Markdown | Fast, extensible, great for technical books |
| [Docusaurus](https://docusaurus.io/) | React / MDX | Rich plugins, versioning, i18n |
| [Astro](https://astro.build/) | Multi-framework | Content-focused, excellent performance |
| [MkDocs](https://www.mkdocs.org/) | Python / Markdown | Simple, material theme is popular |

### Diagram Tools

| Tool | Approach | Best for |
|------|----------|----------|
| [Mermaid](https://mermaid.js.org/) | Text-to-diagram | Flowcharts, sequences, embedded in Markdown |
| [D2](https://d2lang.com/) | Text-to-diagram | Complex architecture diagrams |
| [draw.io](https://www.drawio.com/) | Visual editor | Collaborative, free, offline-capable |
| [Excalidraw](https://excalidraw.com/) | Sketch-style | Whiteboard-feel diagrams |

### AI-Assisted Writing

| Tool | Purpose |
|------|---------|
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | AI coding agent with MCP support, skills, AGENTS.md |
| [Copilot](https://github.com/features/copilot) | AI pair programmer, inline suggestions |
| [Cursor](https://cursor.sh/) | AI-native IDE with codebase understanding |
| [Aider](https://aider.chat/) | Terminal-based AI pair programming |

______________________________________________________________________

## Putting It All Together

A well-documented repository in 2026 looks like this:

```
my-project/
├── AGENTS.md                  # AI agent instructions
├── CLAUDE.md -> AGENTS.md     # Symlink for Claude Code
├── CONTRIBUTING.md            # Human contributor guide
├── CODE_OF_CONDUCT.md         # Behavioural expectations
├── CHANGELOG.md               # Release history
├── LICENSE                    # Legal terms
├── SECURITY.md                # Vulnerability reporting
├── README.md                  # Project overview
├── .claude/
│   └── settings.json          # MCP server configuration
├── .github/
│   ├── ISSUE_TEMPLATE/        # Structured issue templates
│   └── PULL_REQUEST_TEMPLATE.md
├── docs/
│   ├── adr/                   # Architectural Decision Records
│   │   ├── 001-use-mdbook.md
│   │   └── 002-use-nix.md
│   ├── tutorials/             # Diátaxis: learning by doing
│   ├── how-to/                # Diátaxis: working guides
│   ├── reference/             # Diátaxis: factual lookup
│   └── explanation/           # Diátaxis: understanding
└── src/                       # Source code with inline docs
```

The key insight: **documentation is not a single thing**. It is a system of interconnected documents, each serving a specific audience and purpose. Diátaxis gives you the framework, community standard files give you the structure, and AI tools (AGENTS.md, MCP, skills) ensure that both humans and machines can navigate and contribute to the project effectively.

______________________________________________________________________
