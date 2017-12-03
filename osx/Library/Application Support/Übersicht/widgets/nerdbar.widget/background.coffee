# Background and shared styles
refreshFrequency: false
render: ( ) ->
    """
    <link rel="stylesheet" href="nerdbar.widget/assets/css/font-awesome.min.css" />
    <link rel="stylesheet" href="nerdbar.widget/assets/css/shared.css" />
    """

style: """
    top: 0px
    left: 0px
    right: 0px
    height: 23px

    z-index: -1

    background-color: rgba(43, 42, 39, 0.7)
    -webkit-backdrop-filter: blur(10px)

    border-bottom: 1px solid #839a57;
    """
