# Additional indicators

commands =
  date : "date +'%H:%M %d-%m-%y'"
  cpu : "ESC=`printf \"\e\"`; ps -A -o %cpu | awk '{s+=$1} END {printf(\"%.2f\",s/8);}'"
  mem : "ESC=`printf \"\e\"`; ps -A -o %mem | awk '{s+=$1} END {printf(\"%.2f\",s/8);}'"

command: "echo " +
         "$(#{ commands.date }):::" +
         "$(#{ commands.cpu }):::" +
         "$(#{ commands.mem }):::"
refreshFrequency: 30000

render: ( ) ->
    """
    <div class="window">
        <div class="indicator">
            <span class="mem-output"></span>
            <i class="fa fa-microchip" style="color: #c678dd"></i>
        </div>
        <div class="indicator">
            <span class="cpu-output"></span>
            <i class="fa fa-dashboard" style="color: #c678dd"></i>
        </div>
        <div class="indicator">
            <span class="date-output"></span>
            <i class="fa fa-clock-o" style="color: #26a6a6"></i>
        </div>
    </div>
    """

update: ( output ) ->
    output = output.split( /:::/g )
    [date, cpu, mem] = output
    $( ".date-output" ) .text( "#{ date }" )
    $( ".cpu-output" ) .text( "#{ cpu }" )
    $( ".mem-output" ) .text( "#{ mem }" )

style: """
    .indicator
        margin-left: 5px
        display: inline-block

    top: 2px
    right: 130px
    """

# ──────────────────────────────────────────────────────────────────────────────
