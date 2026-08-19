# Technical writing

Reference for prose a human reads: docs, READMEs, RFCs, specs, PR descriptions, commit bodies, case notes. Adapted from the `technical-writing` skill in [pstack](https://github.com/cursor/plugins/tree/main/pstack) (MIT, Lauren Tan), which layers Diataxis, the Google developer style guide, ASD-STE100, and Global English.

Pointed at by `docs:create` and `docs:update`. The slop-pattern catalog lives in `writing:unslop`; this file owns structure and sentence mechanics.

Target: a tired engineer understands it on the first read.

## Three rules above the layers

- **Cut every word that does no work.** If the sentence survives without a word, the word goes. "In order to" is "to". "It is important to note that" is nothing.
- **Use the short, everyday word.** Use, not utilize. Help, not facilitate. A long word buys its length with precision or it goes.
- **When a rule makes the sentence worse, fix it another way.** The rules serve the reader. A sentence that obeys every rule and reads like a machine wrote it has failed.

The codebase is the word list: write the real symbol, file, flag, sproc, or command name, never a synonym or a description of it. Do not invent jargon; use the words a developer says out loud.

## Layer 1: pick the mode (Diataxis)

One document, one mode. Two questions pick it: does the content serve doing or understanding, and learning or work?

| | Learning | Work |
|---|---|---|
| **Doing** | tutorial | how-to |
| **Understanding** | explanation | reference |

- **Tutorial.** The learner's success is the author's job. Every step produces a visible result, and the doc says what they should see. Explanation is one clause and a link. Write as "we", in commands.
- **How-to.** Solves a problem a person has. Assumes competence, skips teaching, allows forks ("if you want X, do Y"). Name it by the task.
- **Reference.** Describe, only describe. Dry, complete, no hedging. Mirror the structure of the thing described. Generate from code where possible so it stays true.
- **Explanation.** One bounded topic, readable away from the product, anchored on a real why question. Design decisions, history, constraints, alternatives. Opinion is allowed here and nowhere else.

Do not mix modes: no reference table inside a tutorial, no hand-holding inside reference, no arguing inside a how-to. Split and link.

## Layer 2: address the reader (Google developer style)

- Second person, present tense. "Will" only for things that genuinely happen later.
- Name the actor: "the compiler validates", not "is validated". Passive only when the actor is unknown or beside the point.
- Instructions are commands. "Click Submit", never "should be done".
- Condition before instruction: "To delete the document, click Delete." The reader skips what does not apply.
- Common case first, exceptions after.
- No buzzwords, no figurative language, and never "simply", "easy", or "quickly" in a procedure. If it were simple the reader would not be here.
- Headings carry the point, not the topic ("Pick the mode first", not "Modes"). Sentence case. One h1.
- Numbered lists for sequences, bullets for everything else. Introduce a list with a complete sentence, keep items parallel.
- Link text says where the link goes. Never "click here".

## Layer 3: one load per statement (ASD-STE100)

- One instruction per sentence, one thought per sentence everywhere else.
- Split instructions past about 20 words, other sentences past about 25.
- Warning or condition before the step it guards.
- Keep "the" and "a". "Remove backup file" reads two ways; "remove the backup file" reads one.
- One word, one meaning, one job, kept throughout. Pick one verb per action and stay on it: start, not start here and initiate there.
- Procedures are direct commands, never narration and never passive.

## Layer 4: leave no sentence open to two readings (Global English)

- Keep "only" and "not" next to what they change. "Only fails on growth" and "fails only on growth" say different things.
- Break up long noun strings. "The proto import budget check script" becomes "the script that checks the proto-import budget".
- Every "it", "they", and "this" points at one obvious thing. Repeat the noun when in doubt, and never use "this" or "which" to point at a whole clause.
- Do not drop verbs across parallel clauses.
- Say which parts "and" or "or" joins when a sentence can group two ways. Both/and, either/or, and if/then are free disambiguators.
- Text in parentheses is a full grammatical unit or its own sentence. Never "(s)" plurals, never slashes: write "a, b, or both".
- One name per thing, everywhere. A doc that calls one thing the gate, the ratchet, and the budget check teaches three things.
- Skip idioms, Latin abbreviations, and metaphors. A translator, a non-native reader, and an agent all parse plain constructions best.

## House deltas from the source

- The em-dash ban is already absolute in CLAUDE.md, at a higher rung than this file.
- The source also bans semicolons and mid-sentence colons. Not adopted: house punctuation uses both deliberately. Everything else in Layer 4 holds.
- Counts and tree claims must be true at the commit that lands them, and the doc includes the command that regenerates them.

## Review checklist

1. Is each file one mode, with links where modes meet?
2. Is every instruction a command with its condition in front?
3. Does any sentence carry two instructions or two thoughts? Split it.
4. Can any word be cut without losing meaning? Cut it.
5. Is "only" beside the word it changes? Does every "it" point at one thing? Does every clause keep its verb?
6. Does each thing have exactly one name across the document set?
7. Would a developer say these words out loud?
8. Are all symbols, paths, and counts real at this commit?
