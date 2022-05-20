util.AddNetworkString( "BigChat_Incoming" )
util.AddNetworkString( "BigChat_Receive" )
util.AddNetworkString( "BigChat_Incoming_JK" )

local waitingForBigChat = {}

net.Receive( "BigChat_Incoming", function( _, ply )
    waitingForBigChat[ply] = true
end )

net.Receive( "BigChat_Incoming_JK", function( _, ply )
    waitingForBigChat[ply] = nil
end )

net.Receive( "BigChat_Receive", function( _, ply )
    if not waitingForBigChat[ply] then return end

    local msg = net.ReadString()
    net.Start( "BigChat_Receive" )
    net.WriteEntity( ply )
    net.WriteString( msg )
    net.Broadcast()

    hook.Run( "PlayerSay", ply, msg )
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
