from pathlib import Path

lcov = Path("coverage/lcov.info").read_text(encoding="utf-8", errors="ignore")
files = {}
current = None
for line in lcov.splitlines():
    if line.startswith("SF:"):
        current = line[3:].replace("\\", "/")
        files[current] = {"hit": 0, "found": 0}
    elif current and line.startswith("DA:"):
        _, rest = line.split(":", 1)
        _, count = rest.split(",")
        files[current]["found"] += 1
        if int(count) > 0:
            files[current]["hit"] += 1
    elif line == "end_of_record":
        current = None

logic_utils = {
    "goal_points.dart",
    "streak_logic.dart",
    "goal_achievement_eval.dart",
    "achievement_tracking_codec.dart",
    "sound_volume.dart",
    "common_utils.dart",
    "text_utils.dart",
}

groups = {
    "progressive_visuals": (0, 0),
    "utils_logic": (0, 0),
    "models": (0, 0),
    "notifier": (0, 0),
    "achievement_service": (0, 0),
}

for path, data in files.items():
    p = path.replace("\\", "/")
    found, hit = data["found"], data["hit"]
    if "lib/progressive_visuals/" in p:
        h, f = groups["progressive_visuals"]
        groups["progressive_visuals"] = (h + hit, f + found)
    if "lib/models/classes/" in p:
        h, f = groups["models"]
        groups["models"] = (h + hit, f + found)
    if p.endswith("lib/utils/notifier.dart"):
        h, f = groups["notifier"]
        groups["notifier"] = (h + hit, f + found)
    if p.endswith("lib/services/achievement_service.dart"):
        h, f = groups["achievement_service"]
        groups["achievement_service"] = (h + hit, f + found)
    for name in logic_utils:
        if p.endswith(f"lib/utils/{name}"):
            h, f = groups["utils_logic"]
            groups["utils_logic"] = (h + hit, f + found)

for name, (hit, found) in groups.items():
    pct = (hit / found * 100) if found else 0
    print(f"{name}: {hit}/{found} = {pct:.1f}%")

all_hit = sum(v[0] for v in groups.values())
all_found = sum(v[1] for v in groups.values())
if all_found:
    print(f"combined_logic: {all_hit}/{all_found} = {all_hit / all_found * 100:.1f}%")

print("\nPer-file (logic):")
for path, data in sorted(files.items()):
    p = path.replace("\\", "/")
    is_logic = (
        "lib/progressive_visuals/" in p
        or "lib/models/classes/" in p
        or p.endswith("lib/utils/notifier.dart")
        or p.endswith("lib/services/achievement_service.dart")
        or p.split("/")[-1] in logic_utils
    )
    if not is_logic or not data["found"]:
        continue
    pct = data["hit"] / data["found"] * 100
    print(f"  {pct:5.1f}%  {p.split('lib/')[-1]}  ({data['hit']}/{data['found']})")
