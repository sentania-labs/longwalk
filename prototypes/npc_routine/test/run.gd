extends SceneTree
const Routine = preload("res://src/sim/citizen_routine.gd")
var failures := 0
func check(condition: bool, message: String) -> void:
 if not condition:
  failures += 1
  printerr("FAIL: ",message)
func _initialize() -> void:
 var npc = Routine.new()
 var expected := [
  [0.0, "resting at home", Routine.HOME],
  [10.0, "walking to work", Routine.HOME],
  [15.0, "walking to work", (Routine.HOME+Routine.WORK)*0.5],
  [20.0, "working", Routine.WORK],
  [35.0, "walking to square", Routine.WORK],
  [40.0, "visiting square", Routine.SQUARE],
  [50.0, "walking home", Routine.SQUARE],
  [55.0, "walking home", Routine.HOME*0.5],
  [60.0, "resting at home", Routine.HOME]
 ]
 for example in expected:
  var result = Routine.state_at(example[0])
  check(result.activity == example[1],"Activity at %s seconds" % example[0])
  check(result.position.is_equal_approx(example[2]),"Position at %s seconds" % example[0])
  print("t=%5.1f  %-20s  %s" % [example[0],result.activity,result.position])
 # Equal elapsed time must not depend on caller cadence, including multiple days.
 var fine = Routine.new()
 var coarse = Routine.new()
 var irregular = Routine.new()
 for i in range(1380):
  fine.advance(0.125)
 coarse.advance(172.5)
 for step in [3.5,0.125,44.0,0.375,61.0,13.5,50.0]:
  irregular.advance(step)
 for result in [fine.state(),irregular.state()]:
  check(result == coarse.state(),"Exact state equality across tick partitions")
 check(coarse.state().day == 2,"Multiple-day jump advances day counter")
 check(coarse.state().activity == "walking home","Large tick crosses all intervening phases")
 check(npc.advance(0.0),"Zero delta is valid")
 check(not npc.advance(-1.0),"Negative delta rejected")
 check(not npc.advance(INF),"Infinite delta rejected")
 check(not npc.advance(NAN),"NaN delta rejected")
 check(npc.elapsed_seconds == 0.0,"Rejected input leaves clock unchanged")
 # Decimal deltas are compared with tolerance, since binary float cannot represent 0.1.
 var decimal = Routine.new()
 for i in range(157): decimal.advance(0.1)
 var reference = Routine.state_at(15.7)
 check(decimal.state().activity == reference.activity,"Decimal partition retains phase")
 check(decimal.state().position.distance_to(reference.position)<0.00001,"Decimal partition retains position")
 var boundary_decimal = Routine.new()
 for i in range(600): boundary_decimal.advance(0.1)
 check(boundary_decimal.state() == Routine.state_at(60.0),"Decimal ticks agree exactly at day boundary")
 if failures == 0:
  print("NPC ROUTINE CHECKS PASSED: schedule boundaries, motion, day wrap, tick partition invariance, invalid input")
 quit(0 if failures == 0 else 1)
