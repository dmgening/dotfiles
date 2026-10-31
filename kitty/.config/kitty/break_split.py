# Break the active split out into a new tab to the right, keeping that tab in
# the current kitty session (ctrl+b !).
#
# Plain `detach_window new-tab-right` creates a tab that belongs to no session,
# and the tab bar filter (session:~ or session:^$) then shows it in every
# session.

from kittens.tui.handler import result_handler


def main(args: list[str]) -> str:
    return ''


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss):
    window = boss.window_id_map.get(target_window_id)
    tab = window.tabref() if window else None
    if tab is None or len(tab) < 2:
        return
    session = tab.created_in_session_name
    boss.detach_window('new-tab-right')
    new_tab = window.tabref()
    if new_tab is not None and new_tab is not tab:
        new_tab.created_in_session_name = session
        new_tab.mark_tab_bar_dirty()
