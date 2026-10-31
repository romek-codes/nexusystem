"""At-a-glance Claude (cswap) + Codex (codex-limits) usage and pace."""
import json
import subprocess
import sys
from datetime import datetime, timezone

WEEK_HOURS = 7 * 24
AHEAD_OF_PACE_MARGIN_PCT = 10


def run_json(cmd):
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
        return json.loads(out.stdout) if out.returncode == 0 and out.stdout.strip() else {}
    except Exception:
        return {}


def parse_iso(s):
    if not s:
        return None
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00"))
    except ValueError:
        return None


def fmt_countdown(resets_at):
    reset = parse_iso(resets_at)
    if reset is None:
        return "?"
    secs = max(0, int((reset - datetime.now(timezone.utc)).total_seconds()))
    d, rem = divmod(secs, 86400)
    h, rem = divmod(rem, 3600)
    m, _ = divmod(rem, 60)
    return (f"{d}d {h}h" if d else f"{h}h {m}m")


def pace(used_pct, resets_at, window_hours):
    """codex-limits doesn't compute pace itself (cswap does) -- derive it the same way:
    compare used% against the % of the window that has already elapsed, then
    extrapolate the current rate forward to reset."""
    reset = parse_iso(resets_at)
    if reset is None or used_pct is None:
        return None
    seconds_left = (reset - datetime.now(timezone.utc)).total_seconds()
    window_seconds = window_hours * 3600
    elapsed = window_seconds - seconds_left
    if elapsed <= 0:
        return None
    expected_pct = elapsed / window_seconds * 100
    projected_pct = used_pct / elapsed * window_seconds
    return {
        "expectedUsedPct": round(expected_pct, 1),
        "aheadOfPace": (used_pct - expected_pct) > AHEAD_OF_PACE_MARGIN_PCT,
        "projectedPctAtReset": round(projected_pct, 1),
        "willLastToReset": projected_pct <= 100,
    }


# Verdict meanings:
#   comfortable      -- using less than (or close to) an even share of the window so far;
#                        you have slack before reset.
#   burning fast     -- using noticeably more than an even share, but at this rate you'd
#                        still land under 100% by reset. A heads-up, not an emergency.
#   WILL RUN OUT EARLY -- at this rate, usage is projected to pass 100% before reset,
#                        i.e. you'd be stuck with 0% for however long is left afterward.
def describe_pace(entry):
    will_last = entry.get("willLastToReset")
    if will_last is None:
        return None
    if will_last is False:
        detail = ""
        projected = entry.get("projectedPctAtReset")
        if projected is not None:
            detail = f", projected ~{projected:.0f}% by reset"
        return f"WILL RUN OUT EARLY{detail}"
    if entry.get("aheadOfPace"):
        return "burning fast"
    return "comfortable"


def expected_suffix(entry):
    expected = entry.get("expectedUsedPct")
    if expected is None:
        return ""
    return f" (expected ~{expected:.0f}% by now)"


def build():
    claude = run_json(["cswap", "list", "--json"])
    codex = run_json(["codex-limits", "--json"])

    accounts = []
    throttle_reasons = []

    for acc in claude.get("accounts", []):
        usage = acc.get("usage") or acc.get("lastGoodUsage") or {}
        five = usage.get("fiveHour", {}) or {}
        week = usage.get("sevenDay", {}) or {}
        entry = {
            "label": acc.get("email") or f"#{acc.get('number')}",
            "active": bool(acc.get("active")),
            "status": acc.get("usageStatus", "unknown"),
            "fiveHourUsedPct": five.get("pct"),
            "fiveHourResetsIn": five.get("countdown"),
            "weeklyUsedPct": week.get("pct"),
            "weeklyResetsIn": week.get("countdown"),
            "expectedUsedPct": week.get("expectedPct"),
            "aheadOfPace": week.get("aheadOfPace"),
            "willLastToReset": week.get("willLastToReset"),
            "projectedExhaustionAt": week.get("projectedExhaustionAt"),
        }
        accounts.append(entry)
        if entry["active"] and entry["willLastToReset"] is False:
            throttle_reasons.append(f"claude:{entry['label']} weekly window won't last to reset")

    windows = codex.get("windows", {})
    codex_five = windows.get("fiveHour", {}) or {}
    codex_week = windows.get("weekly", {}) or {}
    codex_week_pace = pace(codex_week.get("usedPercent"), codex_week.get("resetsAt"), WEEK_HOURS) or {}
    codex_entry = {
        "fiveHourUsedPct": codex_five.get("usedPercent"),
        "fiveHourResetsIn": codex_five.get("resetsIn"),
        "weeklyUsedPct": codex_week.get("usedPercent"),
        "weeklyResetsIn": codex_week.get("resetsIn"),
        "coupons": (codex.get("coupons") or {}).get("available"),
        **codex_week_pace,
    }
    if codex_entry.get("willLastToReset") is False:
        throttle_reasons.append("codex weekly window won't last to reset")

    return {
        "claude": accounts,
        "codex": codex_entry,
        "throttle": bool(throttle_reasons),
        "throttleReasons": throttle_reasons,
    }


def print_human(result):
    print("Claude accounts (% of each window used):")
    for a in result["claude"]:
        marker = "*" if a["active"] else " "
        if a["status"] != "ok":
            print(f"  {marker} {a['label']}: usage unavailable ({a['status']})")
            continue
        verdict = describe_pace(a)
        verdict_suffix = f" -- {verdict}" if verdict else ""
        print(f"  {marker} {a['label']}")
        print(f"      5h: {a['fiveHourUsedPct']}% used, resets in {a['fiveHourResetsIn']}")
        print(
            f"      7d: {a['weeklyUsedPct']}% used{expected_suffix(a)}, "
            f"resets in {a['weeklyResetsIn']}{verdict_suffix}"
        )

    print("\nCodex:")
    c = result["codex"]
    if c.get("fiveHourUsedPct") is None:
        print("  usage unavailable (not logged in?)")
    else:
        verdict = describe_pace(c)
        verdict_suffix = f" -- {verdict}" if verdict else ""
        print(f"  5h: {c['fiveHourUsedPct']}% used, resets in {c['fiveHourResetsIn']}")
        print(
            f"  7d: {c['weeklyUsedPct']}% used{expected_suffix(c)}, "
            f"resets in {c['weeklyResetsIn']}{verdict_suffix}"
        )
        if c.get("coupons") is not None:
            print(f"  reset coupons available: {c['coupons']}")

    if result["throttle"]:
        print("\n\033[31m⚠ THROTTLE:\033[0m " + "; ".join(result["throttleReasons"]))
        print("  Ask before dispatching expensive multi-agent work (Workflow runs, many parallel subagents).")


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    result = build()

    if mode == "--json":
        print(json.dumps(result, indent=2))
        return
    if mode == "--check":
        sys.exit(2 if result["throttle"] else 0)

    print_human(result)


if __name__ == "__main__":
    main()
