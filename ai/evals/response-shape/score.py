#!/usr/bin/env python3
"""Score a Cortex reply against the countable rules in SOUL.md.

Every check is a count, so a failure is a fact rather than an opinion. Checks are
grouped by which SOUL.md block they enforce; `RULES` maps a case's rule tag to the
checks that must pass for that case. A check absent from a case's tag list is
reported but does not fail it, because most rules only apply to a matching prompt.
"""
import re, sys, json, collections

WORD_LIMIT = 200
OPENERS = r"(Great question|Let me\b|I'll\b|Sure[!,]|Looking at|To answer|Happy to|Absolutely|Certainly|Here'?s (the|my|what)|This is a|I've (now )?(done|made|completed))"
CLOSERS = r"(let me know if|hope this helps|happy to (clarify|help)|feel free to ask|anything else|if you (want|need) (me to )?(anything|more))"
HYPE = r"\b(amazing|awesome|fantastic|excellent|incredible|impressive|nailed it|great job|well done|love (it|this)|perfect)\b"
VAGUE_TIME = r"(a bit of work|some work|a while|shouldn'?t take long|not too long|fairly quick|pretty quick|a few things|depends)"
UNIT_TIME = r"\b\d+\s*(min|minute|hour|hr|day|week|month)s?\b|\b(an hour|a day|a week|half a day|an afternoon|a morning)\b"
EMOJI = re.compile("[\U0001F300-\U0001FAFF\U00002600-\U000027BF\U0001F1E6-\U0001F1FF❤️]")

# which checks gate which case tag
RULES = {
    "before-you-send": ["over_limit", "announcing_opener", "closer", "list_over_5", "menu_ending", "no_landing"],
    "land-the-plane":  ["over_limit", "announcing_opener", "closer", "no_recommendation"],
    "time-in-units":   ["over_limit", "announcing_opener", "vague_time_only"],
    "numbered-steps":  ["over_limit", "announcing_opener", "unnumbered_plan", "list_over_5"],
    "no-hype":         ["over_limit", "announcing_opener", "hype"],
    "no-emoji":        ["emoji"],
}

def measure(text):
    body = re.sub(r"```.*?```", "", text, flags=re.S)
    lines = [l for l in body.split("\n") if l.strip()]
    first2 = " ".join(lines[:2]) if lines else ""
    last = lines[-1] if lines else ""
    words = len(body.split())

    longest = run = 0
    for l in body.split("\n"):
        if re.match(r"\s*([-*]|\d+\.)\s", l):
            run += 1; longest = max(longest, run)
        elif l.strip() == "":
            pass
        else:
            run = 0

    paras = [p for p in re.split(r"\n\s*\n", body) if p.strip() and not re.match(r"\s*([-*]|\d+\.|#|\|)", p.strip())]
    longest_para = max((len(p.split()) for p in paras), default=0)

    lands = (bool(re.search(r"^(Next:|Start (with|by)|Run |Open |Do |Fix |Approve|→)", last))
             or last.rstrip().endswith("?")
             or bool(re.search(r"(I'?ll (start|do|fix|run|go)|starting (with|on)|doing (that|this|it) now|approve )", last, re.I)))

    m = {
        "words": words,
        "over_limit": words > WORD_LIMIT,
        "announcing_opener": bool(re.search(OPENERS, first2)),
        "closer": bool(re.search(CLOSERS, body, re.I)),
        "longest_list": longest,
        "list_over_5": longest > 5,
        "longest_para": longest_para,
        "wall_of_prose": longest_para > 120,
        "menu_ending": bool(re.search(r"(want me to|should i|shall i|do you want)\b[^.?!]*\b(or|,)\s", last, re.I)),
        "no_landing": not lands,
        "hype": len(re.findall(HYPE, body, re.I)),
        "emoji": len(EMOJI.findall(body)),
        "numbered": len(re.findall(r"^\s*\d+\.\s", body, flags=re.M)),
        "has_unit_time": bool(re.search(UNIT_TIME, body, re.I)),
        "vague_time": len(re.findall(VAGUE_TIME, body, re.I)),
    }
    # a plan answer should be numbered steps, not prose
    m["unnumbered_plan"] = m["numbered"] < 2
    # a duration answer must contain at least one concrete unit
    m["vague_time_only"] = not m["has_unit_time"]
    # a comparison answer must name one pick, not branch
    m["no_recommendation"] = not bool(re.search(
        r"(I'?d (use|do|go with|pick|choose)|use \w+\.|go with|my pick|recommendation:|pick \w+)", body, re.I))
    return m

def grade(text, tag):
    m = measure(text)
    gates = RULES.get(tag, RULES["before-you-send"])
    fails = [g for g in gates if (m[g] if isinstance(m[g], bool) else m[g] > 0)]
    return m, fails

if __name__ == "__main__":
    # args: file:tag pairs, or a directory scan handled by run.sh
    rows = []
    for arg in sys.argv[1:]:
        path, _, tag = arg.partition("::")
        try:
            t = open(path).read()
        except OSError:
            continue
        m, fails = grade(t, tag or "before-you-send")
        rows.append((path, tag, m, fails))

    agg = collections.defaultdict(lambda: [0, 0])   # case -> [passes, total]
    for path, tag, m, fails in rows:
        # filenames are "<rep>-<case>.txt"
        case = path.split("/")[-1].rsplit(".", 1)[0].split("-", 1)[-1]
        key = (case, tag)
        agg[key][1] += 1
        if not fails:
            agg[key][0] += 1
        print(f"{path.split('/')[-1]:28} {'PASS' if not fails else 'FAIL':4} "
              f"w={m['words']:4} list={m['longest_list']} para={m['longest_para']:3} "
              f":: {','.join(fails) or '-'}")

    if agg:
        print("\n--- compliance rate by case ---")
        tp = tt = 0
        for (case, tag), (p, t) in sorted(agg.items()):
            tp += p; tt += t
            bar = "#" * p + "." * (t - p)
            print(f"  {case:12} {tag:16} {p}/{t}  {bar}")
        print(f"\n  overall: {tp}/{tt} ({tp/tt*100:.0f}%)")
