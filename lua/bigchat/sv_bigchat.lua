util.AddNetworkString( "BigChat_Enable" )
util.AddNetworkString( "BigChat_Incoming" )
util.AddNetworkString( "BigChat_Receive" )
util.AddNetworkString( "BigChat_Incoming_JK" )

local string_StartWith = string.StartWith

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

local function broadcastBigChat( ply, msg, isTeam )
    if #msg == 0 then return end
    if string_StartWith( msg, "!p " ) then return end
    if string_StartWith( msg, "@" ) then return end

    local recipients = RecipientFilter()
    if isTeam then
        recipients:AddRecipientsByTeam( ply:Team() )
    else
        recipients:AddAllPlayers()
    end

    net.Start( "BigChat_Receive" )
    net.WriteEntity( ply )
    net.WriteString( msg )
    net.Send( recipients )
end

local function processBigChat( ply )
    local message = ply.BigChat_Message
    local msg = message.msg
    local isTeam = message.isTeam

    ply.BigChat_Message = nil

    timer.Simple( 0, function()
        local isBigChat = true
        msg = hook.Run( "PlayerSay", ply, msg, isTeam, isBigChat )
        if msg == "" then return end

        broadcastBigChat( ply, msg, isTeam )

        local playerName = ply:Nick()

        print( string.format( "%s: %s", playerName, msg ) )
        local teamLog = isTeam and "<Team>" or ""
        local logFormat = [["%s<%d><%s>%s" say "%s"]]
        ServerLog( string.format( logFormat, playerName, ply:UserID(), ply:SteamID(), teamLog, msg ) .. "\n" )
    end )
end

-- This net message is received first
net.Receive( "BigChat_Receive", function( _, ply )
    if not waitingForBigChat[ply] then return end
    if not canUseBigChat( ply ) then return end

    waitingForBigChat[ply] = nil
    ply.BigChat_SkipNext = true

    local isTeam = net.ReadBool()
    local msg = net.ReadString()

    local len = utf8.len( msg )
    if len > BigChat.maxLengthConvar:GetInt() then
        msg = ""
    end

    ply.BigChat_Message = { msg = msg, isTeam = isTeam }
end )

-- This hook is called after the BigChat_Receive net message is received
hook.Add( "PlayerSay", "BigChat_ChatWatcher", function( ply, _, _, isBigChat )
    if waitingForBigChat[ply] then return "" end
    if isBigChat then return end
    if ply.BigChat_SkipNext then
        ply.BigChat_SkipNext = nil
        processBigChat( ply )
        return ""
    end
end, HOOK_HIGH )
