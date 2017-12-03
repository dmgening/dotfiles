command: "khd -e 'print mode'"
refreshFrequency: 100

render: ( ) ->
    """
    <div class="window">
        <div class="indicator">
            <i class="fa  fa-keyboard-o" style="color: #5699AF"></i>
            <span class="khd-mode-output"></span>
        </div>
    </div>
    """

update: ( output ) -> $( ".khd-mode-output" ).text( "#{ output }" )

style: """
    .indicator
        margin-right: 5px
        display: inline-block

    top: 2px
    left: calc(50% + 25px)
    """
