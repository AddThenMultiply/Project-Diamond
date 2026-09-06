import re, pathlib, subprocess
ROOT = pathlib.Path(__file__).resolve().parent.parent
BOOK = "https://api.leadconnectorhq.com/widget/booking/Av6i7gL0YzbszYFfnKqQ"
changed = subprocess.run(["git","diff","--name-only","main"],cwd=ROOT,capture_output=True,text=True).stdout.split()
changed += [p for p in ["pitch.html","commercial-acceleration.html"] if p not in changed]
ok = True
for f in changed:
    if not f.endswith(".html"): continue
    s = (ROOT/f).read_text(encoding="utf-8")
    markup = re.sub(r"<script>.*?</script>", "", s, flags=re.S)
    jslinks = re.findall(r'"([a-z0-9-]+\.html)"', s)
    for h in re.findall(r'href="([^"]+)"', markup) + jslinks:
        if h.startswith("#") or h.startswith("mailto:") or h == BOOK: continue
        if h.startswith("http"):
            print(f"{f}: external href {h}"); ok = False; continue
        target = h.split("#")[0]
        if not (ROOT/target).exists():
            print(f"{f}: BROKEN {h}"); ok = False
    n = len(re.findall(r"const BOOKING_URL\s*=", s))
    vals = set(re.findall(r'const BOOKING_URL\s*=\s*"([^"]+)"', s))
    if n != 1 or vals != {BOOK}:
        print(f"{f}: BOOKING_URL defs={n} vals={vals}"); ok = False
    for w in re.findall(r"\b\w*(?:ize|ized|izing|ization|izes)\b|\b(?:color|favor|center|program|organization|behavior|analyze|license)\b", s):
        pass
    # UK spelling scan on visible text only (strip tags/CSS/JS)
    body = re.sub(r"<style>.*?</style>|<script>.*?</script>", "", s, flags=re.S)
    text = re.sub(r"<[^>]+>", " ", body)
    bad = re.findall(r"\b(?:\w+iz(?:e|ed|es|ing|ation)|colou?r\b(?<!colour)|favor\w*|center\w*|program\b|programs\b|organization\w*|behavior\w*|analyz\w+|licens\w*|\w+eling|\w+eled|\w+elor)\b", text)
    bad = [b for b in bad if b.lower() not in ("size","sized","sizes","prize","seize","seized")]
    if bad: print(f"{f}: US spelling? {sorted(set(bad))}")
    if "localStorage" in body or "sessionStorage" in body: print(f"{f}: storage mention outside script")
print("changed:", changed)
print("OK" if ok else "PROBLEMS")
