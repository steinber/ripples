-- ripples
--
-- water droplet sequencer
-- v0.5 entropybound

engine.name = "Ripples"

-- natural units
deltat = 0.2 -- tick period
c = 8 -- squares per second
k = 1 -- wavelength
t0 = 20
r0 = 5
maxt = 300  -- in seconds
-- drops
dx = {0,0,0,0,0,0,0,0}
dy = {0,0,0,0,0,0,0,0}
dt = {0,0,0,0,0,0,0,0}
dk = {0,0,0,0,0,0,0,0} -- notes
df = {0,0,0,0,0,0,0,0} -- functions
local nd = 0
local maxd = 6
local probd = 0.0
local xmax=32
local ymax=16
local xwid=128/xmax
local ywid=64/ymax
-- stones
sx = {0,0,0,0,0,0,0,0}
sy = {0,0,0,0,0,0,0,0}
st = {0,0,0,0,0,0,0,0} -- need role for "time"
sn = {0,0,0,0,0,0,0,0} -- notes
ss = {0,0,0,0,0,0,0,0} -- state
local ns = 0
maxs = 6
local vn = 0
local px = 0 -- probability (in %) of a motion in x
local py = 0 -- probability (in %) of motion in y
local stone_drop_mode = 0 -- 0 is for modifying stones, 1 is for modifying drops

local stone_sel = 0 -- selected stone ID
local stone_param = 1
local stone_param_max = 4 -- x,y,n,s
stone_param_names = {"x","y","n","s"}
local sval=0

local drop_sel = 0 -- selected drop ID
local drop_param = 1
local drop_param_max = 5 -- x,y,t,k,f
drop_param_names = {"x","y","t","k","f"}
local dval=0
local dmax_fun = 2

function midi_to_hz(note)
  local hz = (440 / 32) * (2 ^ ((note - 9) / 12))
  return hz
end

function status()
  if (stone_drop_mode==0) then
    print("stone mode, stone_sel="..stone_sel)
  else
    print("drop mode, drop_sel="..drop_sel)
  end

  for id=1,nd do
    print("drop " .. id .. " x=" .. dx[id] .. " y=" .. dy[id] .. " t=" .. dt[id])
  end
  
  for id=1,ns do
    print("stone " .. id .. " x=" .. sx[id] .. " y=" .. sy[id] .. " n=" .. sn[id])
  end
  
end

function erase_drop(i)
  if (i>nd) then 
    return
  end
  
  for id=i,nd do
    dx[id-1]=dx[id]
    dy[id-1]=dy[id]
    dt[id-1]=dt[id]
    dk[id-1]=dk[id]
    df[id-1]=df[id]
  end
  nd = nd-1
end

function push_drop(x, y, t, k, f)
  nd = nd+1
  if (nd==maxd) then 
    return
  end
  dx[nd] = x
  dy[nd] = y
  dt[nd] = t
  dk[nd] = k
  df[nd] = f
end

function erase_stone(i)
  if (i>ns) then 
    return
  end
  
  for is=i,ns do
    sx[is-1]=sx[is]
    sy[is-1]=sy[is]
    st[is-1]=st[is]
    sn[is-1]=sn[is]
    ss[is-1]=ss[is]
  end
  ns = ns-1
end

function saw(x)
  local r = 0
  x2 = math.fmod(x,2*math.pi)  
  if (x2>0 and x2<math.pi) then
    r = -x2/math.pi
  elseif (x2>math.pi and x2<2*math.pi) then
    r = (2-x/math.pi)
  end
  return (r+1)/2
end

function push_stone(x, y, t,n,s)
  ns = ns+1
  if (ns==maxs) then 
    return
  end
  sx[ns] = x
  sy[ns] = y
  st[ns] = t
  sn[ns] = n
  ss[ns] = s
  engine.vol(ns,.1)
  engine.hz(ns,midi_to_hz(sn[ns]))
  engine.pan_lag(ns,.1)
  engine.vol_lag(ns,.2)
  --engine.fm_index(ns,ns)
  --engine.amp_atk(ns,0.5)
  --engine.amp_rel(ns,1)
end

function amp(i, x, y) -- amplitude at x,y from node i
  local a3 = 0
  if (dx[i]==x and dy[i]==y) then
      a3 = 0.8+0.2*math.cos(dt[i])
  else
    r = math.sqrt( ((x-dx[i])^2)+((y-dy[i])^2) )
    r_max = c*dt[i]*deltat
    if (r>r_max) then
      a3=0
    else
      a1 = math.exp(-(dt[i]*deltat)/t0)
      a2 = math.exp(-r/r0)
      if (df[i]==1) then
        a3 = a1 * a2 * math.cos( dk[i]*(r_max - r) )
      elseif (df[i]==2) then
        a3 = a1 * a2 * saw(dk[i]*(r_max - r))
      end
    end
  end
  return a3
end

function redraw()
  --

  screen.clear()
  --
  for ix=1,xmax do
    for iy=1,ymax do

      -- calculate total amplitude 
      amp_tot = 0;
      for id=1,nd do
        amp_tot = amp_tot + amp(id,ix,iy)
      end

      amp_tot = math.min(1,amp_tot)
      amp_tot = math.max(-1,amp_tot)
      
      -- translate to brightness level
      level = math.floor(21*(1+amp_tot)/2-7)
      level = math.max(0,level)

      if (ix==dx[id] and iy==dy[id]) then
        if (id==drop_sel) then
          level = 15
        else
          level = 0
        end
      end        

      screen.level(level)

      -- fill rectangle
      screen.rect((ix-0.5)*xwid,(iy-0.5)*ywid,xwid,ywid)
      screen.fill()

      for is=1,ns do
        if (ix==sx[is] and iy==sy[is]) then
          engine.vol(is,math.max(amp_tot,0))
          engine.pan(is,2*(sx[is]/xmax)-1)
        end
      end
    end
  end
  
  for is=1,ns do
      screen.level(2)
      if (is==stone_sel) then
        screen.level(13)
      end
      screen.move(sx[is]*128/xmax,sy[is]*64/ymax)
      screen.circle(sx[is]*128/xmax,sy[is]*64/ymax,xwid)
      screen.fill()
      screen.move(sx[is]*128/xmax-xwid/2,sy[is]*64/ymax-ywid/2)
      screen.level(15)
      screen.text("n"..sn[is])
      if (math.random(0,100)<px) then
        if (math.random(0,100)<51) then
          sx[is] = sx[is]+1 
        else
          sx[is] = sx[is]-1
        end
      end
      if (math.random(0,100)<py) then
        if (math.random(0,100)<51) then
          sy[is] = sy[is]+1 
        else
          sy[is] = sy[is]-1
        end
      end
      
      screen.move(70,60)
      screen.text("d:"..drop_param_names[drop_param].."["..drop_sel.."]:"..string.format("%.1f",dval))

      screen.move(10,60)
      screen.text("s:"..stone_param_names[stone_param].."["..stone_sel.."]:"..string.format("%.1f",sval))
  end
  
  --
  screen.update()
end

local function save_project(num)
 
end

local function load_project(num)
 
end

--local grid = util.file_exists(_path.code.."midigrid") and include "midigrid/lib/mg_128" or grid
g = grid.connect()
g.key = function(x,y,z)
  -- grid key process
end

function grid_redraw()
  -- grid redraw
end

function key(n,z)
  -- key actions: n = number, z = state
  --print("key n="..n.." z="..z)
  if (n==2 and z==1) then
    if (stone_drop_mode==1) then
      stone_drop_mode=0
    else
      stone_sel = stone_sel+1
      if (stone_sel>ns) then
        stone_sel=1
      end
    end
    change_stone_param(stone_param,0)
  end
  
  if (n==3 and z==1) then
    if (stone_drop_mode==0) then
      stone_drop_mode=1 -- go to drop mode
    else
      drop_sel = drop_sel+1
      if (drop_sel>nd) then
        drop_sel=1
      end
    end
    change_drop_param(stone_param,0)
  end
  
  if (n==1) then
    if (stone_drop_mode==0) then
      push_stone(xmax/2,ymax/2,0,64)
    else
      push_drop(xmax/2,ymax/2,0,1)
    end
  end
  
end

function change_drop_param(n,p)
  if (n==1) then 
    dx[drop_sel] = dx[drop_sel] + p
    dval = dx[drop_sel]
  elseif (n==2) then 
    dy[drop_sel] = dy[drop_sel] + p
    dval = dy[drop_sel]
  elseif (n==3) then 
    dt[drop_sel] = dt[drop_sel] + p
    dval = dt[drop_sel]
  elseif (n==4) then 
    dk[drop_sel] = dk[drop_sel] + 0.1*p
    dval = dk[drop_sel]  
  elseif (n==5) then 
    df[drop_sel] = df[drop_sel] + p
    df[drop_sel] = math.min(dmax_fun,df[drop_sel])
    df[drop_sel] = math.max(1,df[drop_sel])
    dval = dk[drop_sel]
  else  
    print("what?")
  end
end

function change_stone_param(n,p)
  if (n==1) then 
    sx[stone_sel] = sx[stone_sel] + p
    sval = sx[stone_sel]
  elseif (n==2) then 
    sy[stone_sel] = sy[stone_sel] + p
    sval = sy[stone_sel]
  elseif (n==3) then 
    sn[stone_sel] = sn[stone_sel] + p
    sval = sn[stone_sel]
    engine.hz(stone_sel,midi_to_hz(sn[stone_sel]))
  elseif (n==4) then 
    ss[stone_sel] = ss[stone_sel] + p
    sval = ss[stone_sel]
    engine.fm_index(stone_sel,midi_to_hz(ss[stone_sel]))
  else  
    print("what?")
  end
end

function enc(n,d)
  -- encoder actions: n = number, d = delta
  if (n==2) then
    if (stone_drop_mode==0) then -- stone mode
      stone_param = stone_param + d
      if (stone_param>stone_param_max) then
        stone_param = stone_param - stone_param_max
      end
      if (stone_param<1) then
          stone_param = stone_param + stone_param_max
      end
      change_stone_param(stone_param,0) -- used to update display
    else -- drop mode
      drop_param = drop_param + d
      if (drop_param>drop_param_max) then
        drop_param = drop_param - drop_param_max
      end
      if (drop_param<1) then
        drop_param = drop_param + drop_param_max
      end
      change_drop_param(drop_param,0) -- used to update display
    end
  end

  if (n==3) then
    if (stone_drop_mode==0) then -- stone mode
      change_stone_param(stone_param,d)
    else -- drop mode
      change_drop_param(drop_param,d)
    end
  end

end

cleanup = function()
  --save_project(project)
end

function count()
  for id=1,nd do
    dt[id] = dt[id]+deltat -- increment time
  end
  --
  for id=1,nd do
    if (dt[id]>maxt) then
      dt[id]=0 -- reset drop
    end
  end
  redraw()
end

function update()
  change_drop_param(drop_param,0)
  change_stone_param(stone_param,0)
end

function init()
-- set up grid
-- set up metronome
-- declare parameters

  counter = metro.init(count,deltat,-1)
  counter:start()

  --update_count = metro.init(update,2-1)
  --update_count:start()
  
  push_drop(8,2,0,1,1)
  --push_drop(8,9,0,.7)
  push_drop(24,7,0,.6,1)
  push_drop(16,15,-2,1,1)
  --push_drop(20,4,0,2)
  --push_drop(29,5,0,2)
  --push_drop(16,15,0,1)
  
  --push_stone(10,8,0,59)  
  --push_stone(24,8,0,64)
  push_stone(4,14,0,64,3)
  push_stone(10,10,0,67,2)
  push_stone(16,6,0,40,1)
  push_stone(22,10,0,65,4)
  push_stone(28,14,0,76,5)

  if (ns>0) then 
    stone_sel = 1
    change_stone_param(1,0)
  end
  
  if (nd>0) then
    drop_sel = 1
    change_drop_param(1,0)
  end
  
end