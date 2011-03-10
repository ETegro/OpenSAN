-- Configuration Bind Interface (CBI)

require("luci.sys")

m = Map("system", "System", "Simple description")
m:chain("luci")

s = m:section(TypedSection, "system", "System Properties")
s.anonymous = true
s.addremove = false

s:tab("general", "General Settings")
s:tab("mount", "Mount Info")

--
-- System Properties
--

local system, model, memtotal, memcached, membuffers, memfree = luci.sys.sysinfo()

s:taboption("general", DummyValue, "_system", "System").value = system
s:taboption("general", DummyValue, "_cpu", "Processor").value = model
s:taboption("general", DummyValue, "_kernel", "Kernel").value = luci.util.exec("uname -r") or "?"

--
-- Mount Info
--

foo = luci.util.exec("mount -i")

s:taboption("mount", DummyValue, "_mount", "Mount line 1").value = luci.util.split(foo, "\n")[1]

return m, t
