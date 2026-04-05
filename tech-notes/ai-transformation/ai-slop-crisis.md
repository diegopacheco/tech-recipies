# AI Slop Crisis

## What is it?

"AI slop" is digital content of low quality produced in quantity by artificial intelligence. Merriam-Webster named "slop" its 2025 Word of the Year. In software development, the term describes the flood of low-quality AI-generated pull requests, bug reports, vulnerability disclosures, and documentation that is overwhelming open source maintainers and degrading the commons. The cost of producing contributions dropped to near zero. The cost of reviewing them stayed the same. This asymmetry is breaking open source.

## The Numbers

```
┌─────────────────────────────────────────┬──────────────────────────────┐
│ Metric                                  │ Value                        │
├─────────────────────────────────────────┼──────────────────────────────┤
│ Agentic PRs studied (AIDev dataset)     │ 932,791 across 116,211 repos │
├─────────────────────────────────────────┼──────────────────────────────┤
│ Agents tracked                          │ Claude Code, Cursor, Devin,  │
│                                         │ Copilot, Codex               │
├─────────────────────────────────────────┼──────────────────────────────┤
│ Legitimate AI PRs                       │ ~10%                         │
├─────────────────────────────────────────┼──────────────────────────────┤
│ AI slop PRs                             │ ~90%                         │
├─────────────────────────────────────────┼──────────────────────────────┤
│ cURL bug bounty valid submission rate   │ <5% (was ~17% pre-AI)        │
├─────────────────────────────────────────┼──────────────────────────────┤
│ Jesse Vincent's Superpowers rejection   │ 94%                          │
├─────────────────────────────────────────┼──────────────────────────────┤
│ Maintainers who quit or considered it   │ 60%                          │
├─────────────────────────────────────────┼──────────────────────────────┤
│ Maintainers citing burnout              │ 44%                          │
└─────────────────────────────────────────┴──────────────────────────────┘
```

The AIDev dataset (MSR 2026 Mining Challenge) covers January 1 to August 1, 2025: 932,791 agentic PRs, 72,189 developers, 116,211 repositories. A curated subset of 33,596 PRs from 2,807 popular repositories (100+ stars) was enriched with comments, reviews, commits, and related issues.

## The Cost Asymmetry Problem

```
┌────────────────────────────────────────────────────────────────────┐
│                    The Fundamental Problem                          │
│                                                                    │
│  Cost to submit a PR:     Near zero (agent generates in minutes)   │
│  Cost to review a PR:     Same as always (human reads every line)  │
│                                                                    │
│  Before AI: Low contribution volume, high effort per contribution  │
│  After AI:  Massive contribution volume, same review effort        │
│                                                                    │
│  Result: Maintainers drown in "well-formed noise"                  │
│                                                                    │
│  "When code was hard to write and low-effort work was easy to      │
│   identify, it was worth the cost to review the good stuff.        │
│   If code is easy to write and bad work is virtually               │
│   indistinguishable from good, then the value of external          │
│   contribution is probably less than zero."                        │
│                                      — Steve Ruiz, tldraw          │
└────────────────────────────────────────────────────────────────────┘
```

## The cURL Bug Bounty Shutdown

Daniel Stenberg ran cURL's bug bounty program on HackerOne for 7 years. On January 31, 2026, he shut it down.

```
┌────────────────────────────────────────────────────────────────────┐
│                    cURL Bug Bounty Timeline                         │
│                                                                    │
│  Pre-2024    ──► ~1 in 6 reports are real vulnerabilities          │
│                                                                    │
│  Early 2024  ──► AI-generated reports begin flooding in            │
│                                                                    │
│  May 2025    ──► 20% of submissions identified as AI slop          │
│                  Only ~5% of all 2025 submissions are genuine       │
│                                                                    │
│  Late 2025   ──► Valid rate drops to 1 in 20 or 1 in 30           │
│                                                                    │
│  Jan 21 2026 ──► Stenberg commits "we stop the bug-bounty"        │
│                                                                    │
│  Jan 31 2026 ──► Last day on HackerOne                             │
│                                                                    │
│  Feb 1 2026  ──► Security reports move to GitHub directly          │
└────────────────────────────────────────────────────────────────────┘
```

Stenberg's words: "Never-ending slop submissions take a serious mental toll to manage and sometimes also a long time to debunk. Time and energy that is completely wasted while also hampering our will to live."

The AI-generated reports are "long, confident, and often completely fabricated" — citing nonexistent functions, including unverified patches, describing vulnerabilities that cannot be reproduced. The amount of time maintainers spend triaging each one is tantamount to a DDoS attack on the project.

Stenberg is not anti-AI. He praised developer Joshua Rogers for sending issues found using AI-assisted tools responsibly, noting that "AI can be a fine bug-hunting aid" when used by competent humans. The problem is unsupervised agents submitting fabricated reports.

## Projects That Changed Policies

```
┌──────────────────┬──────────────┬──────────────────────────────────────┐
│ Project          │ Date         │ Action                               │
├──────────────────┼──────────────┼──────────────────────────────────────┤
│ cURL             │ Jan 2026     │ Shut down bug bounty after 7 years   │
├──────────────────┼──────────────┼──────────────────────────────────────┤
│ tldraw           │ Jan 15 2026  │ Auto-close all external PRs          │
├──────────────────┼──────────────┼──────────────────────────────────────┤
│ Godot            │ Feb 2026     │ Maintainers publicly struggling      │
├──────────────────┼──────────────┼──────────────────────────────────────┤
│ GitHub           │ Feb 2026     │ Shipped kill switch for PRs           │
├──────────────────┼──────────────┼──────────────────────────────────────┤
│ Ghostty          │ Feb 2026     │ Zero tolerance, permanent bans       │
├──────────────────┼──────────────┼──────────────────────────────────────┤
│ LLVM             │ 2026         │ "Human in the loop" policy           │
├──────────────────┼──────────────┼──────────────────────────────────────┤
│ Jazzband         │ Mar 14 2026  │ Sunsetting after 10 years            │
├──────────────────┼──────────────┼──────────────────────────────────────┤
│ Linux Kernel     │ 2026         │ New guidelines for tool-generated    │
│                  │              │ submissions                          │
├──────────────────┼──────────────┼──────────────────────────────────────┤
│ Blender          │ Feb 2026     │ Proposed AI contributions policy     │
└──────────────────┴──────────────┴──────────────────────────────────────┘
```

### Godot Engine

Remi Verschelde: LLM-generated PRs are "increasingly draining and demoralizing" and a "massive time waster for reviewers." Changes "often make no sense, descriptions are extremely verbose, users don't understand their own changes." He noted it would be "horribly ironic" to run AI to detect AI slop. His only viable solution: "more funding so we can pay more maintainers to deal with the slop."

### tldraw

Steve Ruiz coined the term "well-formed noise" — PRs with correct syntax, plausible commit messages, apparent codebase understanding, but solving problems that do not exist or fixing bugs that are not real. Detecting them as invalid requires the same effort as reviewing legitimate contributions. tldraw auto-closes all external PRs as of January 15, 2026.

### Jazzband

Jannis Leidel (founder, Python Software Foundation chairperson) announced Jazzband is sunsetting after 10 years on March 14, 2026. The open-membership model (anyone joins, gets push access) became untenable. 3,135 members, 84 projects, ~93,000 combined GitHub stars, 150+ million monthly downloads. Leidel was the sole admin for the entire run. Projects migrating to Django Commons.

### Ghostty

Mitchell Hashimoto (HashiCorp founder): zero-tolerance policy. AI PRs only allowed for accepted issues. Drive-by AI PRs immediately closed. Bad AI contributors permanently banned. "This is not an anti-AI stance. This is an anti-idiot stance."

### Superpowers

Jesse Vincent's repository (120,000+ GitHub stars, ~300,000 Claude Code Marketplace installs) has a 94% PR rejection rate. Nearly every rejected PR was submitted by an agent that did not read or follow guidelines. Command-line agents bypass PR templates entirely. Vincent created a CLAUDE.md file to instruct AI agents directly.

## GitHub's Response

### Kill Switch for PRs (February 2026)

GitHub product manager Camilla Moraes: "We've been hearing from you that you're dedicating substantial time to reviewing contributions that do not meet project quality standards."

```
┌────────────────────────────────────────────────────────────────────┐
│                    GitHub's Countermeasures                         │
│                                                                    │
│  Shipped:                                                          │
│    • Disable pull requests entirely                                │
│    • Restrict PRs to collaborators only                            │
│                                                                    │
│  Coming:                                                           │
│    • Delete PRs from the UI                                        │
│    • More granular permission settings                             │
│    • AI-based triage tools                                         │
│    • Attribution/transparency signals for AI content               │
└────────────────────────────────────────────────────────────────────┘
```

GitHub product manager Matthew Isabel: "We don't think counting AI-generated PRs is the right metric. A bad PR is a bad PR, regardless of source."

### Copilot PR "Tips" Disaster (March 2026)

On March 28, 2026, Australian developer Zach Manson discovered that Copilot had injected promotional messages into pull request descriptions. Over 1.5 million PRs across GitHub and GitLab had promotional "tips" injected. Over 11,400 PRs contained a specific Raycast promotion. Other injected promotions pushed VS Code, Visual Studio, JetBrains, Eclipse, Slack, and Teams.

The real concern: Copilot modified someone else's content without consent. Manson: "I can't think of a valid use case for that ability."

GitHub principal PM Tim Rogers admitted that letting Copilot make changes to PRs written by a human without their knowledge "was the wrong judgement call." Tips disabled March 30, 2026. Microsoft blamed a "programming logic issue" introduced March 24 when Copilot's abilities were expanded.

## AI Slop Beyond Code

```
┌──────────────────────────┬──────────────────────────────────────────┐
│ Domain                   │ Impact                                   │
├──────────────────────────┼──────────────────────────────────────────┤
│ Bug Bounty Platforms     │ Fabricated vulnerability reports flood    │
│                          │ HackerOne and others. cURL was the       │
│                          │ highest-profile casualty.                │
├──────────────────────────┼──────────────────────────────────────────┤
│ Stack Overflow            │ AI answers banned since Dec 2022.       │
│                          │ Questions dropped 78% in 2025 (3,862    │
│                          │ in Dec 2025 vs prior year). Developers  │
│                          │ bypass SO entirely for AI tools.         │
├──────────────────────────┼──────────────────────────────────────────┤
│ Package Registries       │ 454,600+ new malicious packages in 2025.│
│                          │ 1.233M+ cumulative across npm, PyPI,    │
│                          │ Maven, NuGet, Hugging Face. 99% of      │
│                          │ open source malware on npm.              │
├──────────────────────────┼──────────────────────────────────────────┤
│ Supply Chain Attacks     │ IndonesianFoods campaign: 100K+ packages│
│                          │ in days (one every 7 seconds). Axios    │
│                          │ compromise (Mar 2026, 70M+ weekly DLs). │
│                          │ LiteLLM compromise (Mar 2026).          │
├──────────────────────────┼──────────────────────────────────────────┤
│ Documentation            │ AI-generated tutorials, answers, and    │
│                          │ docs degrade knowledge commons.          │
│                          │ Model collapse feedback loop: models     │
│                          │ trained on AI content get worse.         │
└──────────────────────────┴──────────────────────────────────────────┘
```

## Tragedy of the Commons

The arXiv paper "An Endless Stream of AI Slop" (March 2026, Baltes, Cheong, Treude) frames AI slop as a tragedy of the commons. Individual productivity gains externalize costs onto reviewers, maintainers, and the broader community.

```
┌────────────────────────────────────────────────────────────────────┐
│                    The Tragedy                                      │
│                                                                    │
│  Individual:  "AI helped me submit 10 PRs today!"                  │
│  Maintainer:  "I now have 300 PRs to review, 270 are garbage"      │
│                                                                    │
│  Individual:  "AI found 5 vulnerabilities in curl!"                │
│  Stenberg:    "None of these vulnerabilities exist"                │
│                                                                    │
│  Individual:  "I'm 10x more productive with AI"                   │
│  Ecosystem:   "We're 10x more buried in noise"                    │
│                                                                    │
│  The contributor captures 100% of the benefit.                     │
│  The maintainer absorbs 100% of the cost.                          │
└────────────────────────────────────────────────────────────────────┘
```

RedMonk framing: "AI slop is ripping up the social contract between maintainers and contributors essential to open source development." And: "AI slop is DDOSing OSS maintainers, and the platforms hosting OSS projects have no incentive to stop it. On the contrary, they're incentivized to inflate AI-generated contributions to show 'value' to their shareholders."

## Mitigation Approaches

```
┌──────────────────────┬─────────────────────────────────────────────┐
│ Approach             │ Details                                     │
├──────────────────────┼─────────────────────────────────────────────┤
│ Platform controls    │ GitHub kill switch, PR restrictions,        │
│                      │ PR deletion, granular permissions           │
├──────────────────────┼─────────────────────────────────────────────┤
│ Trust systems        │ Vouch (Mitchell Hashimoto): contributors    │
│                      │ must be vouched for by trusted members.     │
│                      │ Cross-project trust aggregation.            │
├──────────────────────┼─────────────────────────────────────────────┤
│ Zero tolerance       │ Ghostty model: permanent bans for bad      │
│                      │ AI contributors                             │
├──────────────────────┼─────────────────────────────────────────────┤
│ Auto-close external  │ tldraw model: close all outside PRs        │
├──────────────────────┼─────────────────────────────────────────────┤
│ Agent instructions   │ CLAUDE.md files that instruct AI agents     │
│                      │ directly about contribution standards       │
├──────────────────────┼─────────────────────────────────────────────┤
│ Detection tools      │ Pangram Labs (trained on GPT-4/Claude/      │
│                      │ LLaMA), ai-gen-code-search, git-ai,        │
│                      │ custom GitHub Actions                       │
├──────────────────────┼─────────────────────────────────────────────┤
│ Human-in-the-loop    │ LLVM policy: AI-assisted OK, autonomous     │
│ policies             │ agents prohibited. Contributor must defend  │
│                      │ design decisions.                           │
├──────────────────────┼─────────────────────────────────────────────┤
│ Policy research      │ RedMonk analyzed 73-77 org policies.       │
│                      │ Separate study examined 67 projects.        │
└──────────────────────┴─────────────────────────────────────────────┘
```

None of these solutions address the root cause: the cost asymmetry between submitting and reviewing.

## The Word Itself

```
┌────────────────────────────────────────────────────────────────────┐
│                    "Slop" — Word History                            │
│                                                                    │
│  1700s  ──► "Soft mud"                                             │
│  1800s  ──► "Food waste / pig slop"                                │
│  1900s  ──► "Rubbish"                                              │
│  2022   ──► First uses of "AI slop" online                         │
│  2024   ──► Simon Willison and Casey Newton popularize it          │
│  Aug 2024 ──► Usage explodes after Google Gemini backlash          │
│  2025   ──► Usage increases 9x year-over-year                      │
│           ──► 475,000+ mentions in 30 days across platforms        │
│  Dec 2025 ──► Merriam-Webster Word of the Year                     │
│  Jan-Mar 2026 ──► Explosion in software development context        │
│              ──► cURL, tldraw, Ghostty, Godot, Jazzband,           │
│                  GitHub kill switch in rapid succession             │
│  Feb 2026 ──► RedMonk coins "AI Slopageddon"                      │
└────────────────────────────────────────────────────────────────────┘
```

Merriam-Webster's new definition: "digital content of low quality that is produced usually in quantity by means of artificial intelligence."

## The Research

```
┌──────────────────────────────────────────────────────────────────────┐
│ Paper                                          │ Key Finding         │
├────────────────────────────────────────────────┼─────────────────────┤
│ How AI Agents Modify Code (arXiv:2601.17581)  │ 932K agentic PRs    │
│                                                │ analyzed, agents    │
│                                                │ differ substantially│
│                                                │ from humans in      │
│                                                │ commit patterns     │
├────────────────────────────────────────────────┼─────────────────────┤
│ Where AI Agents Fail (arXiv:2601.15195)       │ Failure modes of    │
│                                                │ agentic PRs         │
├────────────────────────────────────────────────┼─────────────────────┤
│ An Endless Stream of AI Slop                   │ Tragedy of the      │
│ (arXiv:2603.27249)                             │ commons framing,    │
│                                                │ 1,154 posts across  │
│                                                │ 15 discussion       │
│                                                │ threads analyzed    │
├────────────────────────────────────────────────┼─────────────────────┤
│ Why Agentic PRs Get Rejected                   │ Comparative study   │
│ (arXiv:2602.04226)                             │ of rejection reasons│
├────────────────────────────────────────────────┼─────────────────────┤
│ Security in the Age of AI Teammates            │ Security impact of  │
│ (arXiv:2601.00477)                             │ agentic PRs         │
├────────────────────────────────────────────────┼─────────────────────┤
│ Breaking Changes: Human vs Agentic PRs         │ Agentic PRs create  │
│ (arXiv:2603.27524)                             │ different risk      │
│                                                │ profiles            │
└────────────────────────────────────────────────┴─────────────────────┘
```

## What This Means

The AI slop crisis is the externality of the AI coding revolution. Every tool that makes contribution easier without making review easier accelerates the problem. The open source model assumed that contribution had a meaningful cost floor — writing code required skill, time, and understanding. AI removed that floor. The social contract between contributor and maintainer — "I invested effort, please invest attention" — is broken when the effort is zero.

The projects that survive will be the ones that rebuild the trust layer: vouching systems, contribution gates, agent-aware policies, and platforms that make review cheaper, not just contribution cheaper. The rest will drown.

## Links

- AIDev Dataset (MSR 2026): https://github.com/SAILResearch/AI_Teammates_in_SE3
- How AI Agents Modify Code (932K PRs): https://arxiv.org/html/2601.17581
- Failed Agentic PRs: https://arxiv.org/html/2601.15195
- An Endless Stream of AI Slop: https://arxiv.org/abs/2603.27249
- cURL Ends Bug Bounty: https://www.theregister.com/2026/01/21/curl_ends_bug_bounty/
- tldraw Auto-Close Policy: https://tldraw.dev/blog/stay-away-from-my-trash
- Godot Maintainer Burnout: https://www.theregister.com/2026/02/18/godot_maintainers_struggle_with_draining/
- Jazzband Sunsetting: https://jazzband.co/news/2026/03/14/sunsetting-jazzband
- GitHub Kill Switch for PRs: https://www.theregister.com/2026/02/03/github_kill_switch_pull_requests_ai/
- GitHub Copilot PR Tips Backlash: https://www.theregister.com/2026/03/30/github_copilot_ads_pull_requests/
- Ghostty Zero Tolerance: https://github.com/ghostty-org/ghostty/pull/10412
- LLVM Human-in-the-Loop Policy: https://www.phoronix.com/news/LLVM-Human-In-The-Loop
- Vouch Trust System (Hashimoto): https://itsfoss.com/news/mitchell-hashimoto-vouch/
- Jesse Vincent on Slop PRs: https://blog.fsck.com/2026/03/31/slop-prs/
- RedMonk AI Slopageddon: https://redmonk.com/kholterhoff/2026/02/03/ai-slopageddon-and-the-oss-maintainers/
- RedMonk Policy Landscape: https://redmonk.com/kholterhoff/2026/02/26/generative-ai-policy-landscape-in-open-source/
- Merriam-Webster Word of the Year: https://www.merriam-webster.com/wordplay/word-of-the-year
- Sonatype Malware Report: https://www.sonatype.com/state-of-the-software-supply-chain/2026/open-source-malware
- Stack Overflow Question Decline: https://www.devclass.com/ai-ml/2026/01/05/dramatic-drop-in-stack-overflow-questions-as-devs-look-elsewhere-for-help/4079575
