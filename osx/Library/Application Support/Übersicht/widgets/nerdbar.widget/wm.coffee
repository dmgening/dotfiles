commands =
  space : "chunkc tiling::query --desktop id"
  mode : "chunkc tiling::query --desktop mode"
command: "echo " +
         "$(#{ commands.space }):::" +
         "$(#{ commands.mode }):::"
refreshFrequency: 1000

render: ( ) ->
    """
    <div class="window">
        <div class="indicator">
            <span class="space-output"></span> -
            <span class="mode-output"></span>
            <i class="fa fa-window-restore" style="color: #a9a1e1"></i>
        </div>
    </div>
    """

update: ( output ) ->
    output = output.split( /:::/g )
    [space, mode] = output
    $( ".space-output" ) .text( "#{ space }" )
    $( ".mode-output" ) .text( "#{ mode }" )

style: """
    .indicator
        margin-left: 5px
        display: inline-block

    top: 2px
    right: calc(50% + 25px)
    """
