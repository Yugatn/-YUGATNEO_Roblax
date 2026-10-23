local Rules = {}
Rules.presets = {
  Robots10 = {kind="Robots", rounds=10, limit=10},
  Robots20 = {kind="Robots", rounds=20, limit=13},
  Shadows10 = {kind="Shadows", rounds=10, limit=11},
  Shadows20 = {kind="Shadows", rounds=20, limit=14},
}
Rules.roles = {Defender=true,Engineer=true,Support=true}
function Rules.config(mode, people)
  local preset=Rules.presets[mode]
  if not preset or people<1 or people>3 then return nil end
  return {name=mode,kind=preset.kind,rounds=preset.rounds,
    limit=preset.limit,people=people,integrity=150}
end
function Rules.count(cfg,round)
  return math.min(cfg.limit,2+math.floor(round*0.7)+cfg.people)
end
function Rules.resistance(cfg,round)
  return (cfg.kind=="Robots" and 40 or 30)+5*round
end
function Rules.restore(role,value)
  return math.min(150,value+(role=="Engineer" and 20 or 7))
end
function Rules.replenish(role,ammo)
  return math.min(120,ammo+(role=="Support" and 34 or 16))
end
return Rules
