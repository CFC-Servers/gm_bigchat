AddCSLuaFile()

BigChat = {
    maxLengthConvar = CreateConVar( "bigchat_max_length", 500, FCVAR_ARCHIVE + FCVAR_REPLICATED )
}

if SERVER then
    AddCSLuaFile( "bigchat/cl_bigchat.lua" )

    hook.Add( "InitPostEntity", "BigChat_Setup", function()
        include( "bigchat/sv_bigchat.lua" )
    end )
else
    include( "bigchat/cl_bigchat.lua" )
end
