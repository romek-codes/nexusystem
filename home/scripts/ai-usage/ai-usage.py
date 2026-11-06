"""At-a-glance Claude (cswap) + Codex (codex-limits) usage and pace."""
import json
import subprocess
import sys
from datetime import datetime, timedelta, timezone

WEEK_HOURS = 7 * 24
AHEAD_OF_PACE_MARGIN_PCT = 10
WORK_START, WORK_END = 8, 18  # only Mon-Fri within these hours count as time passing
MIN_ELAPSED_WORK_HOURS = 8


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


def work_seconds(start, end):
    """Seconds between start and end inside working hours (Mon-Fri, WORK_START-WORK_END, local)."""
    start, end = start.astimezone(), end.astimezone()
    total = 0.0
    day = start.replace(hour=0, minute=0, second=0, microsecond=0)
    while day < end:
        if day.weekday() < 5:
            lo = max(start, day.replace(hour=WORK_START))
            hi = min(end, day.replace(hour=WORK_END))
            total += max(0.0, (hi - lo).total_seconds())
        day += timedelta(days=1)
        day = day.replace(hour=0)
    return total


def pace(used_pct, resets_at, window_hours):
    """Derive pace ourselves (only Mon-Fri WORK_START-WORK_END counts as time passing): compare
    used% against the % of working time already elapsed in the window, then
    extrapolate the current rate to reset. The observed rate is shrunk toward an even
    pace with the weight of MIN_ELAPSED_WORK_HOURS, so a few early hours can't swing the
    projection wildly. Below that much working time the result is also marked
    provisional and never triggers the throttle."""
    reset = parse_iso(resets_at)
    if reset is None or used_pct is None:
        return None
    now = datetime.now(timezone.utc)
    start = reset - timedelta(hours=window_hours)
    total = work_seconds(start, reset)
    elapsed = work_seconds(start, min(now, reset))
    if total <= 0 or elapsed <= 0:
        return None
    expected_pct = elapsed / total * 100
    prior = MIN_ELAPSED_WORK_HOURS * 3600
    rate = (used_pct + 100 / total * prior) / (elapsed + prior)  # % per working second
    projected_pct = used_pct + rate * (total - elapsed)
    return {
        "expectedUsedPct": round(expected_pct, 1),
        "aheadOfPace": (used_pct - expected_pct) > AHEAD_OF_PACE_MARGIN_PCT,
        "projectedPctAtReset": round(projected_pct, 1),
        "willLastToReset": projected_pct <= 100,
        "elapsedWorkHours": round(elapsed / 3600, 1),
        "provisional": elapsed < MIN_ELAPSED_WORK_HOURS * 3600,
    }


# Verdict meanings:
#   comfortable      -- using less than (or close to) an even share of the window so far;
#                        you have slack before reset.
#   burning fast     -- using noticeably more than an even share, but at this rate you'd
#                        still land under 100% by reset. A heads-up, not an emergency.
#   WILL RUN OUT EARLY -- at this rate, usage is projected to pass 100% before reset,
#                        i.e. you'd be stuck with 0% for however long is left afterward.
def describe_pace(entry):
    verdict = _verdict(entry)
    if verdict and entry.get("provisional"):
        verdict += f" [provisional, only {entry['elapsedWorkHours']:.0f}h work time elapsed]"
    return verdict


def _verdict(entry):
    will_last = entry.get("willLastToReset")
    if will_last is None:
        return "pace n/a"
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
            # cswap's own pace fields count weekends and are often missing; derive locally.
            **(pace(week.get("pct"), week.get("resetsAt"), WEEK_HOURS) or {}),
            # per-model weekly limits (e.g. Fable) can run dry before the overall one
            "scoped": [
                {"name": sc.get("name"), "weeklyUsedPct": sc.get("pct"), "weeklyResetsIn": sc.get("countdown"),
                 **(pace(sc.get("pct"), sc.get("resetsAt"), WEEK_HOURS) or {})}
                for sc in usage.get("scoped") or []
            ],
        }
        accounts.append(entry)
        if entry["active"]:
            for sc in entry["scoped"]:
                if sc.get("willLastToReset") is False and not sc.get("provisional"):
                    throttle_reasons.append(f"claude:{entry['label']} {sc['name']} weekly window won't last to reset")
        if entry["active"] and entry.get("willLastToReset") is False and not entry.get("provisional"):
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
    if codex_entry.get("willLastToReset") is False and not codex_entry.get("provisional"):
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
        for sc in a["scoped"]:
            sc_verdict = describe_pace(sc)
            print(
                f"      7d {sc['name']}: {sc['weeklyUsedPct']}% used{expected_suffix(sc)}"
                f"{f' -- {sc_verdict}' if sc_verdict else ''}"
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
