-- Testable rules for classic childhood zombie tag.
local TagRules={}
function TagRules.finalists(initialRunners)
 if type(initialRunners)~="number" or initialRunners<1 then return 1 end
 return initialRunners>=5 and 2 or 1
end
function TagRules.captured(started,now,visible,range)
 if not visible or type(started)~="number" or type(now)~="number" then return false end
 if type(range)~="number" or range>5.8 or range<0 then return false end
 return now-started>=3
end
function TagRules.timeLimit(minutes,isStudio)
 assert(minutes==30 or minutes==60,"supported tag duration")
 return isStudio and math.min(minutes*60,180) or minutes*60
end
function TagRules.finalEscapeAllowed(initialRunners,remainingRunners)
 return remainingRunners>0 and remainingRunners<initialRunners and
  remainingRunners<=TagRules.finalists(initialRunners)
end
return TagRules
