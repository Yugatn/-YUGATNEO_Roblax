-- STORY X DefenseTactics: pure, testable rules for cooperative crafting and team plans.
local T = {}
T.recipes = {
  Build = {cost = 9, maxLevel = 2},
  Repair = {cost = 4, maxLevel = 2},
  Upgrade = {cost = 15, maxLevel = 2},
}
T.plans = {Balanced=true, Fortify=true, Scout=true, Resupply=true}
T.maxSalvage = 250

function T.cost(action, role)
  local recipe = T.recipes[action]
  if not recipe then return nil end
  return math.max(1, recipe.cost - (role == "Engineer" and 2 or 0))
end

function T.apply(action, role, site, salvage)
  local price = T.cost(action,role)
  if not price or type(site) ~= "table" or type(salvage) ~= "number" then
    return false, salvage, "invalid"
  end
  if price > salvage then return false,salvage,"insufficient" end
  if action=="Build" then
    if site.level > 0 then return false,salvage,"already built" end
    site.level=1
    site.maxHealth=75
    site.health=75
  elseif action=="Upgrade" then
    if site.level ~= 1 then return false,salvage,"needs level one" end
    site.level=2
    site.maxHealth=130
    site.health=math.min(130,site.health+75)
  elseif action=="Repair" then
    if site.level == 0 or site.health >= site.maxHealth then
      return false,salvage,"nothing to repair"
    end
    site.health=math.min(site.maxHealth,site.health+(role=="Engineer" and 45 or 23))
  end
  return true,salvage-price,"ok"
end

function T.awardSalvage(salvage,source)
  local amount = source=="bot" and 3 or (source=="wave" and 8 or 0)
  return math.min(T.maxSalvage,math.max(0,salvage)+amount)
end

function T.vote(votes,uid,plan)
  if not T.plans[plan] or type(uid)~="number" then return false end
  votes[uid]=plan
  return true
end

function T.teamPlan(votes,teamIds)
  local totals = {Fortify=0,Scout=0,Resupply=0}
  for _,uid in ipairs(teamIds) do
    local choice = votes[uid]
    if totals[choice] then totals[choice]+=1 end
  end
  local best,winner=0,"Balanced"
  for _,plan in ipairs({"Fortify","Scout","Resupply"}) do
    if totals[plan]>best then best=totals[plan]; winner=plan
    elseif totals[plan]==best and best>0 then winner="Balanced" end
  end
  return winner,totals
end

-- A barricade intercepts a bot if it lies close to the ray between the bot and core.
function T.intercept(botPos,corePos,sites)
  local toCore=corePos-botPos
  local length=toCore.Magnitude
  if length<1 then return nil end
  local normal=toCore.Unit
  local nearest,best=nil,math.huge
  for index,site in ipairs(sites) do
    if site.health>0 and site.level>0 then
      local delta=site.position-botPos
      local progress=delta:Dot(normal)
      local lateral=(delta-normal*progress).Magnitude
      if progress>0 and progress<length and lateral<10 and progress<best then
        nearest=index
        best=progress
      end
    end
  end
  return nearest
end

function T.objective(core,sites,members,salvage)
  if core<80 then return "Protect the base: engineer repairs the core" end
  local built=0
  for _,site in ipairs(sites) do
    if site.level>0 and site.health>0 then built+=1 end
  end
  if built<2 and salvage>=7 then
    return "Use team salvage to construct protective barricades"
  end
  for _,member in ipairs(members) do
    if member.ammo<12 then return "Support teammates: replenish energy charges" end
  end
  return "Coordinate lanes: defender covers, engineer repairs, support resupplies"
end

function T.coreAttackDamage(baseDamage,plan)
  if plan=="Fortify" then return math.max(1,baseDamage-2) end
  return baseDamage
end
function T.hitDamage(baseDamage,plan)
  return baseDamage+(plan=="Scout" and 4 or 0)
end
function T.supplyBonus(plan)
  return plan=="Resupply" and 8 or 0
end
return T
