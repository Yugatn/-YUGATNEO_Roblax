-- ChessRules: pure server-side rules over an 8x8 board.
-- Board representation: board["row,col"] = {kind="Pawn|...", side="White|Black"}.
-- MVP v0.2: piece moves, captures, king safety, check/mate/stalemate,
-- automatic queen promotion. Castling and en passant are NOT implemented.
-- No Roblox services, Instances or client trust required.
local ChessRules = {}

local function inside(row, col)
    return type(row) == "number" and type(col) == "number"
        and row % 1 == 0 and col % 1 == 0
        and row >= 1 and row <= 8 and col >= 1 and col <= 8
end

local function key(row, col)
    return tostring(row) .. "," .. tostring(col)
end

local function at(board, row, col)
    if not inside(row, col) then return nil end
    return board[key(row, col)]
end

local function other(side)
    return side == "White" and "Black" or "White"
end

local function clearPath(board, fromRow, fromCol, toRow, toCol)
    local dr = toRow > fromRow and 1 or (toRow < fromRow and -1 or 0)
    local dc = toCol > fromCol and 1 or (toCol < fromCol and -1 or 0)
    local row, col = fromRow + dr, fromCol + dc
    while row ~= toRow or col ~= toCol do
        if at(board, row, col) then return false end
        row += dr
        col += dc
    end
    return true
end

local function attack(board, fromRow, fromCol, toRow, toCol)
    local piece = at(board, fromRow, fromCol)
    if not piece or not inside(toRow, toCol) then return false end
    local dr, dc = toRow - fromRow, toCol - fromCol
    if dr == 0 and dc == 0 then return false end
    local adr, adc = math.abs(dr), math.abs(dc)
    if piece.kind == "Pawn" then
        return dr == (piece.side == "White" and 1 or -1) and adc == 1
    elseif piece.kind == "Knight" then
        return (adr == 1 and adc == 2) or (adr == 2 and adc == 1)
    elseif piece.kind == "King" then
        return math.max(adr, adc) == 1
    elseif piece.kind == "Bishop" then
        return adr == adc and clearPath(board, fromRow, fromCol, toRow, toCol)
    elseif piece.kind == "Rook" then
        return (dr == 0 or dc == 0) and clearPath(board, fromRow, fromCol, toRow, toCol)
    elseif piece.kind == "Queen" then
        return (dr == 0 or dc == 0 or adr == adc)
            and clearPath(board, fromRow, fromCol, toRow, toCol)
    end
    return false
end

function ChessRules.isAttacked(board, row, col, attackerSide)
    if not inside(row, col) then return false end
    for fromRow = 1, 8 do
        for fromCol = 1, 8 do
            local piece = at(board, fromRow, fromCol)
            if piece and piece.side == attackerSide and attack(board, fromRow, fromCol, row, col) then
                return true
            end
        end
    end
    return false
end

local function findKing(board, side)
    for row = 1, 8 do
        for col = 1, 8 do
            local piece = at(board, row, col)
            if piece and piece.side == side and piece.kind == "King" then
                return row, col
            end
        end
    end
    return nil, nil
end

function ChessRules.inCheck(board, side)
    local kingRow, kingCol = findKing(board, side)
    if not kingRow then return true end -- invalid board fails closed
    return ChessRules.isAttacked(board, kingRow, kingCol, other(side))
end

local function pseudoLegal(board, fromRow, fromCol, toRow, toCol)
    local piece = at(board, fromRow, fromCol)
    if not piece or not inside(toRow, toCol) then return false end
    local target = at(board, toRow, toCol)
    if target and (target.side == piece.side or target.kind == "King") then return false end
    local dr, dc = toRow - fromRow, toCol - fromCol
    if dr == 0 and dc == 0 then return false end
    if piece.kind == "Pawn" then
        local direction = piece.side == "White" and 1 or -1
        local startRow = piece.side == "White" and 2 or 7
        if dc == 0 then
            if target then return false end
            if dr == direction then return true end
            return fromRow == startRow and dr == 2 * direction
                and not at(board, fromRow + direction, fromCol)
        end
        return math.abs(dc) == 1 and dr == direction
            and target ~= nil and target.side ~= piece.side
    end
    return attack(board, fromRow, fromCol, toRow, toCol)
end

function ChessRules.isLegalMove(board, fromRow, fromCol, toRow, toCol)
    if not pseudoLegal(board, fromRow, fromCol, toRow, toCol) then return false end
    local piece = at(board, fromRow, fromCol)
    local copy = table.clone(board)
    copy[key(fromRow, fromCol)] = nil
    copy[key(toRow, toCol)] = piece
    return not ChessRules.inCheck(copy, piece.side)
end

function ChessRules.analyze(board, side)
    local checked = ChessRules.inCheck(board, side)
    for row = 1, 8 do
        for col = 1, 8 do
            local piece = at(board, row, col)
            if piece and piece.side == side then
                for tr = 1, 8 do
                    for tc = 1, 8 do
                        if ChessRules.isLegalMove(board, row, col, tr, tc) then
                            return checked and "Check" or "Playing"
                        end
                    end
                end
            end
        end
    end
    return checked and "Checkmate" or "Stalemate"
end

function ChessRules.snapshot(occupancy)
    local board = {}
    for row = 1, 8 do
        for col = 1, 8 do
            local model = occupancy[key(row, col)]
            if model then
                board[key(row, col)] = {
                    kind = model:GetAttribute("PieceType"),
                    side = model:GetAttribute("Side"),
                }
            end
        end
    end
    return board
end

return ChessRules
