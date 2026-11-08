local settings = require("settings")
local load_graph = require("items_left.widgets.load_graph")

-- Three load graph cells: cpu, gpu, memory (cpu at the bottom).

-- Execute the event provider binary which provides the event "cpu_update" for
-- the cpu load data, which is fired every 2.0 seconds.
sbar.exec("killall cpu_load >/dev/null; $CONFIG_DIR/helpers/event_providers/cpu_load/bin/cpu_load cpu_update 2.0")

local cpu, cpu_update = load_graph("cpu", { name = "CPU" })
cpu:subscribe("cpu_update", function(env)
  -- Also available: env.user_load, env.sys_load
  cpu_update(tonumber(env.total_load))
end)

load_graph("gpu", {
  name = "GPU",
  command = [[ioreg -r -c IOAccelerator | grep -o '"Device Utilization %"=[0-9]*' | head -1 | cut -d= -f2]],
})

-- Used = app (anonymous - purgeable) + wired + compressed, like Activity Monitor;
-- graph and colors follow used %, the label shows GB available (total - used)
load_graph("memory", {
  name = "MEM",
  levels = { 60, 75, 90 },
  command = [[vm_stat | awk -v m="$(sysctl -n hw.memsize)" '/page size of/ {ps = $8} /^Anonymous/ {a = $3} /purgeable/ {p = $3} /wired/ {w = $4} /occupied by compressor/ {c = $5} END {u = (a - p + w + c) * ps; f = (m - u) / 2^30; printf (f < 10 ? "%d %.1fG" : "%d %.0fG"), u * 100 / m, f}']],
})

sbar.add("item", "widgets.cpu.padding", {
  position = "right",
  width = settings.group_paddings
})
