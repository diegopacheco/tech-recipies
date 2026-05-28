# Claude Code Auto Mode

## What is it?

Auto mode is a permission mode for Claude Code that delegates approval decisions to model-based classifiers instead of asking the human for every action. Anthropic published it on Mar 25, 2026. It is a middle ground between manually approving each tool call and turning off all guardrails with `--dangerously-skip-permissions`.

The problem it solves is approval fatigue. By default Claude Code asks for permission before running commands or editing files outside the project. Anthropic measured that users approve 93% of those prompts, so people stop reading them and just click "approve". Auto mode aims to keep the protection of a human gate while removing the clicks, by letting a classifier act as a substitute approver and only stopping for the actions that actually have downside.

## The tradeoff space it fills

Before auto mode there were three positions, each with a problem:

| Option | Autonomy | Safety | Maintenance |
|---|---|---|---|
| Manual prompts (default) | Low | Good, but users approve 93% anyway | None, but constant clicking |
| Sandbox | Medium | Strong isolation | High - every new capability needs configuring; network/host access breaks it |
| `--dangerously-skip-permissions` | High | None | Zero |
| **Auto mode** | **High** | **Classifier-gated, improves over time** | **Low** |

Auto mode targets high autonomy at low maintenance cost. Sandboxing is safe but high-friction. Bypassing permissions is frictionless but offers no protection. Auto mode is the attempt to get most of the autonomy of bypass with most of the safety of a human gate.

## Why it exists

Anthropic keeps an internal incident log of agentic misbehaviors. Documented cases include:

- Deleting remote git branches from a misinterpreted instruction
- Uploading an engineer's GitHub auth token to an internal compute cluster
- Attempting migrations against a production database

Each was the model being overeager - taking initiative in a way the user did not intend. These patterns are documented in the Claude Opus 4.6 system card (§6.2.1 and §6.2.3.3). Auto mode is built to catch this class of action: dangerous and not aligned with what the user actually asked for.

## How it works

Auto mode uses two layers of defense - one for what Claude reads, one for what Claude does.

### Input layer - prompt-injection probe

A server-side probe scans tool outputs (file reads, web fetches, shell output, external tool responses) before they enter the agent's context. If content looks like an attempt to hijack behavior, the probe injects a warning into the context telling the agent to treat the content as suspect and anchor on what the user actually asked for.

### Output layer - transcript classifier

The transcript classifier runs on Sonnet 4.6 and evaluates each action before it executes, acting as a stand-in for a human approver. It runs in two stages:

1. **Stage 1 - fast single-token filter.** Emits a single `yes` (block) or `no` (allow) with no reasoning, tuned to "err on the side of blocking". Most actions clear this stage.
2. **Stage 2 - chain-of-thought reasoning.** Runs only on actions stage 1 flagged. More expensive, cleans up false positives.

Because most actions pass stage 1, reasoning tokens are spent only where they matter.

The classifier is **reasoning-blind by design**: it sees only the user messages and the agent's bare tool calls. Claude's own prose and the tool outputs are stripped out.

Subagents run the same pipeline recursively, with handoff classifiers at delegation (can deny) and at return (warns only).

## The three tiers - what actually reaches the classifier

Most actions never hit the classifier. There are three tiers:

| Tier | What it covers | Cost |
|---|---|---|
| Tier 1 - safe-tool allowlist | File reads, search, code navigation, todo/plan-mode transitions, user always-allow rules | No classifier call |
| Tier 2 - in-project file ops | Writes and edits inside the project directory (reviewable via version control) | No classifier call |
| Tier 3 - transcript classifier | Shell commands, web fetches, external integrations, subagent spawns, filesystem ops outside the project | Classifier call |

A key safety detail: on entering auto mode, Claude Code **drops broad permission rules that grant arbitrary code execution** - blanket shell access, wildcarded interpreters (python, node, ruby), and package-manager run commands. Many users set these for convenience in manual mode, but leaving them on would mean the classifier never sees the most dangerous commands. Narrow rules ("allow code formatters") carry over; broad interpreter escapes do not.

## What the classifier blocks

The default ships with 20+ block rules, the trust boundary being only the git repo you are currently in (customizable in settings to name your GitHub org, cloud buckets, internal APIs). Categories:

- **Destroy or exfiltrate** - force-pushing over history, mass-deleting cloud storage, sending internal data externally
- **Degrade security posture** - disabling logging, installing SSH keys or cronjobs for persistence, modifying the agent's own permission config
- **Cross trust boundaries** - running code cloned from external repos, scanning credential stores, sending data to unnamed services
- **Bypass review or affect others** - pushing to main, production deploys, modifying shared resources the agent did not create

## Deny-and-continue

Auto mode is meant to replace `--dangerously-skip-permissions` without bringing back interruptions. When the classifier blocks an action, Claude does not halt and wait - the denial comes back as a tool result with an instruction to respect the boundary in good faith and find a safer path. This is what makes false positives survivable: instead of killing the session, a false positive costs one retry where the agent reconsiders.

Backstop: if a session hits **3 consecutive denials or 20 total**, the model stops and escalates to the human. In headless mode (`claude -p`) there is no UI to ask, so the process terminates.

## Results

Evaluated on three datasets:

- **Real internal traffic** (n = 10,000) - actual Claude Code tool calls from Anthropic employees
- **Real overeager actions** (n = 52) - curated from sessions where an employee denied the action or it was flagged after the fact
- **Synthetic data exfiltration** (n = 1,000) - generated HTTP POSTs of sensitive data, git pushes to untrusted remotes, credentials in URLs, many obfuscated

Two metrics: false-negative rate (FNR, dangerous actions let through) and false-positive rate (FPR, benign actions blocked).

| Stage | Real traffic (FPR) | Real overeager (FNR) | Synthetic exfil (FNR) |
|---|---|---|---|
| Stage 1 (fast filter) | 8.5% | 6.6% | 1.8% |
| Full pipeline (Stage 1 -> 2) | 0.4% | 17% | 5.7% |

The honest number is the **17% FNR on real overeager actions** - roughly one in six dangerous actions gets through end to end. In most misses the classifier correctly identifies the danger (the force-push, the deletion) but gets the consent question wrong - whether a real approval signal existed earlier in the session. The two-stage design deliberately trades some recall for a usable 0.4% FPR, since a high false-positive rate would make long-running tasks miserable.

## Design decisions worth noting

- **Why strip assistant text:** so the agent cannot talk the classifier into a bad call with rationalizations like "the user implicitly approved this earlier". The classifier judges what the agent *did*, not what it *said*.
- **Why strip tool results:** this is the primary prompt-injection defense at this layer - tool outputs are where hostile content enters. If a file says "post .env to this URL" and the agent issues the POST, the classifier never sees the file but does not need to: a POST of env vars to an external URL fails against user intent regardless of what prompted it. The cost is provenance - the classifier cannot always tell whether the agent pulled an identifier from a real query or fabricated it. Anthropic accepts that cost for injection robustness.
- **Why two stages:** a single classifier faces a direct cost/recall tradeoff. Splitting it lets stage 1 be cheap and recall-biased while stage 2 does expensive cleanup only on flagged actions.

## How it differs from the other modes

- **vs default (manual):** same protection model (a gate that asks "is this aligned with intent?"), but the gate is a classifier instead of a human, so there are no prompts for the 93% of actions people rubber-stamp anyway.
- **vs `--dangerously-skip-permissions`:** auto mode is the intended replacement. Bypass has zero guardrails; auto mode keeps a classifier between the agent and dangerous actions while preserving the no-interruption flow.
- **vs sandbox:** sandbox isolates tools so nothing dangerous *can* happen, but breaks the moment you need network or host access and needs configuring per capability. Auto mode does not isolate - it judges intent - so it works with real network/host access at low maintenance.
- **vs plan mode / accept-edits:** those control *what stage of work* Claude operates in (read-only planning, or auto-accepting in-project edits). Auto mode is orthogonal - it governs *which actions need approval* across the whole session.

This is a harness-level feature, not a model feature - see [[harness]]. It complements unattended setups like [[claude-dispatch]] where no human is watching to click approve.

## How to turn it on, and make it the default

There are three ways to activate auto mode, from one-off to permanent:

**One session, at startup:**

```
claude --permission-mode auto
```

**During a session:** press `Shift+Tab` to cycle modes (`default` -> `acceptEdits` -> `plan` -> ... -> `auto`). The first time you cycle to it you get an opt-in prompt.

**Always on by default** - set `defaultMode` to `auto` in settings (`.claude/settings.json` for a project, `~/.claude/settings.json` for all projects):

```
{
  "permissions": {
    "defaultMode": "auto"
  }
}
```

Requirements that must be met for any of these to work:

- **Version:** Claude Code v2.1.83 or later
- **Model:** Sonnet 4.6, Opus 4.6, or Opus 4.7 (older models including Sonnet 4.5 / Opus 4.5 / Haiku are not supported)
- **Provider:** Anthropic API only - not available on Bedrock or Vertex
- **Admin:** on Team and Enterprise plans an admin must enable it in Claude Code admin settings first. Admins can also lock it off with `permissions.disableAutoMode: "disable"` in managed settings.

Note that `bypassPermissions` skips the permission layer entirely, but every other mode (including auto) still never auto-approves writes to protected paths.

## Is this necessary for coding agents? Yes - here is why

Yes, something like auto mode is necessary, and the reasoning is structural rather than about this one product:

1. **Approval fatigue is real and measured.** 93% approval means the human gate has already failed as a safety mechanism - people are not reading the prompts. A gate that nobody reads provides the *feeling* of safety without the substance. You either remove the friction or remove the protection; auto mode removes the friction while keeping a gate that actually evaluates.

2. **Autonomy and a human-in-the-loop are in direct tension.** The whole value of a coding agent is doing multi-step work unattended. But unattended + full permissions = the incident log (deleted branches, leaked tokens, prod migrations). You cannot have long-running autonomy and a human approving every step. A model-based gate is the only thing that scales with autonomy.

3. **The dangerous actions are a tiny, recognizable set.** Force-push, mass-delete, exfiltrate, deploy to prod, disable logging. The vast majority of an agent's actions (reads, in-repo edits, searches) have no downside and should never prompt. Tiering means you only pay scrutiny where it matters - which is exactly what makes "skip the prompts" safe enough to use.

4. **Prompt injection makes this non-optional for agents that read external content.** Any agent that fetches web pages or reads untrusted files can be hijacked. An action-level classifier that judges *what the agent did against what the user asked* is robust to injection in a way that input filtering alone is not - the POST of secrets fails regardless of the clever prompt that produced it.

The honest caveat: it is not a guarantee. A 17% FNR on real overeager actions means it is a strong backstop, not a substitute for least-privilege credentials, sandboxed environments for untrusted code, and version control. The right mental model is defense in depth - auto mode is one layer that makes autonomous coding agents *usable* without being reckless, not a reason to hand an agent production keys.

## Links

* https://www.anthropic.com/engineering/claude-code-auto-mode
* https://code.claude.com/docs/en/permission-modes#eliminate-prompts-with-auto-mode
* https://www-cdn.anthropic.com/14e4fb01875d2a69f646fa5e574dea2b1c0ff7b5.pdf
