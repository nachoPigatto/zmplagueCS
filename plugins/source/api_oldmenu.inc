// api_oldmenu.inc - old-style KEYSMENU wrapper
// All menus are shown with title "oldmenuhandler" so key presses
// route through a single dispatcher that translates 0-indexed -> display key.

new g_oldmenu_body[2048]
new g_oldmenu_keys
new g_oldmenu_name[64]
new g_oldmenu_items[10][2]
new g_oldmenu_itemcount
new g_oldmenu_page[33]
new g_oldmenu_current[33][64]   // which menu is open per player
new g_oldmenu_pitems[33][10][2] // per-player stored item key/value pairs
new g_oldmenu_pitemcount[33]    // per-player item count
new g_oldmenu_handler_name[] = "oldmenuhandler"

stock oldmenu_create(const menuid[], const fmt[], any:...) {
    copy(g_oldmenu_name, 63, menuid);
    new args[192];
    vformat(args, 191, fmt, 3);
    g_oldmenu_body[0] = EOS;
    g_oldmenu_keys = 0;
    g_oldmenu_itemcount = 0;
    format(g_oldmenu_body, 2047, "%s^n", args);
}

stock oldmenu_additem(key, value, const fmt[], any:...) {
    new line[128];
    vformat(line, 127, fmt, 4);
    add(g_oldmenu_body, 2047, line);
    add(g_oldmenu_body, 2047, "^n");
    if(key >= 0 && key <= 9) {
        g_oldmenu_keys |= (1 << (key == 0 ? 9 : key - 1));
        g_oldmenu_items[g_oldmenu_itemcount][0] = key;
        g_oldmenu_items[g_oldmenu_itemcount][1] = value;
        g_oldmenu_itemcount++;
    }
}

// Saves per-player item snapshot so value lookups survive concurrent menu opens.
stock oldmenu_display(id, page = 0, timeout = -1) {
    g_oldmenu_page[id] = page;
    copy(g_oldmenu_current[id], 63, g_oldmenu_name);
    g_oldmenu_pitemcount[id] = g_oldmenu_itemcount;
    for(new i = 0; i < g_oldmenu_itemcount; i++) {
        g_oldmenu_pitems[id][i][0] = g_oldmenu_items[i][0];
        g_oldmenu_pitems[id][i][1] = g_oldmenu_items[i][1];
    }
    show_menu(id, g_oldmenu_keys, g_oldmenu_body, timeout, g_oldmenu_handler_name);
}

// Returns the value stored for the given display key, or -1 if not found.
stock oldmenu_getvalue(id, key) {
    for(new i = 0; i < g_oldmenu_pitemcount[id]; i++) {
        if(g_oldmenu_pitems[id][i][0] == key)
            return g_oldmenu_pitems[id][i][1];
    }
    return -1;
}

stock oldmenu_calculate_pages(&maxpages, &start, &end, page, total) {
    new items_per_page = 7;
    maxpages = (total + items_per_page - 1) / items_per_page;
    if(maxpages < 1) maxpages = 1;
    if(page < 1) page = 1;
    if(page > maxpages) page = maxpages;
    start = (page - 1) * items_per_page;
    end = start + items_per_page;
    if(end > total) end = total;
}
