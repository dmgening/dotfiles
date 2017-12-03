# Focused window

command: "echo $(/usr/local/bin/chunkc tiling::query --window tag)"
refreshFrequency: 1000

render: ( ) ->
    """
    <div class="window">
        <i class="fa fa-th-list" style="color: #cb4b16"></i>
        <span class="window-output"></span>
    </div>
    """
update: ( output ) -> $( ".window-output" ).text( "#{ if output == '?\n' then '' else output }" )

style: """
    .window-output
        padding-left: 5px

    .window
        max-width: calc(30% - 130px)

    width: 100%
    top: 2px
    left: 130px
    """
