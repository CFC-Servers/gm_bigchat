# gm_bigchat
Garry's Mod Chat, but bigger

# Usage
Just install the addon!

If a player types more text than the standard text box allows, the box will expand to "Big" mode.

# Caveats

## Compatability
No effort has been made to make this work with popular chat addons. I would be very surprised if it did.

This addon is intended to enhance the default chat box as unintrusively as possible.


## Operating conditions
If a message is under the default GMod limit, BigChat will stay out of the way entirely.
Only when the messag exceeds the default GMod length will BigChat take over.

## Privileges
When a client spawns, they ask the server if they can use BigChat.

The server runs a hook, `BigChat_CanUse` with the requesting player.
You may return `false` in this hook to prevent the player from using BigChat.

If the player uses clientside lua to send bigchats anyway, they still won't work - all of the serverside net receivers and hooks are also guarded.
