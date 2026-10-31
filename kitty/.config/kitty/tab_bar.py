# Minimal text tab bar (tab_bar_style custom).
#
# Tabs have no backgrounds or separators: the active tab is drawn in the
# accent colour and bold, the rest are dimmed. Each tab shows its project
# directory (or the name set with ctrl+b ,) plus the foreground program when
# it is not a shell. The right edge shows the active keyboard mode (the ctrl+b
# prefix) and the current session.
#
# Colours come from the active_/inactive_tab_* options set in
# dark-theme.auto.conf and light-theme.auto.conf, so it follows the system theme.

import os
import re

from kitty.fast_data_types import Screen, get_boss, wcswidth
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb
from kitty.utils import color_as_int

SUPERSCRIPT = str.maketrans('0123456789', '⁰¹²³⁴⁵⁶⁷⁸⁹')
SHELLS = {'zsh', 'bash', 'fish', 'sh', 'login'}
VERSION = re.compile(r'^\d+(\.\d+)+$')
HOME = os.path.expanduser('~')

# Session of the active tab, remembered while drawing so the status on the
# right edge (drawn with the last tab) can show it.
active_session = ''


def program_name(path: str) -> str:
    # Versioned installs (~/.local/share/claude/versions/2.1.3) are named after
    # the directory above "versions".
    parts = [p for p in path.split('/') if p]
    while parts and (VERSION.match(parts[-1]) or parts[-1] == 'versions'):
        parts.pop()
    return parts[-1].lstrip('-') if parts else ''


def labels(tab: TabBarData) -> tuple[str, str]:
    """The tab's main label and a dimmed hint."""
    t = get_boss().tab_for_id(tab.tab_id)
    w = t.active_window if t else None
    if w is None:
        return tab.title, ''
    cwd = w.cwd_of_child or ''
    label = t.name or ('~' if cwd == HOME else os.path.basename(cwd)) or tab.title
    procs = w.child.foreground_processes
    cmdline = procs[-1].get('cmdline') if procs else None
    program = program_name(cmdline[0]) if cmdline else ''
    hint = '' if program in SHELLS else program
    return label, hint


def fit(text: str, width: int) -> str:
    if wcswidth(text) <= width:
        return text
    out = ''
    for ch in text:
        if wcswidth(out + ch) >= width:
            break
        out += ch
    return out + '…' if width > 0 else ''


def draw_status(draw_data: DrawData, screen: Screen) -> None:
    accent = as_rgb(color_as_int(draw_data.active_fg))
    dim = as_rgb(color_as_int(draw_data.inactive_fg))
    bar_bg = as_rgb(color_as_int(draw_data.default_bg))
    mode = get_boss().mappings.current_keyboard_mode_name
    mode_text = f' {mode.upper()} ' if mode else ''
    session_text = f'◆ {active_session}' if active_session else ''
    gap = '  ' if mode_text and session_text else ''
    width = wcswidth(mode_text + gap + session_text) + 1
    x = screen.columns - width
    if x <= screen.cursor.x:
        return
    screen.cursor.bg = bar_bg
    screen.draw(' ' * (x - screen.cursor.x))
    if mode_text:
        screen.cursor.bg, screen.cursor.fg, screen.cursor.bold = accent, bar_bg, True
        screen.draw(mode_text)
        screen.cursor.bg, screen.cursor.bold = bar_bg, False
        screen.draw(gap)
    if session_text:
        screen.cursor.fg = dim
        screen.draw(session_text)
    screen.cursor.fg = 0
    screen.draw(' ')


def draw_tab(
    draw_data: DrawData, screen: Screen, tab: TabBarData,
    before: int, max_tab_length: int, index: int, is_last: bool,
    extra_data: ExtraData,
) -> int:
    global active_session
    if tab.is_active:
        active_session = tab.active_session_name or tab.session_name

    accent = as_rgb(color_as_int(draw_data.active_fg))
    dim = as_rgb(color_as_int(draw_data.inactive_fg))
    label, hint = labels(tab)
    number = str(index).translate(SUPERSCRIPT)
    marker = ' ●' if tab.needs_attention else ' •' if tab.has_activity_since_last_focus else ''

    # Fit into max_tab_length: " ¹ label hint marker  "
    room = max_tab_length - wcswidth(f' {number} {marker}  ')
    label = fit(label, room)
    hint = fit(hint, room - wcswidth(label) - 1) if hint else ''

    screen.cursor.bold = screen.cursor.italic = False
    screen.cursor.fg = accent if tab.is_active else dim
    screen.draw(f' {number} ')
    screen.cursor.bold = tab.is_active
    screen.draw(label)
    screen.cursor.bold = False
    if hint:
        screen.cursor.fg = dim
        screen.draw(f' {hint}')
    if marker:
        if tab.needs_attention:
            screen.apply_sgr('31')
        else:
            screen.cursor.fg = accent
        screen.draw(marker)
    screen.cursor.fg = 0
    screen.draw('  ')
    end = screen.cursor.x

    if is_last and not extra_data.for_layout:
        draw_status(draw_data, screen)
    return end
