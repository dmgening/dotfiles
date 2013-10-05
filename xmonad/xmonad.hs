-- Language
{-# LANGUAGE DeriveDataTypeable, NoMonomorphismRestriction, MultiParamTypeClasses, ImplicitParams #-}

-- ------------------------------------------------------------------
-- Imports
-- ------------------------------------------------------------------
import XMonad

-- Layout
import XMonad
import XMonad.Layout
import XMonad.Layout.IM
import XMonad.Layout.Named
import XMonad.Layout.Tabbed
import XMonad.Layout.OneBig
import XMonad.Layout.Master
import XMonad.Layout.Reflect
import XMonad.Layout.MosaicAlt
import XMonad.Layout.NoFrillsDecoration
import XMonad.Layout.SimplestFloat
import XMonad.Layout.NoBorders
import XMonad.Layout.ResizableTile
import XMonad.Layout.MultiToggle
import XMonad.Layout.MultiToggle.Instances
import XMonad.Layout.PerWorkspace (onWorkspace)
import XMonad.Layout.Minimize
import XMonad.Layout.Maximize
import XMonad.Layout.ToggleLayouts
import XMonad.Layout.ComboP
import XMonad.Layout.MagicFocus
import XMonad.Layout.WindowNavigation
import XMonad.Layout.WindowSwitcherDecoration
import XMonad.Layout.DraggingVisualizer

import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.ManageDocks

import qualified XMonad.StackSet as W
import qualified XMonad.Actions.FlexibleResize as Flex
import qualified XMonad.Util.ExtensibleState as XS

-- Scratchpad
import XMonad.Util.Scratchpad
import XMonad.Util.NamedScratchpad

-- Statusbar

-- Prompt
import XMonad.Prompt
import XMonad.Prompt.Shell
import XMonad.Prompt.Man

-- Keyboard & Mouse
import XMonad.Util.Cursor
import XMonad.Actions.MouseResize
import Graphics.X11.ExtraTypes.XF86

-- System
import System.Exit
import System.IO (Handle, hPutStrLn)

-- Data Types
import Data.Monoid
import Data.List
import qualified Data.Map as M

-- Utility
import XMonad.Hooks.SetWMName
import XMonad.Actions.GridSelect

-- Non-official modules
import DzenBoxLoggers

--Unsorted
import XMonad.Actions.ShowText
import XMonad.Hooks.UrgencyHook
import XMonad.Hooks.DynamicLog
import XMonad.Util.Loggers
import XMonad.Util.Run (spawnPipe)
import XMonad.Util.Timer

-- ------------------------------------------------------------------
-- Look & Feel
-- ------------------------------------------------------------------

myFont		= "xft:Droid Sans Mono:pixelsize=12"

clBackground 	= ""
clCurrentLine 	= ""
clSelection 	= ""
clForeground 	= ""
clComment		= "" 

-- Ethan Schoonover "Solarized" Theme
clBase03    = "#1d1f21"
clBase02    = "#282a2e"
clBase01    = "#969896"
clBase00    = "#373b41"

clBase0     = "#c5c8c6"

clRed       = "#cc6666"
clOrange    = "#de935f"
clYellow    = "#f0c674"
clGreen     = "#b5bd68"
clCyan      = "#8abeb7"
clBlue      = "#81a2be"

clMagenta   = "#"
clViolet    = "#b294bb"

displayX = 1920
displayY = 1080

dockHeigth = 16
dockSepTop = 950
dockSepBot = 400

boxHeight      = 12
boxLeftIcon    = "/home/dmgening/.xmonad/icons/boxleft.xbm"   --left icon of dzen logger boxes
boxLeftIcon2   = "/home/dmgening/.xmonad/icons/boxleft2.xbm"  --left icon2 of dzen logger boxes
boxRightIcon   = "/home/dmgening/.xmonad/icons/boxright.xbm"  --right icon of dzen logger boxes

-- Title theme

myTitleTheme :: Theme
myTitleTheme = defaultTheme
	{ fontName            = myFont
	, inactiveBorderColor = clBase02
	, inactiveColor       = clBase03
	, inactiveTextColor   = clBase01
	, activeBorderColor   = clBase02
	, activeColor         = clBase03
	, activeTextColor     = clGreen
	, urgentBorderColor   = clMagenta
	, urgentTextColor     = clMagenta
	, decoHeight          = dockHeigth
	}

-- Prompt theme
myXPConfig :: XPConfig
myXPConfig = defaultXPConfig
	{ font              = myFont
	, bgColor           = clBase03
	, fgColor           = clBase01
	, bgHLight          = clBase03
	, fgHLight          = clBlue
	, borderColor       = clBase02
	, promptBorderWidth = 1
	, height            = dockHeigth
	, position          = Top
	, historySize       = 100
	, historyFilter     = deleteConsecutive
	}

-- GridSelect color scheme
myColorizer :: Window -> Bool -> X (String, String)
myColorizer = colorRangeFromClassName
	(0x00,0x2B,0x36) --lowest inactive bg
	(0x07,0x36,0x42) --highest inactive bg
	(0x85,0x99,0x00) --active bg
	(0x58,0x6E,0x75) --inactive fg
	(0x07,0x36,0x42) --active fg

-- GridSelect theme
myGSConfig :: t -> GSConfig Window
myGSConfig colorizer = (buildDefaultGSConfig myColorizer)
	{ gs_cellheight  = 40
	, gs_cellwidth   = 200
	, gs_cellpadding = 10
	, gs_font        = myFont
	}

-- Flash text config
myTextConfig :: ShowTextConfig
myTextConfig = STC
	{ st_font = myFont
	, st_bg   = clBase03
	, st_fg   = clBase01
	}

-- Dzen logger box pretty printing themes
gray2BoxPP :: BoxPP
gray2BoxPP = BoxPP
	{ bgColorBPP   = clBase03
	, fgColorBPP   = clBase01
	, boxColorBPP  = clBase02
	, leftIconBPP  = boxLeftIcon2
	, rightIconBPP = boxRightIcon
	, boxHeightBPP = boxHeight
	}

blueBoxPP :: BoxPP
blueBoxPP = BoxPP
	{ bgColorBPP   = clBase03
	, fgColorBPP   = clBlue
	, boxColorBPP  = clBase02
	, leftIconBPP  = boxLeftIcon
	, rightIconBPP = boxRightIcon
	, boxHeightBPP = boxHeight
	}

blue2BoxPP :: BoxPP
blue2BoxPP = BoxPP
	{ bgColorBPP   = clBase03
	, fgColorBPP   = clBlue
	, boxColorBPP  = clBase02
	, leftIconBPP  = boxLeftIcon2
	, rightIconBPP = boxRightIcon
	, boxHeightBPP = boxHeight
	}

whiteBoxPP :: BoxPP
whiteBoxPP = BoxPP
	{ bgColorBPP   = clBase03
	, fgColorBPP   = clBase01
	, boxColorBPP  = clBase02
	, leftIconBPP  = boxLeftIcon
	, rightIconBPP = boxRightIcon
	, boxHeightBPP = boxHeight
	}

blackBoxPP :: BoxPP
blackBoxPP = BoxPP
	{ bgColorBPP   = clBase03
	, fgColorBPP   = clBase03
	, boxColorBPP  = clBase01
	, leftIconBPP  = boxLeftIcon
	, rightIconBPP = boxRightIcon
	, boxHeightBPP = boxHeight
	}

white2BBoxPP :: BoxPP
white2BBoxPP = BoxPP
	{ bgColorBPP   = clBase03
	, fgColorBPP   = clBase03
	, boxColorBPP  = clBase01
	, leftIconBPP  = boxLeftIcon2
	, rightIconBPP = boxRightIcon
	, boxHeightBPP = boxHeight
	}

blue2BBoxPP :: BoxPP --current workspace
blue2BBoxPP = BoxPP
	{ bgColorBPP   = clBase03
	, fgColorBPP   = clBase03
	, boxColorBPP  = clGreen
	, leftIconBPP  = boxLeftIcon2
	, rightIconBPP = boxRightIcon
	, boxHeightBPP = boxHeight
	}

green2BBoxPP :: BoxPP --urgent workspace
green2BBoxPP = BoxPP
	{ bgColorBPP   = clBase03
	, fgColorBPP   = clBase03
	, boxColorBPP  = clMagenta
	, leftIconBPP  = boxLeftIcon2
	, rightIconBPP = boxRightIcon
	, boxHeightBPP = boxHeight
	}

-- Dzen logger clickable areas
calendarCA :: CA
calendarCA = CA
	{ leftClickCA   = "/home/dmgening/.bin/dzencal.sh"
	, middleClickCA = ""
	, rightClickCA  = ""
	, wheelUpCA     = ""
	, wheelDownCA   = ""
	}

layoutCA :: CA
layoutCA = CA
	{ leftClickCA   = "/usr/bin/xdotool key super+space"
	, middleClickCA = ""
	, rightClickCA  = "/usr/bin/xdotool key super+shift+space"
	, wheelUpCA     = ""
	, wheelDownCA   = ""
	}

workspaceCA :: CA
workspaceCA = CA
	{ leftClickCA   = "/usr/bin/xdotool key super+1"
	, middleClickCA = "/usr/bin/xdotool key super+g"
	, rightClickCA  = "/usr/bin/xdotool key super+0"
	, wheelUpCA     = "/usr/bin/xdotool key ctrl+alt+Right"
	, wheelDownCA   = "/usr/bin/xdotool key ctrl+alt+Left"
	}

focusCA :: CA
focusCA = CA
	{ leftClickCA   = "/usr/bin/xdotool key super+m"
	, middleClickCA = "/usr/bin/xdotool key super+c"
	, rightClickCA  = "/usr/bin/xdotool key super+shift+m"
	, wheelUpCA     = "/usr/bin/xdotool key super+shift+j"
	, wheelDownCA   = "/usr/bin/xdotool key super+shift+k"
	}

-- ------------------------------------------------------------------
-- Workspaces
-- ------------------------------------------------------------------

-- Workspace index
myWorkspaces :: [WorkspaceId]
myWorkspaces = map show $ [1..9] ++ [0]

-- Workspace names
workspaceNames :: [WorkspaceId]
workspaceNames = ["Terminal", "Network", "Development", "Graphics", "Chatting", "Video", "Alternate", "Alternate", "Alternate", "Alternate"]

---------------------------------------------------------------------
-- Dzen2 status bar config
---------------------------------------------------------------------

-- Dzen2 Flags
dzTLFlags :: DF
dzTLFlags = DF
	{ xPosDF       = 0
	, yPosDF       = 0
	, widthDF      = dockSepTop
	, heightDF     = dockHeigth
	, alignementDF = "l"
	, fgColorDF    = clBase01
	, bgColorDF    = clBase03
	, fontDF       = myFont
	, eventDF      = "onstart=lower"
	, extrasDF     = "-p"
	}

dzTRFlags :: DF
dzTRFlags = DF
	{ xPosDF       = dockSepTop
	, yPosDF       = 0
	, widthDF      = displayX - dockSepTop
	, heightDF     = dockHeigth
	, alignementDF = "r"
	, fgColorDF    = clBase01
	, bgColorDF    = clBase03
	, fontDF       = myFont
	, eventDF      = "onstart=lower"
	, extrasDF     = "-p"
	}

dzBLFlags :: DF
dzBLFlags = DF
	{ xPosDF       = 0
	, yPosDF       = displayY - dockHeigth
	, widthDF      = dockSepBot
	, heightDF     = dockHeigth
	, alignementDF = "l"
	, fgColorDF    = clBase01
	, bgColorDF    = clBase03
	, fontDF       = myFont
	, eventDF      = "onstart=lower"
	, extrasDF     = "-p"
	}

dzBRFlags :: DF
dzBRFlags = DF
	{ xPosDF       = dockSepBot
	, yPosDF       = displayY - dockHeigth
	, widthDF      = displayX - dockSepBot
	, heightDF     = dockHeigth
	, alignementDF = "r"
	, fgColorDF    = clBase01
	, bgColorDF    = clBase03
	, fontDF       = myFont
	, eventDF      = "onstart=lower"
	, extrasDF     = "-p"
	}

-- Hooks
dzUrgencyHook :: LayoutClass l Window => XConfig l -> XConfig l
dzUrgencyHook = withUrgencyHook dzenUrgencyHook
	{ duration = 2000000
	, args     = ["-x", "0", "-y", "0", "-h", show dockHeigth, "-w", show displayX, "-fn", myFont, "-bg", clBase03, "-fg", clMagenta]
	}

dzTLLogHook :: Handle -> X ()
dzTLLogHook h = dynamicLogWithPP $ defaultPP
	{ ppOutput = hPutStrLn h
	, ppOrder = \(_:_:_:x) -> x
	, ppSep = " "
	, ppExtras = [ myLayoutL, myWorkspaceL, myFocusL ]
	}

-- Top right bar logHook
dzTRLogHook :: Handle -> X ()
dzTRLogHook h = dynamicLogWithPP $ defaultPP
	{ ppOutput  = hPutStrLn h
	, ppOrder = \(_:_:_:x) -> x
	, ppSep = " "
	, ppExtras  = [ myUptimeL, myDateL ]
	}

dzBLLogHook :: Handle -> X ()
dzBLLogHook h = dynamicLogWithPP $ defaultPP
	{ ppOutput          = hPutStrLn h
	, ppSort            = fmap (namedScratchpadFilterOutWorkspace .) (ppSort defaultPP) --hide "NSP" from workspace list
	, ppOrder           = \(ws:l:_:x) -> [ws] ++ x
	, ppSep             = " "
	, ppWsSep           = ""
	, ppCurrent         = dzenBoxStyle blue2BBoxPP
	, ppUrgent          = dzenBoxStyle green2BBoxPP . dzenClickWorkspace
	, ppVisible         = dzenBoxStyle blackBoxPP . dzenClickWorkspace
	, ppHiddenNoWindows = dzenBoxStyle blackBoxPP . dzenClickWorkspace
	, ppHidden          = dzenBoxStyle whiteBoxPP . dzenClickWorkspace
	, ppExtras          = [ myFsL ]
	} where
		dzenClickWorkspace ws = "^ca(1," ++ xdo "w;" ++ xdo index ++ ")" ++ "^ca(3," ++ xdo "w;" ++ xdo index ++ ")" ++ ws ++ "^ca()^ca()" where
			wsIdxToString Nothing = "1"
			wsIdxToString (Just n) = show $ mod (n+1) $ length myWorkspaces
			index = wsIdxToString (elemIndex ws myWorkspaces)
			xdo key = "/usr/bin/xdotool key super+" ++ key

dzBRLogHook :: Handle -> X ()
dzBRLogHook h = dynamicLogWithPP $ defaultPP
	{ ppOutput          = hPutStrLn h
	, ppOrder           = \(_:_:_:x) -> x
	, ppSep             = " "
	, ppExtras          = [ myCpuL, myMemL, myTempL, myBrightL, myWifiL]
	}


---------------------------------------------------------------------
-- Loggers config
---------------------------------------------------------------------
myWifiL      = (dzenBoxStyleL gray2BoxPP $ labelL "WIFI") ++! (dzenBoxStyleL blueBoxPP wifiSignal)
myBrightL    = (dzenBoxStyleL gray2BoxPP $ labelL "BRIGHT") ++! (dzenBoxStyleL blueBoxPP brightPerc)
myTempL      = (dzenBoxStyleL gray2BoxPP $ labelL "TEMP") ++! (dzenBoxStyleL blueBoxPP cpuTemp)
myMemL       = (dzenBoxStyleL gray2BoxPP $ labelL "MEM") ++! (dzenBoxStyleL blueBoxPP memUsage)
myCpuL       = (dzenBoxStyleL gray2BoxPP $ labelL "CPU") ++! (dzenBoxStyleL blueBoxPP $ cpuUsage "/tmp/haskell-cpu-usage.txt")
myFsL        = (dzenBoxStyleL blue2BoxPP $ labelL "ROOT") ++! (dzenBoxStyleL whiteBoxPP $ fsPerc "/") 
myDateL      = (dzenBoxStyleL white2BBoxPP $ date "%A") ++! (dzenBoxStyleL whiteBoxPP $ date $ "%Y^fg(" ++ clBase01 ++ ").^fg()%m^fg(" ++ clBase01 ++ ").^fg()^fg(" ++ clBlue ++ ")%d^fg() ^fg(" ++ clBase01 ++ ")-^fg() %H^fg(" ++ clBase01 ++ "):^fg()%M^fg(" ++ clBase01 ++ "):^fg()^fg(" ++ clGreen ++ ")%S^fg()") ++! (dzenClickStyleL calendarCA $ dzenBoxStyleL blueBoxPP $ labelL "CALENDAR")
myUptimeL    = (dzenBoxStyleL blue2BoxPP $ labelL "UPTIME") ++! (dzenBoxStyleL whiteBoxPP uptime)
myFocusL     = (dzenClickStyleL focusCA $ dzenBoxStyleL white2BBoxPP $ labelL "FOCUS") ++! (dzenBoxStyleL whiteBoxPP $ shortenL 100 logTitle)
myLayoutL    = (dzenClickStyleL layoutCA $ dzenBoxStyleL blue2BoxPP $ labelL "LAYOUT") ++! (dzenBoxStyleL whiteBoxPP $ onLogger (layoutText . removeWord . removeWord) logLayout) where
	removeWord = tail . dropWhile (/= ' ')
	layoutText xs
		| isPrefixOf "Mirror" xs       = layoutText $ removeWord xs ++ " [M]"
		| isPrefixOf "ReflectY" xs     = layoutText $ removeWord xs ++ " [Y]"
		| isPrefixOf "ReflectX" xs     = layoutText $ removeWord xs ++ " [X]"
		| isPrefixOf "Simple Float" xs = "^fg(" ++ clGreen ++ ")" ++ xs
		| isPrefixOf "Full Tabbed" xs  = "^fg(" ++ clRed ++ ")" ++ xs
		| otherwise                    = "^fg(" ++ clBase01 ++ ")" ++ xs
myWorkspaceL = (dzenClickStyleL workspaceCA $ dzenBoxStyleL blue2BoxPP $ labelL "WORKSPACE") ++! (dzenBoxStyleL whiteBoxPP $ onLogger namedWorkspaces logCurrent) where
	namedWorkspaces w
		| (elem w $ map show [0..9]) == True = "^fg(" ++ clGreen ++ ")" ++ w ++ "^fg(" ++ clBase01 ++ ")|^fg()" ++ workspaceNames !! (mod ((read w::Int) - 1) 10)
		| otherwise                          = "^fg(" ++ clRed ++ ")x^fg(" ++ clBase01 ++ ")|^fg()" ++ w

---------------------------------------------------------------------
-- Layout Config
---------------------------------------------------------------------

-- Main Layouts
myTile  = smartBorders $ toggleLayouts (named "ResizableTall [S]" myTileS) $ named "ResizableTall" $ ResizableTall 1 0.03 0.5 [] where
	myTileS = windowSwitcherDecoration shrinkText myTitleTheme (draggingVisualizer $ ResizableTall 1 0.03 0.5 [])
myMirr  = smartBorders $ toggleLayouts (named "MirrResizableTall [S]" myMirrS) $ named "MirrResizableTall" $ Mirror $ ResizableTall 1 0.03 0.5 [] where
	myMirrS = windowSwitcherDecoration shrinkText myTitleTheme (draggingVisualizer $ Mirror $ ResizableTall 1 0.03 0.5 [])
myMosA  = smartBorders $ toggleLayouts (named "MosaicAlt [S]" myMosAS) $ named "MosaicAlt" $ MosaicAlt M.empty where
	myMosAS = windowSwitcherDecoration shrinkText myTitleTheme (draggingVisualizer $ MosaicAlt M.empty)
myOneB  = smartBorders $ toggleLayouts (named "OneBig [S]" myOneBS) $ named "OneBig" $ OneBig 0.75 0.65 where
	myOneBS = windowSwitcherDecoration shrinkText myTitleTheme (draggingVisualizer $ OneBig 0.75 0.65)
myMTab  = smartBorders $ toggleLayouts (named "Mastered Tabbed [S]" myMTabS) $ named "Mastered Tabbed" $ mastered 0.01 0.4 $ tabbed shrinkText myTitleTheme where
	myMTabS = windowSwitcherDecoration shrinkText myTitleTheme (draggingVisualizer $ mastered 0.01 0.4 $ tabbed shrinkText myTitleTheme)

-- Special Layouts
myTabb  = smartBorders $ named "Tabbed" $ tabbed shrinkText myTitleTheme
myTTab  = smartBorders $ named "Two Tabbed" $ combineTwoP (OneBig 0.75 0.75) (tabbed shrinkText myTitleTheme) (tabbed shrinkText myTitleTheme) (ClassName "Chromium")
myFTab  = smartBorders $ named "Full Tabbed" $ tabbedAlways shrinkText myTitleTheme
myFloat = named "Simplest Float" $ mouseResize  $ noFrillsDeco shrinkText myTitleTheme simplestFloat
myGimp  = named "Gimp MosaicAlt" $ withIM (0.15) (Role "gimp-toolbox") $ reflectHoriz $ withIM (0.20) (Role "gimp-dock") myMosA
myChat  = named "Pidgin MirrResizableTall" $ withIM (0.20) (Title "Buddy List") $ myMirr

-- Tabbed transformer (W+f)
data TABBED = TABBED deriving (Read, Show, Eq, Typeable)
instance Transformer TABBED Window where
	transform TABBED x k = k myFTab (\_ -> x)

-- Floated transformer (W+ctl+f)
data FLOATED = FLOATED deriving (Read, Show, Eq, Typeable)
instance Transformer FLOATED Window where
	transform FLOATED x k = k myFloat (\_ -> x)

-- Layout hook
myLayoutHook = avoidStruts
	$ windowNavigation
	$ minimize
	$ maximize
	$ mkToggle (single TABBED)
	$ mkToggle (single FLOATED)
	$ mkToggle (single MIRROR)
	$ mkToggle (single REFLECTX)
	$ mkToggle (single REFLECTY)
	$ onWorkspace (myWorkspaces !! 1) webLayouts  --Workspace 1 layouts
	$ onWorkspace (myWorkspaces !! 2) codeLayouts --Workspace 2 layouts
	$ onWorkspace (myWorkspaces !! 3) gimpLayouts --Workspace 3 layouts
	$ onWorkspace (myWorkspaces !! 4) chatLayouts --Workspace 4 layouts
	$ allLayouts where
		allLayouts  = myTile ||| myOneB ||| myMirr ||| myMosA ||| myMTab
		webLayouts  = myTabb
		codeLayouts = myTabb 
		gimpLayouts = myGimp
		chatLayouts = myChat

---------------------------------------------------------------------
-- Windows managment hooks
---------------------------------------------------------------------
manageScratchPad :: ManageHook
manageScratchPad = scratchpadManageHook (W.RationalRect (0) (1/50) (1) (3/4))
scratchPad = scratchpadSpawnActionCustom "urxvtc -name scratchpad"

myManageHook :: ManageHook
myManageHook = composeAll . concat $
	[ [resource  =? r	--> doIgnore					| r <- myIgnores	] -- ignore desktop
	, [className =? c	--> doShift (myWorkspaces !! 1) | c <- myWebS		]
	, [className =? c	--> doShift (myWorkspaces !! 2) | c <- myCodeS		]	
	, [isFullscreen		--> doFullFloat										]
	] where
		doShiftAndGo ws = doF (W.greedyView ws) <+> doShift ws
		myIgnores		= ["desktop","desktop_window"]
		myWebS			= ["Firefox","Chromium","Opera"]
		myCodeS			= ["subl","subl3","emacs"]
---------------------------------------------------------------------
-- Handle Event Hook
---------------------------------------------------------------------

-- wrapper for the Timer id, so it can be stored as custom mutable state
data TidState = TID TimerId deriving Typeable

instance ExtensionClass TidState where
	initialValue = TID 0

-- Handle event hook
myHandleEventHook = docksEventHook <+> clockEventHook <+> handleTimerEvent <+> notFocusFloat where
	clockEventHook e = do                 --thanks to DarthFennec
		(TID t) <- XS.get                 --get the recent Timer id
		handleTimer t e $ do              --run the following if e matches the id
		    startTimer 1 >>= XS.put . TID --restart the timer, store the new id
		    ask >>= logHook . config      --get the loghook and run it
		    return Nothing                --return required type
		return $ All True                 --return required type
	notFocusFloat = followOnlyIf (fmap not isFloat) where --Do not focusFollowMouse on Float layout
		isFloat = fmap (isSuffixOf "Simplest Float") $ gets (description . W.layout . W.workspace . W.current . windowset)


---------------------------------------------------------------------
-- Other Hooks
---------------------------------------------------------------------

myStartupHook = do
	startTimer 1 >>= XS.put . TID
	setDefaultCursor xC_left_ptr
	spawn "urxvtd"
	setWMName "LG3D"

---------------------------------------------------------------------
-- Keyboard & Mouse
---------------------------------------------------------------------

myKeys :: XConfig Layout -> M.Map (KeyMask, KeySym) (X ())
myKeys conf@(XConfig {XMonad.modMask = modMask}) = M.fromList $
	[ ((modMask .|. shiftMask, 	xK_q), 		io (exitWith ExitSuccess))
	, ((modMask, 			xK_q), 		restart "xmonad" True)
	, ((modMask,			xK_r),		shellPrompt myXPConfig)
	, ((modMask .|. shiftMask,	xK_r),		manPrompt myXPConfig)
	, ((modMask .|. shiftMask,	xK_c),		kill)
	, ((modMask, 			xK_j), 		windows W.focusDown)
	, ((modMask, 			xK_k), 		windows W.focusUp)
	, ((modMask, 			xK_m), 		windows W.focusMaster)
	, ((modMask .|. shiftMask, 	xK_j), 		windows W.swapDown)
	, ((modMask .|. shiftMask, 	xK_k), 		windows W.swapUp)
	, ((modMask .|. shiftMask, 	xK_m), 		windows W.swapMaster)
	, ((modMask .|. shiftMask, 	xK_space), 	windows W.swapMaster)
	, ((modMask, 			xK_g), 		goToSelected $ myGSConfig myColorizer) 
	, ((modMask, 			xK_h), 		sendMessage Shrink)
	, ((modMask, 			xK_l), 		sendMessage Expand)
	, ((modMask .|. shiftMask, 	xK_h), 		sendMessage MirrorShrink)
	, ((modMask .|. shiftMask, 	xK_l), 		sendMessage MirrorExpand)
	, ((modMask .|. shiftMask, 	xK_Return), spawn $ XMonad.terminal conf)
	, ((modMask, xK_space), sendMessage NextLayout)                                              --Rotate through the available layout algorithms
	, ((modMask, xK_v ), sendMessage ToggleLayout) 
	] ++ 
	[ ((m .|. modMask, k), windows $ f i)                                                        --Switch to n workspaces and send client to n workspaces
	  | (i, k) <- zip (XMonad.workspaces conf) ([xK_1 .. xK_9])
	  , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]
	] ++
	[ ((m .|. modMask, key), screenWorkspace sc >>= flip whenJust (windows . f))                 --Switch to n screens and send client to n screens
	  | (key, sc) <- zip [xK_u, xK_i, xK_o] [0..]
	  , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]
	]

-- Mouse bindings
myMouseBindings :: XConfig Layout -> M.Map (KeyMask, Button) (Window -> X ())
myMouseBindings (XConfig {XMonad.modMask = modMask}) = M.fromList $
	[ ((modMask, button1), (\w -> focus w >> mouseMoveWindow w >> windows W.shiftMaster)) --Set the window to floating mode and move by dragging
	, ((modMask, button2), (\w -> focus w >> windows W.shiftMaster))                      --Raise the window to the top of the stack
	, ((modMask, button3), (\w -> focus w >> Flex.mouseResizeWindow w))                   --Set the window to floating mode and resize by dragging
	]

---------------------------------------------------------------------
-- Main cycle
---------------------------------------------------------------------

main = do
	barTL <- spawnPipe $ dzenFlagsToStr dzTLFlags
	barTR <- spawnPipe $ dzenFlagsToStr dzTRFlags
	barBL <- spawnPipe $ dzenFlagsToStr dzBLFlags
	barBR <- spawnPipe $ dzenFlagsToStr dzBRFlags
	xmonad $ defaultConfig
		{ terminal				= "urxvtc"
		, borderWidth 			= 1
		, normalBorderColor		= clBase02
		, focusedBorderColor	= clGreen
		, workspaces            = myWorkspaces
		-- Keybaord & Mouse
		, modMask				= mod4Mask
		, keys 					= myKeys
		, mouseBindings         = myMouseBindings
		-- Hooks
		, manageHook			= myManageHook <+> manageScratchPad <+> manageDocks
		, layoutHook			= myLayoutHook
		, startupHook			= myStartupHook
		, handleEventHook		= myHandleEventHook
		, logHook				= dzBLLogHook barBL <+> dzBRLogHook barBR <+> dzTLLogHook barTL <+> dzTRLogHook barTR  
		}
    
