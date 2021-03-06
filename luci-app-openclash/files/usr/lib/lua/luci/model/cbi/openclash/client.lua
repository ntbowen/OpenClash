
local NXFS = require "nixio.fs"
local SYS  = require "luci.sys"
local HTTP = require "luci.http"
local DISP = require "luci.dispatcher"
local UTIL = require "luci.util"
local fs = require "luci.openclash"
local uci = require("luci.model.uci").cursor()

m = Map("openclash")
m.title = translate("OpenClash")
m.description = translate("A Clash Client For OpenWrt")
m.pageaction = false

m:section(SimpleSection).template  = "openclash/status"
m:section(SimpleSection).template  = "openclash/state"

local e,a={}
for t,o in ipairs(fs.glob("/etc/openclash/config/*"))do
a=fs.stat(o)
if a then
e[t]={}
e[t].name=fs.basename(o)
BACKUP_FILE="/etc/openclash/backup/".. e[t].name
e[t].mtime=os.date("%Y-%m-%d %H:%M:%S",fs.mtime(BACKUP_FILE)) or os.date("%Y-%m-%d %H:%M:%S",a.mtime)
if string.sub(luci.sys.exec("uci get openclash.config.config_path"), 23, -2) == e[t].name then
   e[t].state=translate("Enable")
else
   e[t].state=translate("Disable")
end
e[t].size=tostring(a.size)
e[t].remove=0
e[t].enable=false
end
end

form=SimpleForm("filelist")
form.reset=false
form.submit=false
tb=form:section(Table,e)
st=tb:option(DummyValue,"state",translate("State"))
nm=tb:option(DummyValue,"name",translate("File Name"))
mt=tb:option(DummyValue,"mtime",translate("Update Time"))

function IsYamlFile(e)
e=e or""
local e=string.lower(string.sub(e,-5,-1))
return e==".yaml"
end

btnis=tb:option(Button,"switch",translate("Switch Config"))
btnis.template="openclash/other_button"
btnis.render=function(o,t,a)
if not e[t]then return false end
if IsYamlFile(e[t].name)then
a.display=""
else
a.display="none"
end
o.inputstyle="apply"
Button.render(o,t,a)
end
btnis.write=function(a,t)
luci.sys.exec(string.format('uci set openclash.config.config_path="/etc/openclash/config/%s"',e[t].name))
uci:commit("openclash")
end

s = Map("openclash")
s.pageaction = false
s:section(SimpleSection).template  = "openclash/myip"

local t = {
    {enable, disable}
}

ap = SimpleForm("apply")
ap.reset = false
ap.submit = false
ss = ap:section(Table, t)

o = ss:option(Button, "enable") 
o.inputtitle = translate("Enable Clash")
o.inputstyle = "apply"
o.write = function()
  uci:set("openclash", "config", "enable", 1)
  uci:commit("openclash")
  SYS.call("/etc/init.d/openclash restart >/dev/null 2>&1 &")
end

o = ss:option(Button, "disable")
o.inputtitle = translate("Disable Clash")
o.inputstyle = "reset"
o.write = function()
  uci:set("openclash", "config", "enable", 0)
  uci:commit("openclash")
  SYS.call("/etc/init.d/openclash stop >/dev/null 2>&1 &")
end

d = Map("openclash")
d.title = translate("Technical Support")
d.pageaction = false
d:section(SimpleSection).template  = "openclash/developer"

return m, form, s, ap, d
