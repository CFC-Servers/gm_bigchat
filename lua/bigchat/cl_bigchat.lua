local function init()
    local IsValid = IsValid
    local CHAT_BOX = CHAT_BOX or nil

    net.Receive( "BigChat_Receive", function()
        local ply = net.ReadEntity()
        if not IsValid( ply ) then return end

        local msg = net.ReadString()
        hook.Run( "OnPlayerChat", ply, msg, false, not ply:Alive() )
    end )

    local function wrapChatBox( chatBox )
        CHAT_BOX = CHAT_BOX or chatBox
        if not chatBox then return end

        local inp = chatBox:Find( "ChatInput" )
        inp:SetMaximumCharCount( BigChat.maxLengthConvar:GetInt() )
    end
    cvars.AddChangeCallback( "bigchat_max_length", function()
        if not CHAT_BOX then return end
        timer.Simple( 0, function()
            wrapChatBox( CHAT_BOX )
        end )
    end )

    local isBig = false
    local isTeamMessage = false
    local x = nil
    local chatY = nil
    local width = nil
    local inpHeight = nil
    local maxInputHeightMultiplier = 3.5

    local function makeUnBig()
        local inputContainer = CHAT_BOX.inputContainer
        if not IsValid( inputContainer ) then return end

        local inp = CHAT_BOX:Find( "ChatInput" )
        local inpHolder = inp:GetParent()
        local label = inpHolder:Find("ChatInputPrompt")

        label:SetText( "Say:" )

        CHAT_BOX:SetHeight( CHAT_BOX:GetTall() - ( inpHeight * ( maxInputHeightMultiplier - 1 ) ) )

        inpHolder:Dock( BOTTOM )
        inpHolder:SetParent( CHAT_BOX )

        inp:SetMultiline( false )

        CHAT_BOX:InvalidateLayout( true )
        inpHolder:Dock( NODOCK )
        CHAT_BOX:InvalidateLayout( true )

        inpHolder:SetX( x )
        inpHolder:SetWidth( width )
        inpHolder:InvalidateLayout( true )

        inputContainer:Remove()
        CHAT_BOX.inputContainer = nil

        -- undo the chat wrapper
        local textContainer = CHAT_BOX.textContainer
        -- if not IsValid( textContainer ) then return end

        local chatContainer = textContainer:GetChildren()[1]
        chatContainer:SetParent( CHAT_BOX )

        chatContainer:Dock( NODOCK )
        CHAT_BOX:InvalidateLayout( true )

        chatContainer:SetX( x )
        chatContainer:SetY( chatY )
        chatContainer:InvalidateLayout( true )

        textContainer:Remove()
        CHAT_BOX.textContainer = nil
    end

    local function makeBig()
        local inp = CHAT_BOX:Find( "ChatInput" )
        local chatContainer = CHAT_BOX:Find( "HudChatHistory" )

        inpHeight = inp:GetTall()
        local inpHolder = inp:GetParent()
        local label = inpHolder:Find("ChatInputPrompt")
        label:SetText( "Big:" )

        x = x or inpHolder:GetX()
        local inpY = inpHolder:GetY()
        width = width or inpHolder:GetWide()
        chatY = chatY or chatContainer:GetY()

        -- spacer
        local inputTopMargin = inpY - ( chatY + chatContainer:GetTall() )
        local inputBottomMargin = CHAT_BOX:GetTall() - ( inpY + inpHeight )

        -- input line wrapper
        CHAT_BOX.inputContainer = vgui.Create( "DPanel", CHAT_BOX )
        local inputContainer = CHAT_BOX.inputContainer

        inputContainer:Dock(BOTTOM)
        inputContainer:DockMargin( x, inputTopMargin, 0, inputBottomMargin )
        inputContainer:SetTall( inpHeight * maxInputHeightMultiplier )
        inputContainer.Paint = function() end
        inpHolder:SetParent( inputContainer )
        inpHolder:Dock( LEFT )
        inp:SetMultiline( true )

        -- chat wrapper
        CHAT_BOX.textContainer = vgui.Create( "DPanel", CHAT_BOX )
        local textContainer = CHAT_BOX.textContainer
        textContainer:Dock(FILL)

        textContainer:DockMargin( x, chatY, x, 0 )
        textContainer.Paint = function() end

        chatContainer:SetParent( textContainer )
        chatContainer:Dock(FILL)

        -- size the overall box
        CHAT_BOX:SetHeight( CHAT_BOX:GetTall() + ( inpHeight * ( maxInputHeightMultiplier - 1 ) ) )

        -- invalidations
        textContainer:InvalidateLayout( true )
        inputContainer:InvalidateLayout( true )
        CHAT_BOX:InvalidateLayout( true )
    end

    hook.Add( "ChatTextChanged", "BigChat_BigWatcher", function( text )
        if not CHAT_BOX then
            local focused = vgui.GetKeyboardFocus()
            if not focused then return end

            wrapChatBox( focused:GetParent():GetParent() )
        end

        local inp = CHAT_BOX:Find( "ChatInput" )

        if #text > 0 then
            inp.LastText = text
        end

        if #text < 128 then
            if isBig then
                net.Start( "BigChat_Incoming_JK" )
                net.SendToServer()

                local caretPos = inp:GetCaretPos()
                makeUnBig()
                inp:SetText( inp:GetText() )
                inp:SetCaretPos( caretPos )

                isBig = false
            end

            return
        end

        if isBig then return end

        net.Start( "BigChat_Incoming" )
        net.SendToServer()

        makeBig()
        isBig = true
    end )

    hook.Add( "FinishChat", "BigChat_Undo", function()
        if isBig == false then return end

        local inputContainer = CHAT_BOX.inputContainer
        if not IsValid( inputContainer ) then return end

        local inp = inputContainer:Find( "ChatInput" )
        local chatText = inp.LastText or ""

        if #chatText > 128 and not input.IsButtonDown( KEY_ESCAPE ) then
            net.Start( "BigChat_Receive" )
            net.WriteBool( isTeamMessage )
            net.WriteString( chatText )
            net.SendToServer()
        end

        makeUnBig()
        isBig = false
        inp.LastText = nil
    end )

    hook.Add( "StartChat", "BigChat_JK", function( isTeam )
        isTeamMessage = isTeam

        net.Start( "BigChat_Incoming_JK" )
        net.SendToServer()
    end )

    local beepSound = {
        channel = CHAN_STATIC,
        name = "BigChat_ChatBeep",
        sound = "buttons/button3.wav",
        volume = 1,
        pitch = 75
    }
    sound.Add( beepSound )

    hook.Add( "OnPlayerChat", "BigChat_Ping", function( ply, text )
        if ply == LocalPlayer() then return end

        local nick = string_lower( LocalPlayer():Nick() )
        local found = string_find( text, nick )
        if not found then return end

        surface.PlaySound( "BigChat_ChatBeep" )
    end )
end

net.Receive( "BigChat_Enable", function()
    init()
end )

hook.Add( "StartChat", "BigChat_Setup", function()
    hook.Remove( "StartChat", "BigChat_Setup" )
    net.Start( "BigChat_Enable" )
    net.SendToServer()
end )

