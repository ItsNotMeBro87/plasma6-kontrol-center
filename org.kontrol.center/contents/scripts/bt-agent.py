#!/usr/bin/env python3
"""Kontrol Center Bluetooth pairing agent.

Runs only while the Bluetooth page of the widget is open (bt.sh agent-start / agent-stop). It registers itself with
BlueZ as the default agent, so pairing requests (a device wants to pair with this PC, or this PC pairs with a device
and a code has to be compared) are shown in the widget instead of in a desktop notification. The widget and this
agent talk through small files in ~/.cache/kontrol-center:
    bt-request   "kind|hex(name)|code"   written by the agent   (kind: confirm, authorize, pin, passkey, show)
    bt-answer    "yes|text" or "no|"      written by `bt.sh answer`
    bt-alive     touched by `bt.sh list`; when it goes stale (widget closed or crashed) the agent quits by itself
When the agent is not running, KDE's own Bluetooth agent handles pairing as usual.
"""
import os
import signal
import sys
import time

try:
    from gi.repository import Gio, GLib
except Exception:
    sys.exit(3)

CACHE = os.path.join(os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")), "kontrol-center")
REQ = os.path.join(CACHE, "bt-request")
ANS = os.path.join(CACHE, "bt-answer")
ALIVE = os.path.join(CACHE, "bt-alive")
AGENT_PATH = "/org/kontrolcenter/agent"
TIMEOUT = 60

XML = """<node><interface name="org.bluez.Agent1">
<method name="Release"/>
<method name="RequestPinCode"><arg type="o" direction="in"/><arg type="s" direction="out"/></method>
<method name="DisplayPinCode"><arg type="o" direction="in"/><arg type="s" direction="in"/></method>
<method name="RequestPasskey"><arg type="o" direction="in"/><arg type="u" direction="out"/></method>
<method name="DisplayPasskey"><arg type="o" direction="in"/><arg type="u" direction="in"/><arg type="q" direction="in"/></method>
<method name="RequestConfirmation"><arg type="o" direction="in"/><arg type="u" direction="in"/></method>
<method name="RequestAuthorization"><arg type="o" direction="in"/></method>
<method name="AuthorizeService"><arg type="o" direction="in"/><arg type="s" direction="in"/></method>
<method name="Cancel"/>
</interface></node>"""

os.makedirs(CACHE, exist_ok=True)
bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
loop = GLib.MainLoop()
pending = None       # {"inv", "kind", "deadline"}
show_until = 0.0


def hexs(s):
    return s.encode("utf-8").hex()


def remove(path):
    try:
        os.remove(path)
    except OSError:
        pass


def get_prop(path, prop):
    try:
        r = bus.call_sync("org.bluez", path, "org.freedesktop.DBus.Properties", "Get",
                          GLib.Variant("(ss)", ("org.bluez.Device1", prop)), GLib.VariantType("(v)"),
                          Gio.DBusCallFlags.NONE, 2000, None)
        return r.unpack()[0]
    except Exception:
        return None


def dev_name(path):
    n = get_prop(path, "Alias") or get_prop(path, "Name")
    if n:
        return str(n)
    return path.split("/")[-1].replace("dev_", "").replace("_", ":")


def post(kind, path, code=""):
    with open(REQ, "w") as f:
        f.write("%s|%s|%s" % (kind, hexs(dev_name(path)), code))


def finish(accept, text=""):
    global pending
    p, pending = pending, None
    if not p:
        return
    inv, kind = p["inv"], p["kind"]
    try:
        if kind in ("confirm", "authorize"):
            if accept:
                inv.return_value(None)
            else:
                inv.return_dbus_error("org.bluez.Error.Rejected", "Rejected")
        elif kind == "pin":
            if accept and text:
                inv.return_value(GLib.Variant("(s)", (text,)))
            else:
                inv.return_dbus_error("org.bluez.Error.Rejected", "Rejected")
        elif kind == "passkey":
            if accept and text.isdigit():
                inv.return_value(GLib.Variant("(u)", (int(text),)))
            else:
                inv.return_dbus_error("org.bluez.Error.Rejected", "Rejected")
    except Exception:
        pass
    remove(REQ)


def ask(kind, path, inv, code=""):
    global pending
    if pending:
        finish(False)
    remove(ANS)
    pending = {"inv": inv, "kind": kind, "deadline": time.time() + TIMEOUT}
    post(kind, path, code)


def on_call(conn, sender, obj_path, iface, method, params, inv):
    global show_until
    args = params.unpack()
    if method in ("Release", "Cancel"):
        if pending:
            finish(False)
        remove(REQ)
        inv.return_value(None)
        if method == "Release":
            loop.quit()
    elif method == "DisplayPasskey":
        post("show", args[0], "%06d" % args[1])
        show_until = time.time() + 45
        inv.return_value(None)
    elif method == "DisplayPinCode":
        post("show", args[0], str(args[1]))
        show_until = time.time() + 45
        inv.return_value(None)
    elif method == "RequestConfirmation":
        ask("confirm", args[0], inv, "%06d" % args[1])
    elif method == "RequestAuthorization":
        ask("authorize", args[0], inv)
    elif method == "AuthorizeService":
        if get_prop(args[0], "Paired") or get_prop(args[0], "Trusted"):
            inv.return_value(None)      # an already paired / trusted device may use its services
        else:
            ask("authorize", args[0], inv)
    elif method == "RequestPinCode":
        ask("pin", args[0], inv)
    elif method == "RequestPasskey":
        ask("passkey", args[0], inv)
    else:
        inv.return_dbus_error("org.bluez.Error.Rejected", "Unsupported")


def tick():
    global show_until
    now = time.time()
    # the widget stopped asking for status: quit
    try:
        if now - os.path.getmtime(ALIVE) > 25:
            loop.quit()
            return False
    except OSError:
        loop.quit()
        return False
    if pending:
        try:
            with open(ANS) as f:
                ans = f.read().strip()
            remove(ANS)
            yes, _, text = ans.partition("|")
            finish(yes == "yes", text)
        except OSError:
            if now > pending["deadline"]:
                finish(False)
    elif show_until and now > show_until:
        show_until = 0.0
        remove(REQ)
    return True


node = Gio.DBusNodeInfo.new_for_xml(XML)
bus.register_object(AGENT_PATH, node.interfaces[0], on_call, None, None)
try:
    bus.call_sync("org.bluez", "/org/bluez", "org.bluez.AgentManager1", "RegisterAgent",
                  GLib.Variant("(os)", (AGENT_PATH, "KeyboardDisplay")), None, Gio.DBusCallFlags.NONE, 3000, None)
    bus.call_sync("org.bluez", "/org/bluez", "org.bluez.AgentManager1", "RequestDefaultAgent",
                  GLib.Variant("(o)", (AGENT_PATH,)), None, Gio.DBusCallFlags.NONE, 3000, None)
except Exception:
    sys.exit(4)

GLib.timeout_add(300, tick)
GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGTERM, loop.quit)
GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGINT, loop.quit)
try:
    loop.run()
finally:
    try:
        if pending:
            finish(False)
        bus.call_sync("org.bluez", "/org/bluez", "org.bluez.AgentManager1", "UnregisterAgent",
                      GLib.Variant("(o)", (AGENT_PATH,)), None, Gio.DBusCallFlags.NONE, 2000, None)
    except Exception:
        pass
    remove(REQ)
    remove(ANS)
