-- ripples
--
-- water droplet sequencer
-- v0.3 entropybound

engine.name = "Ripples"

-- natural units
deltat = 0.2 -- tick period
c = 5 -- squares per second
k = 1 -- wavelength
t0 = 20
r0 = 5
maxt = 180 -- in seconds
-- drops
dx = {0,0,0,0,0,0,0,0}
dy = {0,0,0,0,0,0,0,0}
dt = {0,0,0,0,0,0,0,0}
dk = {0,0,0,0,0,0,0,0} -- notes
nd = 0
maxd = 6
probd = 0.0
xmax=32
ymax=16
xwid=128/xmax
ywid=64/ymax
-- stones
sx = {0,0,0,0,0,0,0,0}
sy = {0,0,0,0,0,0,0,0}
st = {0,0,0,0,0,0,0,0}
sn = {0,0,0,0,0,0,0,0} -- notes
ss = {0,0,0,0,0,0,0,0} -- state
ns = 0
maxs = 6
vn = 0
px = 3
py = 3

function midi_to_hz(note)
  local hz = (440 / 32) * (2 ^ ((note - 9) / 12))
  return hz
end

function status()
  for id=1,nd do
    print("drop " .. id .. " x=" .. dx[id] .. " y=" .. dy[id] .. " t=" .. dt[id])
  end
  for id=1,ns do
    print("stone " .. id .. " x=" .. sx[id] .. " y=" .. sy[id] .. " t=" .. st[id])
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
  end
  nd = nd-1
end

function push_drop(x, y, t, k)
  nd = nd+1
  if (nd==maxd) then 
    return
  end
  dx[nd] = x
  dy[nd] = y
  dt[nd] = t
  dk[nd] = k
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

function push_stone(x, y, t,n)
  ns = ns+1
  if (ns==maxs) then 
    return
  end
  sx[ns] = x
  sy[ns] = y
  st[ns] = t
  sn[ns] = n
  ss[ns] = 0
  engine.vol(ns,0)
  engine.hz(ns,midi_to_hz(sn[ns]))
  engine.pan_lag(ns,.01)
  engine.amp_atk(ns,0.5)
  engine.amp_rel(ns,1)
end

function amp(i, x, y) -- amplitude at x,y from node i
  local a3
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
      a3 = a1 * a2 * math.cos( dk[i]*(r_max - r) )
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
      amp_tot = 0;
      for id=1,nd do
        amp_tot = amp_tot + amp(id,ix,iy)
      end
      amp_tot = math.min(1,amp_tot)
      level = math.floor(20.99*(1+amp_tot)/2-5)
      screen.level(level)
      screen.fill()
      screen.rect(ix*xwid-xwid/2,iy*ywid-ywid/2,xwid,ywid)
      for is=1,ns do
        if (ix==sx[is] and iy==sy[is]) then
          if (amp_tot>.0) then
            engine.vol(is,amp_tot)
            engine.pan(is,2*(sx[is]/xmax)-1)
          end
        end
      end
      
    end
  end
  
  for is=1,ns do
      screen.level(2)
      screen.move(sx[is]*128/xmax,sy[is]*64/ymax)
      screen.circle(sx[is]*128/xmax,sy[is]*64/ymax,4)
      screen.stroke()
      screen.move(sx[is]*128/xmax,sy[is]*64/ymax)
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
      
  end
  
  --
  screen.update()
end

local function save_project(num)
 
end

local function load_project(num)
 
end

local grid = util.file_exists(_path.code.."midigrid") and include "midigrid/lib/mg_128" or grid
g = grid.connect()
g.key = function(x,y,z)
  -- grid key process
end

function grid_redraw()
  -- grid redraw
end

function key(n,z)
  -- key actions: n = number, z = state
end

function enc(n,d)
  -- encoder actions: n = number, d = delta
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
      erase_drop(id)
    end
  end
  redraw()
end

function init()
-- set up grid
-- set up metronome
-- declare parameters
  counter = metro.init(count,deltat,-1)
  counter:start()
  push_drop(8,2,0,1.3)
  --push_drop(8,9,0,.7)
  push_drop(24,2,0,2)
  --push_drop(20,4,0,2)
  --push_drop(29,5,0,2)
  --push_drop(16,15,0,1)
  
  push_stone(8,8,0,40)
  --push_stone(12,8,0,67)
  --push_stone(16,8,0,69)
  --push_stone(20,8,0,65)
  --push_stone(24,8,0,64)
  --push_stone(28,8,0,76)
end