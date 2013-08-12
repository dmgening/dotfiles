-- ------------------------------------------------------------------
-- Imports
-- ------------------------------------------------------------------
import XMonad

-- Layout
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

-- ------------------------------------------------------------------
-- Look & Feel
-- ------------------------------------------------------------------

myFont		= "xft:Droid Sans Mono:pixelsize=12"

-- Ethan Schoonover "Solarized" Theme
clBase03    = "#002b36"
clBase02    = "#073642"
clBase01    = "#586e75"
clBase00    = "#657b83"
clBase0     = "#839496"
clBase1     = "#93a1a1"
clBase2     = "#eee8d5"
clBase3     = "#fdf6e3"
clYellow    = "#b58900"
clOrange    = "#cb4b16"
clRed       = "#dc322f"
clMagenta   = "#d33682"
clViolet    = "#6c71c4"
clBlue      = "#268bd2"
clCyan      = "#2aa198"
clGreen     = "#859900"

dockHeigth = 20
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

-- ------------------------------------------------------------------
-- Workspaces
-- ------------------------------------------------------------------

myWorkspaces = clickable $ ["I","II","III","IV","V","VI","VII"] 
	where clickable l = [ "^ca(1,xdotool key meta+" ++ show (n) ++ ")" ++ ws ++ "^ca()" |
		(i,ws) <- zip [1..] l, 
		let n = i ]

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
		myCodeS			= ["subl3","emacs"]



---------------------------------------------------------------------
-- Other Hooks
---------------------------------------------------------------------

myStartupHook = do
	setDefaultCursor xC_left_ptr
	spawn "urxvtd"
	setWMName "LG3D"

---------------------------------------------------------------------
-- Keyboard & Mouse
---------------------------------------------------------------------

myKeys :: XConfig Layout -> M.Map (KeyMask, KeySym) (X ())
myKeys conf@(XConfig {XMonad.modMask = modMask}) = M.fromList $
	[ ((modMask .|. shiftMask, 	xK_q), 		io (exitWith ExitSuccess))
	, ((modMask, 				xK_q), 		restart "xmonad" True)

	, ((modMask,				xK_r),		shellPrompt myXPConfig)
	, ((modMask .|. shiftMask,	xK_r),		manPrompt myXPConfig)
	
	, ((modMask .|. shiftMask,	xK_c),		kill)
	, ((modMask .|. shiftMask, 	xK_Return), spawn $ XMonad.terminal conf)
	] ++ 
	[ ((m .|. modMask, k), windows $ f i)                                                        --Switch to n workspaces and send client to n workspaces
	  | (i, k) <- zip (XMonad.workspaces conf) ([xK_1 .. xK_9])
	  , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]
	]

---------------------------------------------------------------------
-- Main cycle
---------------------------------------------------------------------

main = do
	xmonad $ defaultConfig
		{ terminal				= "urxvtc"
		, borderWidth 			= 1
		, normalBorderColor		= clBase02
		, focusedBorderColor	= clGreen
		-- Keybaord & Mouse
		, modMask				= mod4Mask
		, keys 					= myKeys
		-- Hooks
		, manageHook			= myManageHook <+> manageScratchPad <+> manageDocks
		--, layoutHook			= myLayoutHook
		, startupHook			= myStartupHook
		--, handleEventHook		= myHandleEventHook
		--, logHook				= myLogHook
		}
    
