# Prompting Guide for GPT and Claude

A practical guide to writing better prompts for AI assistants like ChatGPT (GPT) and Claude. This guide is written for general users, not developers.

---

## 1. Bad vs Good Prompt Examples

The single biggest reason people get bad results from AI is that their prompts leave too much room for guesswork. Small changes in how you ask lead to massive changes in what you get back.

### Pair 1: Writing an Email

**Bad prompt:**
```
Write me an email.
```

**Good prompt:**
```
Write a professional email to my landlord requesting a repair
for a leaking kitchen faucet. Keep it polite but firm.
Mention that I first reported this issue two weeks ago.
Keep it under 150 words.
```

**Why it works:** The good prompt specifies who the email is for, what tone to use, what details to include, and how long it should be.

---

### Pair 2: Summarizing Something

**Bad prompt:**
```
Summarize this article.
```

**Good prompt:**
```
Summarize this article in 3 bullet points. Focus on the main
argument, the evidence used, and the conclusion. Write it so
a high school student could understand it.
```

**Why it works:** The good prompt defines the format (bullet points), what to focus on, and the reading level of the audience.

---

### Pair 3: Learning a New Topic

**Bad prompt:**
```
Explain quantum physics.
```

**Good prompt:**
```
Explain quantum physics to someone with no science background.
Use everyday analogies. Start with the most basic concept and
build up. Keep it under 300 words.
```

**Why it works:** The good prompt sets the audience level, requests analogies for clarity, asks for a logical structure, and sets a length limit.

---

### Pair 4: Creative Writing

**Bad prompt:**
```
Write a story.
```

**Good prompt:**
```
Write a short story (500 words) about a retired detective who
discovers a mystery in her own neighborhood. Set it in a small
coastal town. Use a suspenseful tone. End with a cliffhanger.
```

**Why it works:** The good prompt gives character details, setting, tone, length, and a specific ending style.

---

### Pair 5: Getting Advice

**Bad prompt:**
```
How do I get healthy?
```

**Good prompt:**
```
I'm a 35-year-old office worker who sits most of the day. I have
30 minutes available before work each morning. Suggest a simple
beginner-friendly exercise routine I can do at home with no
equipment. Include a weekly schedule.
```

**Why it works:** The good prompt provides personal context, time constraints, limitations (no equipment), experience level, and a desired output format (weekly schedule).

---

### Pair 6: Asking for Feedback

**Bad prompt:**
```
Is my resume good?
```

**Good prompt:**
```
Review my resume below. I'm applying for a marketing manager
position at a mid-size tech company. Point out any weaknesses
in how I present my experience. Suggest specific improvements
for each section. Be direct and honest.

[paste resume here]
```

**Why it works:** The good prompt tells the AI what role you are targeting, what kind of feedback you want, and asks for actionable suggestions rather than a generic yes or no.

---

### Key Takeaways for Better Prompts

- Tell the AI WHO the output is for (audience)
- Tell the AI WHAT format you want (list, email, table, story)
- Tell the AI HOW LONG the response should be
- Tell the AI WHAT TONE to use (formal, casual, funny, serious)
- Give CONTEXT about your situation
- Use positive instructions ("write in simple language") instead of negative ones ("don't be complicated")

---

## 2. Prompt Frameworks

Prompt frameworks are structured templates that help you write better prompts consistently. Think of them as fill-in-the-blank recipes for talking to AI.

### CO-STAR Framework

Developed by data scientist Sheila Teo, winner of Singapore's first GPT-4 Prompt Engineering competition.

| Letter | Stands For | What It Means |
|--------|-----------|---------------|
| C | Context | Background information and situation |
| O | Objective | What you want the AI to achieve |
| S | Style | Writing style (formal, casual, academic) |
| T | Tone | Emotional quality (friendly, serious, humorous) |
| A | Audience | Who will read the output |
| R | Response | Desired format (list, essay, table, email) |

**CO-STAR Applied:**
```
Context: I run a small bakery that just started offering online ordering.
Objective: Write a social media post announcing our new online ordering system.
Style: Conversational and warm, like talking to a neighbor.
Tone: Excited and inviting.
Audience: Local community members aged 25-55.
Response: A short social media post (under 100 words) with a call to action.
```

---

### RISEN Framework

Created by Kyle Balmer. Good for complex or multi-step tasks.

| Letter | Stands For | What It Means |
|--------|-----------|---------------|
| R | Role | Who should the AI pretend to be |
| I | Instructions | The data or information you provide |
| S | Steps | Specific actions the AI should follow in order |
| E | End Goal | The final result you want |
| N | Narrowing | Constraints, limits, and things to exclude |

**RISEN Applied:**
```
Role: You are a travel planner with 20 years of experience.
Instructions: I'm planning a 7-day trip to Japan in April with my
  partner. We enjoy food, culture, and nature. Budget is $3,000
  per person (excluding flights).
Steps: 1) Suggest a day-by-day itinerary. 2) Include restaurant
  recommendations for each city. 3) Add transportation tips
  between cities.
End Goal: A complete, printable travel plan we can follow.
Narrowing: No luxury hotels. No guided group tours. Focus on
  experiences locals would recommend.
```

---

### CREATE Framework

A six-part framework especially useful for iterative work where you refine results.

| Letter | Stands For | What It Means |
|--------|-----------|---------------|
| C | Character | The role or persona the AI should adopt |
| R | Request | What you specifically want done |
| E | Examples | Samples of the kind of output you want |
| A | Adjustments | Refinements after seeing the first result |
| T | Type of Output | The format or structure of the final result |
| E | Extras | Additional references, context, or rules |

**CREATE Applied:**
```
Character: You are an experienced children's book author.
Request: Write a bedtime story for a 5-year-old about a brave little owl.
Examples: Similar in style to "Goodnight Moon" -- simple sentences,
  repetition, calming rhythm.
Adjustments: (used after first draft) Make it shorter, add more
  rhyming words.
Type of Output: A story of about 200 words, broken into short paragraphs.
Extras: The owl should learn that being afraid of the dark is okay.
  No scary elements.
```

---

### RTF (Role, Task, Format)

The simplest framework. Good for quick, everyday prompts.

| Letter | Stands For | What It Means |
|--------|-----------|---------------|
| R | Role | Who the AI should act as |
| T | Task | What you want done |
| F | Format | How the output should look |

**RTF Applied:**
```
Role: You are a nutritionist.
Task: Create a healthy meal plan for someone trying to eat
  more vegetables.
Format: A 5-day table with columns for breakfast, lunch, dinner,
  and one snack.
```

---

### Other Notable Frameworks

**CARE (by Nielsen Norman Group):**
- C = Context (background)
- A = Action (what to do)
- R = Result (desired outcome)
- E = Example (sample of what you want)

**ERA:**
- E = Expectation (what you expect)
- R = Role (who the AI should be)
- A = Action (what to do)

**TIDD-EC:**
- T = Task
- I = Instructions
- D = Do (actions)
- D = Details
- E = Exclusions
- C = Confirmation

---

### Which Framework Should You Use?

| Situation | Best Framework |
|-----------|---------------|
| Quick everyday questions | RTF |
| Social media posts or marketing | CO-STAR |
| Complex multi-step projects | RISEN |
| Creative work with revisions | CREATE |
| Simple tasks with clear goals | CARE or ERA |

You do not need to memorize these. Pick one that feels natural and use it as a mental checklist when your prompts are not giving you good results.

---

## 3. AI Slop: What It Is and How to Avoid It

### What Is AI Slop?

"Slop" was named the 2025 Word of the Year by Merriam-Webster. It refers to low-quality, mass-produced AI-generated content that sounds polished on the surface but lacks substance, originality, or genuine thought.

Three defining characteristics of AI slop:
1. **Superficial competence** -- it sounds smart but says nothing specific
2. **Asymmetric effort** -- it takes zero effort to produce and almost zero thought went into it
3. **Mass producibility** -- it could have been written about anything, for anyone

### Common Slop Words

These words appear far more often in AI-generated text than in human writing. A 2025 study from the Max Planck Institute found that words like "delve," "robust," and "pivotal" spiked in usage by over 50% since ChatGPT launched.

**Single Words to Watch For:**

| Word | Why It Is Slop |
|------|--------------|
| Delve | Almost never used by real people in conversation |
| Tapestry | Overused metaphor ("a tapestry of experiences") |
| Landscape | Vague filler ("the competitive landscape") |
| Leverage | Corporate buzzword used as a verb for everything |
| Robust | Applied to everything from software to sandwiches |
| Seamless | Meaningless when applied to every experience |
| Pivotal | Every event becomes "pivotal" in AI writing |
| Multifaceted | Used to avoid being specific |
| Holistic | Sounds deep but adds no information |
| Synergy | Corporate jargon that means almost nothing |
| Paradigm | Overused to sound intellectual |
| Cutting-edge | Tired cliche |
| Groundbreaking | Almost never accurate |
| Game-changer | Hyperbolic and overused |
| Embark | "Let's embark on this journey" -- nobody talks like this |
| Navigate | "Navigate the complexities" -- filler phrase |
| Harness | "Harness the power of" -- empty marketing language |
| Foster | "Foster collaboration" -- vague |
| Underscore | Used instead of "show" or "prove" |
| Realm | "In the realm of" -- unnecessary padding |

**Phrases to Watch For:**

| Phrase | Problem |
|--------|---------|
| "In today's fast-paced world" | Generic opening that says nothing |
| "It's worth noting that" | Filler that delays the actual point |
| "Let's dive into" / "Let's delve into" | Overused transition |
| "At the end of the day" | Cliche with no content |
| "Here's the thing" | Stalling phrase |
| "In conclusion" | Robotic closing |
| "Moving forward" | Vague and empty |
| "It's important to note" | If it is important, just say it |
| "A testament to" | Sounds grand, says little |
| "At the forefront of" | Generic praise |
| "Embrace the future" | Meaningless motivation |
| "Furthermore" / "Moreover" | Over-formal connectors |
| "The human mind is a tapestry of" | Purple prose that AI loves |
| "In an ever-changing world" | Says nothing specific |

### How to Reduce Slop in AI Outputs

**In your prompt, add instructions like:**

```
Write in plain, direct language. Avoid buzzwords and filler phrases.
Do not use words like "delve," "tapestry," "landscape," "leverage,"
"robust," or "seamless." Write the way a person would actually talk.
No generic openings like "In today's fast-paced world."
```

**Other tips:**
- Ask the AI to "write like a human, not a press release"
- Tell it to "be specific instead of vague"
- Request that it "cut any sentence that could apply to any topic"
- Ask it to "use simple, everyday words"
- If the output sounds like a corporate brochure, ask it to rewrite in a more natural voice
- Provide a writing sample of the tone you want and say "match this style"

---

## 4. Prompt Patterns and Techniques

These are practical techniques you can use regardless of which AI tool you prefer.

### Chain-of-Thought

Ask the AI to think through a problem step by step before giving a final answer. This dramatically improves accuracy on reasoning tasks.

**Without chain-of-thought:**
```
If I have 23 apples and give away 7, then buy 12 more, and then
split what I have equally among 4 people, how many does each
person get?
```

**With chain-of-thought:**
```
If I have 23 apples and give away 7, then buy 12 more, and then
split what I have equally among 4 people, how many does each
person get? Think through this step by step before giving your
final answer.
```

The simplest version: just add "Think step by step" or "Show your reasoning" to the end of a prompt.

---

### Few-Shot Prompting

Give the AI a few concrete outputs before asking it to produce its own. This is one of the most effective techniques available. Aim for 3 to 5 samples.

**Without few-shot:**
```
Classify these customer reviews as positive, negative, or neutral.
```

**With few-shot:**
```
Classify customer reviews as positive, negative, or neutral.

Review: "Absolutely love this product, best purchase this year!"
Classification: Positive

Review: "It broke after two days. Complete waste of money."
Classification: Negative

Review: "It works fine. Nothing special."
Classification: Neutral

Now classify these:
Review: "Pretty good for the price, though shipping was slow."
Review: "I will never buy from this company again."
Review: "Exactly what I expected, does the job."
```

---

### Role Assignment (Persona Prompting)

Telling the AI to act as a specific type of person changes the vocabulary, depth, and perspective of the output.

**Without a role:**
```
How should I invest my money?
```

**With a role:**
```
You are a conservative financial advisor who specializes in
helping first-time investors in their 30s. I have $10,000
to invest and I'm risk-averse. What would you recommend?
```

**Useful roles for everyday tasks:**
- "You are an experienced editor" (for improving your writing)
- "You are a patient teacher who explains things simply" (for learning)
- "You are a career coach" (for job search advice)
- "You are a doctor explaining to a patient" (for health information)
- "You are a skeptical journalist" (for getting balanced perspectives)

---

### Output Format Specification

Telling the AI exactly what format you want prevents you from getting a wall of text when you wanted a simple list.

**Format options you can request:**
- "Give me a numbered list"
- "Present this as a table with columns for X, Y, and Z"
- "Write this as bullet points"
- "Format this as a step-by-step guide"
- "Give me a pros and cons list"
- "Write this as a FAQ with questions and answers"
- "Present this as a timeline"
- "Summarize in exactly 3 sentences"

**Applied:**
```
Compare working from home vs working from an office.
Format your response as a table with three columns:
Factor, Work From Home, Work From Office.
Include at least 8 factors.
```

---

### Constraints and Guardrails

Setting boundaries keeps the AI focused and prevents it from going off track.

**Types of constraints you can set:**
- **Length:** "Keep your response under 200 words"
- **Scope:** "Only discuss the financial aspects, not the emotional ones"
- **Exclusions:** "Do not include any medical advice"
- **Reading level:** "Write at a 6th grade reading level"
- **Sources:** "Only reference information from after 2023"
- **Tone:** "Do not use humor or sarcasm"
- **Language:** "Avoid jargon and technical terms"

**Applied:**
```
Explain how credit scores work.
Constraints:
- Under 300 words
- No financial jargon
- Include one real-world analogy
- Do not recommend any specific financial products
- Write for someone who has never had a credit card
```

---

### Step-by-Step Instructions

When you need the AI to follow a specific process, number your steps explicitly.

**Applied:**
```
I want to write a thank-you note after a job interview.

Follow these steps:
1. Ask me the name of the interviewer and the company.
2. Ask me what specific topics we discussed.
3. Ask me what I liked most about the opportunity.
4. Using my answers, draft a professional thank-you email
   that is warm but not overly casual. Keep it under 150 words.
```

This turns the AI into an interactive assistant that gathers information before producing output, rather than guessing at details.

---

### Combining Techniques

The most effective prompts often combine multiple techniques together.

**Combined prompt:**
```
You are a senior hiring manager at a tech company (role).

I'm going to show you three cover letter openings. For each one,
rate it on a scale of 1-10 and explain why (format).

Opening 1: "I am writing to express my interest in..."
Opening 2: "When I saw your job posting, I immediately thought
of the project I led at..."
Opening 3: "I've been following your company's work in renewable
energy for three years..."

After rating all three, explain what makes a strong cover letter
opening in general. Think through what hiring managers actually
care about (chain-of-thought). Keep your total response under
400 words (constraint).
```

---

## 5. Common Anti-Patterns (Prompting Mistakes)

### Mistake 1: Being Too Vague

**The problem:** Asking "What time is high tide?" without saying where or when. The AI has to guess, and it will guess wrong.

**The fix:** Always include the specific details that matter. Who, what, where, when, why, how much, how long.

---

### Mistake 2: Overloading a Single Prompt

**The problem:** Cramming five unrelated requests into one message. "Write me a resume, plan my vacation, explain Bitcoin, and give me a recipe for dinner."

**The fix:** One task per prompt. If tasks are related, break them into a logical sequence. Handle them one at a time.

---

### Mistake 3: Using Negative Instructions

**The problem:** "Don't be boring. Don't use jargon. Don't be too long."

**The fix:** Tell the AI what TO do instead of what NOT to do. "Write in an engaging, conversational tone. Use simple language. Keep it under 200 words."

AI models respond better to positive instructions because they tell the model what direction to go, rather than listing all the directions to avoid.

---

### Mistake 4: Skipping Context

**The problem:** "How do I fix this?" without explaining what "this" is, what you have already tried, or what your situation looks like.

**The fix:** Give background. Explain your situation. Share what you have already tried. The more relevant context you provide, the more useful the answer.

---

### Mistake 5: Contradictory Instructions

**The problem:** Asking for a "detailed summary" or a "brief comprehensive analysis." These are contradictions. The AI does not know which instruction to prioritize.

**The fix:** Be consistent. If you want detail, say "detailed." If you want brevity, say "brief." Pick one direction and commit to it.

---

### Mistake 6: Not Iterating

**The problem:** Accepting the first output as the final answer. One-and-done prompting rarely gives the best results.

**The fix:** Treat the first response as a draft. Give feedback. Ask the AI to revise specific parts. Say things like "Make the second paragraph more concise" or "Add more specific numbers to point three."

---

### Mistake 7: Trusting Without Verifying

**The problem:** Assuming everything the AI says is factually correct. AI models can generate plausible-sounding information that is completely wrong (this is called hallucination).

**The fix:** Always verify important facts, especially dates, statistics, names, and scientific claims. Use the AI as a starting point, not as a source of truth.

---

### Mistake 8: Same Prompt for Every Model

**The problem:** Using the exact same prompt for ChatGPT, Claude, Gemini, and every other AI tool. Each model has different strengths and responds differently to prompting styles.

**The fix:**
- **ChatGPT** responds well when you specify the output format first (table, list, JSON) and add hard limits (word count, number of items).
- **Claude** responds well when you lead with the goal, provide context as bullet points, and ask it to identify assumptions or tradeoffs.
- When something does not work on one model, try rephrasing before switching models.

---

### Mistake 9: Asking the AI to Remember

**The problem:** Expecting the AI to remember details from a previous conversation or from earlier in a very long conversation.

**The fix:** Re-state important context when starting a new conversation. In long conversations, periodically re-state key constraints and requirements.

---

### Mistake 10: Not Specifying the Audience

**The problem:** Asking the AI to "explain machine learning" without saying who the explanation is for. An explanation for a PhD student is very different from one for a 10-year-old.

**The fix:** Always specify your audience. "Explain this to a complete beginner." "Write this for a professional audience." "Assume the reader has no technical background."

---

## 6. Before and After: Prompt Refactoring Step by Step

The best way to learn prompting is to see how a bad prompt gets improved through incremental changes. Here are three real refactoring walkthroughs.

### Refactoring 1: Writing a Blog Post

**Version 1 (the starting point):**
```
Write a blog post about remote work.
```

**Version 2 (add specificity):**
```
Write a blog post about the challenges of remote work for new managers.
```

**Version 3 (add audience and format):**
```
Write a blog post about the challenges of remote work for new managers.
The audience is first-time managers at tech startups. Use short paragraphs
and include subheadings.
```

**Version 4 (add tone, length, and constraints):**
```
Write a blog post about the challenges of remote work for new managers.
The audience is first-time managers at tech startups. Use short paragraphs
and include subheadings. Keep it under 800 words. Use a practical,
no-nonsense tone. Include at least 3 actionable tips they can use this
week. Avoid generic advice like "communicate more."
```

**What changed at each step:**
- V1 to V2: Added a specific angle and audience
- V2 to V3: Added format and reader context
- V3 to V4: Added tone, length limit, actionable requirement, and exclusions

---

### Refactoring 2: Getting a Recipe

**Version 1:**
```
Give me a dinner recipe.
```

**Version 2:**
```
Give me a chicken dinner recipe that takes under 30 minutes.
```

**Version 3:**
```
Give me a chicken dinner recipe that takes under 30 minutes.
I only have chicken breast, rice, onions, garlic, soy sauce,
and olive oil. No oven, only a stovetop.
```

**Version 4:**
```
Give me a chicken dinner recipe that takes under 30 minutes.
I only have chicken breast, rice, onions, garlic, soy sauce,
and olive oil. No oven, only a stovetop. Write it as numbered
steps. Include exact measurements. Serves 2 people.
```

**What changed at each step:**
- V1 to V2: Added protein preference and time constraint
- V2 to V3: Added available ingredients and equipment constraints
- V3 to V4: Added format, precision requirement, and serving size

---

### Refactoring 3: Asking for Career Advice

**Version 1:**
```
How do I get a promotion?
```

**Version 2:**
```
How do I get promoted from junior to senior software developer?
```

**Version 3:**
```
How do I get promoted from junior to senior software developer?
I have been in my current role for 2 years at a mid-size company.
My manager says I need to "show more leadership."
```

**Version 4:**
```
You are a career coach who specializes in tech careers.

I have been a junior software developer for 2 years at a mid-size
company (about 200 employees). My manager told me I need to "show
more leadership" to get promoted to senior developer, but I am not
sure what that means in practice.

Give me 5 specific, concrete actions I can take in the next 3 months
to demonstrate leadership without being in a management role.
For each action, include a real example of what it looks like day-to-day.
```

**What changed at each step:**
- V1 to V2: Added specific role and target
- V2 to V3: Added personal context and the actual feedback received
- V3 to V4: Added a role for the AI, timeline, format (5 actions), and asked for concrete daily examples

---

### The Refactoring Pattern

Every prompt can be improved by asking yourself these questions in order:

1. **What specifically do I want?** (narrow the topic)
2. **What is my situation?** (add personal context)
3. **Who is this for?** (define the audience)
4. **What format do I want?** (list, table, steps, essay)
5. **What constraints matter?** (length, tone, exclusions)
6. **What would make the answer actually useful?** (actionable details, real examples)

You do not need to answer all six every time. But each one you add makes the output significantly better.

---

## 7. When NOT to Prompt Engineer

Sometimes the problem is not your prompt. Sometimes AI is simply the wrong tool for the job.

### Use a Search Engine Instead of AI When...

- You need **current, real-time information** (stock prices, weather, live scores, breaking news). AI models have knowledge cutoffs and can be out of date.
- You need a **specific fact with a source** (exact quote, legal statute, official statistic). AI may hallucinate facts. Search engines link you directly to sources you can verify.
- You need to **find a specific website or document** you already know exists.

### Use a Calculator or Spreadsheet Instead of AI When...

- You need **precise mathematical calculations**. AI does math "in its head" using pattern matching, not actual computation. It can get arithmetic wrong, especially with long sequences or decimals.
- You need to **process large datasets**. A spreadsheet or database is the right tool for sorting, filtering, and calculating thousands of rows of data.
- You need **financial calculations** where accuracy is critical (taxes, interest rates, loan payments).

### Use a Professional Instead of AI When...

- You need **legal advice** for a specific situation. AI can give general legal information, but it cannot replace a lawyer who knows your jurisdiction and circumstances.
- You need **medical diagnosis or treatment decisions**. AI can help you understand medical terms, but it should never replace a doctor.
- You need **licensed professional work** (structural engineering, tax preparation for complex situations, therapy).

### Use a Database or Dedicated Tool Instead of AI When...

- You need to **look up something in a specific system** (your company's inventory, a government registry, a library catalog). AI does not have access to these systems.
- You need **real-time data integration** (CRM data, analytics dashboards, financial systems).
- You need to **perform repetitive, rule-based tasks** with 100% accuracy. A script or automation tool is more reliable.

### The Problem Is the Model, Not Your Prompt, When...

- The AI **keeps hallucinating facts** no matter how you phrase the question. Some questions require access to information the model does not have.
- The AI **cannot follow complex instructions** even after simplification. Some tasks exceed what current models can reliably do.
- You have been **rephrasing the same prompt 10 times** with similar poor results. At that point, the model may simply not be capable of the task you are asking for. Try a different model, a different approach, or a different tool entirely.
- The task requires **true randomness or creativity that must be non-repetitive** across thousands of outputs. AI models have patterns, and those patterns repeat.

### The Decision Checklist

Before spending more time on your prompt, ask yourself:

1. Does this task require real-time or frequently changing data? If yes, use a search engine or live data source.
2. Does this task require 100% mathematical accuracy? If yes, use a calculator or spreadsheet.
3. Does this task have legal, medical, or safety consequences? If yes, consult a professional.
4. Does this task require access to a specific private system? If yes, use that system directly.
5. Have I already tried 5+ different prompt variations with poor results? If yes, the problem may be the model's limitations, not your prompt.

---

## Sources

- [10 ChatGPT Prompt Engineering Tips in 2026 - eWeek](https://www.eweek.com/news/10-good-vs-bad-chatgpt-prompts-2026/)
- [How to Write Good AI Prompts - Stack AI](https://www.stack-ai.com/blog/how-to-write-good-ai-prompts-a-complete-guide-to-getting-better-results)
- [Prompt Engineering Best Practices 2026 - Prompt Builder](https://promptbuilder.cc/blog/prompt-engineering-best-practices-2026)
- [CO-STAR Framework - Portkey](https://portkey.ai/blog/what-is-costar-prompt-engineering/)
- [CO-STAR and Delimiters - Streamline](https://www.streamline.us/blog/co-star-and-delimiters-elevate-your-prompt-engineering-skills/)
- [Mastering Prompt Engineering with Empower - GovTech Singapore](https://www.tech.gov.sg/technews/mastering-the-art-of-prompt-engineering-with-empower/)
- [RISEN Framework - ClickUp](https://clickup.com/general-resources/playbooks/ai-prompts)
- [RISEN Framework Transforms AI Prompt Engineering - EasyAIBeginner](https://easyaibeginner.com/risen-framework-ai-prompt-for-chatgpt/)
- [CREATE Framework - Tom Barrett](https://edte.ch/blog/create-framework/?v=b870c45f9584)
- [CREATE Framework - University of Pittsburgh](https://services.pitt.edu/TDClient/33/Portal/KB/ArticleDet?ID=2930)
- [AI Slop - Wikipedia](https://en.wikipedia.org/wiki/AI_slop)
- [Merriam-Webster Word of the Year 2025: Slop - PBS](https://www.pbs.org/newshour/nation/merriam-websters-word-of-the-year-for-2025-is-ais-slop)
- [AI Word Slop - American Enterprise Institute](https://www.aei.org/op-eds/ai-word-slop/)
- [Common AI Words to Avoid - GPTHuman](https://gpthuman.ai/common-ai-words-to-avoid-if-you-want-to-bypass-ai-detectors/)
- [500 ChatGPT Overused Words - GodOfPrompt](https://www.godofprompt.ai/blog/500-chatgpt-overused-words-heres-how-to-avoid-them)
- [AI Words List: Spot Overused Phrases - HasteWire](https://hastewire.com/blog/ai-words-list-spot-overused-phrases-in-ai-text)
- [How to Clean Up AI-Generated Drafts - Louis Bouchard](https://www.louisbouchard.ai/ai-editing/)
- [Chain-of-Thought Prompting - Prompting Guide](https://www.promptingguide.ai/techniques/cot)
- [Few-Shot Prompting - Prompting Guide](https://www.promptingguide.ai/techniques/fewshot)
- [Prompt Engineering Techniques Top 6 for 2026 - K2View](https://www.k2view.com/blog/prompt-engineering-techniques/)
- [The Ultimate Guide to Prompt Engineering 2026 - Lakera](https://www.lakera.ai/blog/prompt-engineering-guide)
- [Top 10 Prompt Mistakes to Avoid - Nucamp](https://www.nucamp.co/blog/ai-essentials-for-work-2025-top-10-prompt-mistakes-to-avoid-in-2025)
- [14 Prompt Engineering Mistakes - ODSC](https://odsc.medium.com/beyond-prompt-and-pray-14-prompt-engineering-mistakes-youre-probably-still-making-c2c3a32711bc)
- [5 Common Prompt Engineering Mistakes - Great Learning](https://www.mygreatlearning.com/blog/prompt-engineering-beginners-mistakes/)
- [Prompt Engineering in 2025: Latest Best Practices - Aakash Gupta](https://www.news.aakashg.com/p/prompt-engineering)
- [Does Prompt Engineering Still Matter in 2025 - Coalfire](https://coalfire.com/the-coalfire-blog/does-prompt-engineering-still-matter-in-late-2025/)
- [AI Search Engines Fail to Produce Accurate Citations - Nieman Lab](https://www.niemanlab.org/2025/03/ai-search-engines-fail-to-produce-accurate-citations-in-over-60-of-tests-according-to-new-tow-center-study/)
- [Prompt Frameworks 2025 Explained - EncodeDots](https://www.encodedots.com/blog/prompt-frameworks-2025)
- [Mastering AI Prompt Mini-Frameworks - PromptLayer](https://blog.promptlayer.com/mastering-ai-prompt-mini-frameworks/)
