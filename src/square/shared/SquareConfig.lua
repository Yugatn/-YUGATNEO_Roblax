--!strict
-- Four-square football: an original asphalt mini-game, played by four people.
local Config = {
    half = 40,
    centerHalf = 4,
    ballRadius = 1.4,
    hitRadius = 12,
    flightDuration = 1.15,
    bounceDuration = 1.05,
    headHeight = 3.3,
    maxConceded = 5,
    cooldown = 0.16,
    squareCenters = {
        Vector3.new(-20, 0, -20),
        Vector3.new(20, 0, -20),
        Vector3.new(-20, 0, 20),
        Vector3.new(20, 0, 20),
    },
    colors = {
        Color3.fromRGB(53, 132, 211),
        Color3.fromRGB(209, 158, 51),
        Color3.fromRGB(95, 181, 120),
        Color3.fromRGB(179, 114, 203),
    },
}
function Config.diagonal(seat)
    return ({[1]=4, [2]=3, [3]=2, [4]=1})[seat]
end
-- -1 = red central penalty square; 0 = outside court; 1–4 = four quadrants.
function Config.zone(x, z)
    if math.abs(x) > Config.half or math.abs(z) > Config.half then return 0 end
    if math.abs(x) <= Config.centerHalf and math.abs(z) <= Config.centerHalf then return -1 end
    if x < 0 then
        return if z < 0 then 1 else 3
    end
    return if z < 0 then 2 else 4
end
return Config
