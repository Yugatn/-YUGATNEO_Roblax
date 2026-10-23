-- STORY X pathfinding adaptor. Bounded asynchronous computations; safe direct fallback.
-- Works with procedural anchored hologram bots; not tied to Humanoid MoveTo.
local PathfindingService=game:GetService("PathfindingService")
local Navigation={}
local computing=0
local MAX_CONCURRENT=2
function Navigation.direction(bot,target,now)
  now=now or os.clock()
  if not bot or typeof(target)~="Vector3" then return target end
  bot.route=bot.route or {}
  local stale=not bot.routeDestination or (bot.routeDestination-target).Magnitude>9
  if stale then
    bot.route={}
    bot.routeIndex=1
    bot.routeDestination=target
    bot.replanAt=0
  end
  if not bot.calculating and now >= (bot.replanAt or 0)
      and computing<MAX_CONCURRENT and bot.model and bot.model.Parent then
    bot.calculating=true
    bot.replanAt=now+4.5
    computing+=1
    local start=bot.position
    local endPos=target
    task.spawn(function()
      local path=PathfindingService:CreatePath({
        AgentRadius=2,AgentHeight=6,AgentCanJump=false,WaypointSpacing=6,
      })
      local ok=pcall(function() path:ComputeAsync(start,endPos) end)
      if ok and path.Status==Enum.PathStatus.Success and bot.model and bot.model.Parent
          and bot.routeDestination and (bot.routeDestination-endPos).Magnitude<1 then
        local points={}
        for _,wp in ipairs(path:GetWaypoints()) do
          table.insert(points,wp.Position)
        end
        bot.route=points
        bot.routeIndex=math.min(2,#points)
      end
      bot.calculating=false
      computing=math.max(0,computing-1)
      path:Destroy()
    end)
  end
  local waypoint=bot.route and bot.route[bot.routeIndex or 1]
  if waypoint then
    local delta=Vector3.new(waypoint.X-bot.position.X,0,waypoint.Z-bot.position.Z)
    if delta.Magnitude<3.5 then
      bot.routeIndex=(bot.routeIndex or 1)+1
      waypoint=bot.route[bot.routeIndex]
    end
  end
  return waypoint or target
end
return Navigation
