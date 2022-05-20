AddCSLuaFile()

BigChat = {
    maxLengthConvar = CreateConVar( "bigchat_max_length", 500, FCVAR_ARCHIVE + FCVAR_REPLICATED )
}

if SERVER then
    include( "bigchat/sv_bigchat.lua" )
    AddCSLuaFile( "bigchat/cl_bigchat.lua" )
else
    include( "bigchat/cl_bigchat.lua" )
end
