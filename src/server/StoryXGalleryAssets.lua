-- Reviewed Roblox image asset registry for the Story X exhibition.
-- Art from a personal Library or GitHub is NOT an in-game asset until
-- uploaded to Roblox and the resulting permitted asset ID is recorded here.
-- Leave all ids at 0 while developing the playable procedural pixel gallery.
local Assets={}
Assets.images={
    observer={id=0,approved=false,license="ORIGINAL_PENDING_UPLOAD",artist="Югатн"},
    mira={id=0,approved=false,license="ORIGINAL_PENDING_UPLOAD",artist="Югатн"},
    symbiont={id=0,approved=false,license="ORIGINAL_PENDING_UPLOAD",artist="Югатн"},
    future={id=0,approved=false,license="ORIGINAL_PENDING_UPLOAD",artist="Югатн"},
    ambivalence={id=0,approved=false,license="ORIGINAL_PENDING_UPLOAD",artist="Югатн"},
    catharsis={id=0,approved=false,license="ORIGINAL_PENDING_UPLOAD",artist="Югатн"},
    spiral={id=0,approved=false,license="ORIGINAL_PENDING_UPLOAD",artist="Югатн"},
    synthesis={id=0,approved=false,license="ORIGINAL_PENDING_UPLOAD",artist="Югатн"},
}
function Assets.get(name)
    if type(name)~="string" then return nil end
    local asset=Assets.images[name]
    if not asset or asset.approved~=true
        or (asset.license~="ORIGINAL" and asset.license~="LICENSED" and asset.license~="CC0")
        or type(asset.id)~="number" or asset.id%1~=0 or asset.id<=0 then
        return nil
    end
    return asset.id
end
return Assets
