# CodeGraph

**Deterministic architecture analysis for AI-assisted development.**

CodeGraph transforms your codebase into a traversable graph that AI assistants can use to understand code structure, trace dependencies, and assess the impact of changes before making them.

## The Problem

AI coding assistants are powerful but blind. They can write code, but they don't inherently understand:

- **What depends on what** — Changing a function might break 15 other functions
- **The ripple effect** — A "simple" refactor can cascade through your entire codebase
- **Code architecture** — They see files, not flows; functions, not systems

This leads to:
- AI suggesting changes that break dependent code
- Repeated "fix one thing, break another" cycles
- Developers manually explaining architecture over and over
- Missed edge cases in refactoring

## The Solution

CodeGraph creates a **static architecture graph** of your codebase that AI assistants can query. Before modifying code, the AI can:

1. **Check impact** — "What would break if I change this function?"
2. **Understand context** — "What calls this? What does it call?"
3. **See the system** — "Show me all API endpoints and their handlers"

```
┌─────────────┐    analyze    ┌──────────────────┐    query    ┌─────────────┐
│  Your Code  │ ────────────► │  .codegraph.json │ ◄────────── │  AI Agent   │
└─────────────┘               └──────────────────┘             └─────────────┘
```

## Installation

### One-Command Install (macOS)

```bash
curl -fsSL https://raw.githubusercontent.com/mitchellDrake/code-graph-releases/main/install.sh | bash
```

This installs:
- **CLI** (`codegraph`) at `/usr/local/bin/codegraph`
- **MCP Server** at `~/.codegraph/bin/codegraph-mcp`
- **Cursor configuration** in `~/.cursor/mcp.json`

### Manual Installation

1. Download the appropriate binary from [Releases](https://github.com/mitchellDrake/code-graph-releases/releases):
   - `codegraph-vX.X.X-macos-arm64` (Apple Silicon)
   - `codegraph-vX.X.X-macos-x64` (Intel Mac)

2. Install the CLI:
```bash
sudo mv codegraph-* /usr/local/bin/codegraph
sudo chmod +x /usr/local/bin/codegraph
sudo xattr -d com.apple.quarantine /usr/local/bin/codegraph
```

3. Install the MCP server:
```bash
mkdir -p ~/.codegraph/bin
mv codegraph-mcp-* ~/.codegraph/bin/codegraph-mcp
chmod +x ~/.codegraph/bin/codegraph-mcp
xattr -d com.apple.quarantine ~/.codegraph/bin/codegraph-mcp
```

4. Configure Cursor (`~/.cursor/mcp.json`):
```json
{
  "mcpServers": {
    "codegraph": {
      "command": "/Users/YOUR_USERNAME/.codegraph/bin/codegraph-mcp"
    }
  }
}
```

5. Restart Cursor.

## Quick Start

```bash
# Navigate to your project
cd your-project

# Initialize CodeGraph (creates rules + analyzes)
codegraph init

# Or just analyze
codegraph analyze --agent

# Check what a function affects
codegraph impact "processPayment"

# Get full context around a function
codegraph context --function "processPayment"

# List all API endpoints
codegraph list --type http-endpoint

# Watch for changes in real-time
codegraph watch

# See what changed since last commit
codegraph diff
```

## How It Works

### 1. Analysis

CodeGraph parses your codebase and extracts:

| Node Type | Description |
|-----------|-------------|
| `function` | Functions, methods, arrow functions |
| `class` | Class definitions |
| `module` | File-level modules |
| `http-endpoint` | REST API routes (Express, Next.js App Router, FastAPI, Flask, API Gateway) |
| `kafka-consumer` | Message queue consumers (Kafka, SQS) |
| `kafka-producer` | Message queue producers (Kafka, SNS) |
| `serverless-function` | AWS Lambda, Google Cloud Functions, Azure Functions |
| `terraform-resource` | Terraform infrastructure resources |
| `terraform-module` | Terraform modules |
| `terraform-variable` | Terraform input variables |
| `terraform-output` | Terraform output values |
| `terraform-data` | Terraform data sources |
| `database-query` | Database resources (RDS, DynamoDB, etc.) |

It also traces relationships:

| Edge Type | Meaning |
|-----------|---------|
| `calls` | Function A calls Function B |
| `imports` | Module A imports Module B |
| `exposes` | Module exposes Function |
| `extends` | Class extends another Class |
| `implements` | Class implements Interface |
| `references` | Terraform resource A references resource B |
| `depends-on` | Terraform explicit depends_on relationship |

### Advanced Call Detection

CodeGraph includes intelligent call graph detection:

**Class Method Resolution:**
- `this.method()` in TypeScript/JavaScript → Resolves to `ClassName.method`
- `self.method()` in Python → Resolves to `ClassName.method`
- `cls.method()` in Python class methods → Resolves to `ClassName.method`

**Re-export Resolution:**
- Follows `export { x } from './module'` chains in TypeScript index files
- Follows `from .module import x` re-exports in Python `__init__.py` files
- Ensures accurate impact analysis even through barrel files

**Singleton Instance Resolution:**
- Tracks module-level singleton patterns like `const service = new ServiceClass()` (TS) or `service = ServiceClass()` (Python)
- Resolves `service.method()` calls to `ServiceClass.method`
- Works across files when singletons are imported
- Supports factory patterns like `ServiceClass.create()` and `ServiceClass.getInstance()`
- Common pattern in both TypeScript and Python service-oriented architectures

**Next.js App Router Detection:**
- Automatically detects Next.js 13+ App Router HTTP endpoints from `route.ts`/`route.js` files
- Derives HTTP path from file structure: `app/api/users/[id]/route.ts` → `GET /api/users/[id]`
- Supports dynamic route segments (e.g., `[id]`, `[slug]`)
- Recognizes all HTTP methods: `GET`, `POST`, `PUT`, `DELETE`, `PATCH`, `HEAD`, `OPTIONS`
- Works with both `app/` and `src/app/` directory structures
- Links route handlers to the functions they call for complete flow analysis

### 2. Impact Analysis

For every function, CodeGraph computes an **impact score** based on:
- Direct callers (functions that call this one)
- Transitive dependents (the full upstream chain)
- Cross-service connections

**Impact Score Guide:**
- **0-2 (LOW)**: Safe to modify, few dependencies
- **3-10 (MEDIUM)**: Check callers, may affect multiple paths
- **10+ (HIGH)**: Critical function, changes ripple widely

### 3. Output Files

| File | Purpose |
|------|---------|
| `.codegraph.json` | Full graph with all nodes, edges, and metadata |
| `.codegraph.agent.txt` | Compact summary optimized for AI context windows |

## Cursor Rules File

When you run `codegraph init`, it creates `.cursor/rules/code-graph.mdc`:

```markdown
---
name: code-graph
description: Architecture analysis - use codegraph MCP tools before making structural changes
---

# CodeGraph Integration

This project uses CodeGraph for architecture analysis. The MCP tools are 
available to help understand code structure and impact.

## Required Workflow: Check Before You Change

Before modifying any function that might be shared or critical:

1. **Check Impact First** - Use `codegraph_impact` with the function name
   - This shows all code that depends on the function
   
2. **Get Context** - Use `codegraph_context` for full understanding
   - Shows callers, callees, and impact score
   
3. **Make Changes** with full knowledge of what's affected

4. **Verify** all callers still work correctly

## Impact Score Guide

- **0-2 (LOW)**: Safe to modify, few dependencies
- **3-10 (MEDIUM)**: Check callers, may affect multiple paths  
- **10+ (HIGH)**: Critical function, changes ripple widely

## Available MCP Tools

| Tool | When to Use |
|------|-------------|
| `codegraph_impact` | Before modifying a function |
| `codegraph_context` | To understand a function's role |
| `codegraph_list` | To see endpoints, functions by type/file |
| `codegraph_analyze` | After adding new files or refactoring |
| `codegraph_changes` | To see what changed since last commit |
| `codegraph_info` | To see graph statistics |
| `codegraph_update` | To check for and install updates |

## When to Regenerate

Run `codegraph_analyze` (or CLI: `codegraph analyze`) after:
- Adding new files or functions
- Major refactoring
- When the graph feels outdated
```

This file instructs Cursor's AI to:
- Check impact before modifying shared functions
- Understand the dependency chain before refactoring
- Re-analyze after significant changes

## MCP Tools Reference

These tools are available to AI assistants in Cursor:

### `codegraph_analyze`

Analyze a codebase and generate the architecture graph.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `path` | string | No | Path to analyze (default: current directory) |
| `agent` | boolean | No | Also generate agent-friendly summary |

**Example:** "Analyze this project and generate a code graph"

---

### `codegraph_impact`

Show what code would be affected by changing a function.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `functionName` | string | Yes | Name of the function to analyze |
| `graphFile` | string | Yes | Absolute path to `.codegraph.json` |
| `depth` | number | No | Depth of analysis (default: 5) |

**Example:** "What would break if I change the `processPayment` function?"

---

### `codegraph_context`

Get detailed context around a function including callers and callees.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `functionName` | string | Yes | Name of the function |
| `graphFile` | string | Yes | Absolute path to `.codegraph.json` |
| `depth` | number | No | Depth of context (default: 2) |
| `direction` | string | No | `upstream`, `downstream`, or `both` |

**Example:** "Show me everything that calls `validateUser` and everything it calls"

---

### `codegraph_list`

List nodes in the graph with optional filtering.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `graphFile` | string | Yes | Absolute path to `.codegraph.json` |
| `type` | string | No | Filter by type: `function`, `class`, `http-endpoint`, etc. |
| `file` | string | No | Filter by file path |
| `name` | string | No | Filter by name pattern |
| `highImpact` | boolean | No | Show only high-impact nodes |

**Example:** "List all API endpoints in this project"

---

### `codegraph_info`

Show summary statistics about the architecture graph.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `graphFile` | string | No | Path to graph file |

**Example:** "How many functions and endpoints are in this project?"

---

### `codegraph_export`

Export the graph as an interactive HTML visualization.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `graphFile` | string | No | Input graph file |
| `output` | string | No | Output HTML file path |

**Example:** "Generate a visual architecture diagram"

---

### `codegraph_init`

Initialize CodeGraph in a project (creates Cursor rules and runs analysis).

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `path` | string | No | Path to initialize |

**Example:** "Set up CodeGraph in this project"

---

### `codegraph_changes`

Show architecture changes since a git commit. Compares current graph against the version in git history.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `graphFile` | string | Yes | Absolute path to `.codegraph.json` |
| `since` | string | No | Git ref: `HEAD` (default), `HEAD~1`, `HEAD~5`, `main`, branch name, or commit hash |

**Example:** "What functions have changed since last commit?"

**Example:** "Show me architecture changes in the last 5 commits"

---

### `codegraph_status`

Show diagnostic information about the CodeGraph installation.

**Example:** "Check if CodeGraph is installed correctly"

---

### `codegraph_update`

Check for and install CodeGraph updates.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `checkOnly` | boolean | No | Only check, don't install |
| `force` | boolean | No | Force reinstall even if already on latest version |

**Example:** "Update CodeGraph to the latest version"

**Example:** "Force reinstall CodeGraph"

## Real-time Updates

### Watch Mode

Monitor your codebase for changes and keep the graph updated in real-time:

```bash
codegraph watch
```

Features:
- Incrementally updates graph as files change
- Shows what was added/removed/modified
- Compares against last git commit
- Debounced writes to avoid thrashing

Options:
```bash
codegraph watch -p ./src      # Watch specific path
codegraph watch --no-git      # Disable git comparison
codegraph watch --debounce 2000  # 2 second debounce
```

### Diff Against Git

Compare current architecture against any point in git history:

```bash
codegraph diff              # Compare against HEAD (last commit)
codegraph diff HEAD~1       # Compare against 1 commit ago
codegraph diff HEAD~5       # Compare against 5 commits ago
codegraph diff main         # Compare against main branch
codegraph diff abc1234      # Compare against specific commit
```

**Tip:** Commit `.codegraph.json` to git so you have a baseline to compare against.

## Supported Languages

| Language | Status | Detection |
|----------|--------|-----------|
| TypeScript/JavaScript | ✅ Full | Functions, classes, imports, Express routes, **Next.js App Router**, Kafka, `this.method()` calls, index.ts re-exports, singleton instance calls |
| Python | ✅ Full | Functions, classes, decorators, FastAPI/Flask routes, `self`/`cls` method calls, `__init__.py` re-exports, singleton instance calls |
| Go | ✅ Basic | Functions, structs, methods |
| Rust | ✅ Basic | Functions, structs, impl blocks |
| C | ✅ Basic | Functions |
| Terraform | ✅ Full | Resources, modules, variables, outputs, data sources, providers, locals, cross-resource references, cloud service semantic mapping (AWS/GCP/Azure) |

## Updating

```bash
# Check for updates
codegraph update --check

# Update to latest version
codegraph update

# Force reinstall (even if already on latest)
codegraph update --force
```

Or reinstall via script:
```bash
curl -fsSL https://raw.githubusercontent.com/mitchellDrake/code-graph-releases/main/install.sh | bash
```

## Troubleshooting

### "unknown command" errors

Your CLI version is outdated. Update with:
```bash
codegraph update
```

### MCP tools not appearing in Cursor

1. Check `~/.cursor/mcp.json` has the correct path
2. Restart Cursor completely (Cmd+Q)
3. Run `codegraph_status` to verify installation

### Graph shows 0 nodes

- Make sure you're in the right directory
- Check the path doesn't have issues (spaces should be quoted)
- Run `codegraph analyze -p "/full/path/to/project"`

### "ENOENT .codegraph.json" error

The graph file doesn't exist. Run analysis first:
```bash
codegraph analyze --agent
```

## License

MIT

## Links

- [Source Code](https://github.com/mitchellDrake/code-graph) (Private)
- [Releases](https://github.com/mitchellDrake/code-graph-releases/releases)
- [Report Issues](https://github.com/mitchellDrake/code-graph-releases/issues)
