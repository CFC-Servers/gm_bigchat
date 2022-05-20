util.AddNetworkString( "BigChat_Enable" )
util.AddNetworkString( "BigChat_Incoming" )
util.AddNetworkString( "BigChat_Receive" )
util.AddNetworkString( "BigChat_Incoming_JK" )

local waitingForBigChat = {}

local function _canUseBigChat( ply )
    local canBig = hook.Run( "BigChat_CanUse", ply )
    if canBig == false then return false end

    return true
end

local function canUseBigChat( ply )
    local cached = ply.canUseBigChat
    if cached then return cached end

    local canUse = _canUseBigChat( ply )
    ply.canUseBigChat = canUse

    return canUse
end

-- If player is allowed, send the Enable message
-- Otherwise, ignore it
net.Receive( "BigChat_Enable", function( _, ply )
    if not canUseBigChat( ply ) then return end
    net.Start( "BigChat_Enable" )
    net.Send( ply )
end )

net.Receive( "BigChat_Incoming", function( _, ply )
    if not canUseBigChat( ply ) then return end
    waitingForBigChat[ply] = true
end )

net.Receive( "BigChat_Incoming_JK", function( _, ply )
    if not canUseBigChat( ply ) then return end
    waitingForBigChat[ply] = nil
end )

local function logBigChat( ply, msg )
    msg = hook.Run( "PlayerSay", ply, msg, false )
    if msg == "" then return end

    local playerName = ply:Nick()

    print( string.format( "%s: %s", playerName, msg ) )
    local logFormat = [["%s<%d><%s>" say "%s"]]
    ServerLog( string.format( logFormat, playerName, ply:UserID(), ply:SteamID(), msg ) .. "\n" )
end

net.Receive( "BigChat_Receive", function( _, ply )
    if not waitingForBigChat[ply] then return end
    if not canUseBigChat( ply ) then return end

    local msg = net.ReadString()
    if #msg > BigChat.maxLengthConvar:GetInt() then return end

    net.Start( "BigChat_Receive" )
    net.WriteEntity( ply )
    net.WriteString( msg )
    net.Broadcast()

    logBigChat( ply, msg )
    waitingForBigChat[ply] = nil
    ply.blockNextMessage = true
end )

hook.Add( "PlayerSay", "BigChat_ChatWatcher", function( ply )
    if waitingForBigChat[ply] then return "" end
    if ply.blockNextMessage then
        ply.blockNextMessage = nil
        return ""
    end
end, HOOK_HIGH )
