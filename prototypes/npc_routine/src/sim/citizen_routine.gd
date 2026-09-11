extends RefCounted

# One minute of simulation represents a complete day in this fixed demo.
# State is derived from elapsed simulation time, never from rendering frames.
const DAY_SECONDS := 60.0
const HOME := Vector2(-20, 8)
const WORK := Vector2(16, -12)
const SQUARE := Vector2(0, 0)
const PHASES := [
 {"start": 0.0, "end": 10.0, "activity": "resting at home", "from": HOME, "to": HOME},
 {"start": 10.0, "end": 20.0, "activity": "walking to work", "from": HOME, "to": WORK},
 {"start": 20.0, "end": 35.0, "activity": "working", "from": WORK, "to": WORK},
 {"start": 35.0, "end": 40.0, "activity": "walking to square", "from": WORK, "to": SQUARE},
 {"start": 40.0, "end": 50.0, "activity": "visiting square", "from": SQUARE, "to": SQUARE},
 {"start": 50.0, "end": 60.0, "activity": "walking home", "from": SQUARE, "to": HOME}
]
var elapsed_seconds := 0.0

# Invalid deltas are rejected without changing the simulation clock.
func advance(delta_seconds: float) -> bool:
 if not is_finite(delta_seconds) or delta_seconds < 0.0:
  return false
 var next_time := elapsed_seconds + delta_seconds
 if not is_finite(next_time):
  return false
 elapsed_seconds = next_time
 return true

func state() -> Dictionary:
 return state_at(elapsed_seconds)

static func state_at(seconds: float) -> Dictionary:
 # Snap floating-point accumulation noise at exact schedule boundaries.
 var whole_second := roundf(seconds)
 if absf(seconds-whole_second) < 0.000000001:
  seconds = whole_second
 var local_time := fposmod(seconds, DAY_SECONDS)
 var phase: Dictionary = PHASES[0]
 for candidate in PHASES:
  if local_time >= candidate.start and local_time < candidate.end:
   phase = candidate
   break
 var progress: float = (local_time-phase.start)/(phase.end-phase.start)
 var location: Vector2 = phase.from.lerp(phase.to, progress)
 return {"day": int(floor(seconds/DAY_SECONDS)), "time": local_time,
  "activity": phase.activity, "position": location}
