pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--a retro demake of satisfactory
--by devon grandahl

--game manager + utils
frame = 0
seed = rnd(100)
--dbg = {} -- debug tools

function _init()
 srand(seed)
 music()
 _init_tile_types()
 _init_grid()
 _init_items()
 _init_recipes()
 _init_goals()
 start_fade()
end

function _update()
	_update_grid()
 _update_cursor()
 _update_extras()
 _update_ui()
	_update_fx()
 frame = wrap(frame, 1, 0, 3000)
end

function _draw()
 cls()
 map()
 screen_shake()
 _draw_grid()
 _draw_pwr_lines()
 _draw_cursor()
 _draw_animals()
 _draw_fx()
 _draw_ui()
 fade()
end

function wrap(val, inc, min_val, max_val)
 val += inc
 if (val > max_val) val = min_val
 if (val < min_val) val = max_val
	return val
end

--toggles between f1 and f2 by t
function tick(f1, f2, t)
 return (frame / 30) % t > (t/2) and f1 or f2
end

--ticks to f2 after seconds
function tick_wait(f1, f2, t, by_frames)
 timer = by_frames and frame or frame / 30
 return timer % t == 0 and f2 or f1
end

function shake(amt)
 offset = amt;
end

offset = 0
function screen_shake()
  local fade = 0.91
  local offset_x=16-rnd(32)
  local offset_y=16-rnd(32)
  offset_x*=offset
  offset_y*=offset
  
  camera(offset_x,offset_y)
  offset*=fade
  if offset<0.05 then
    offset=0
  end
end

fade_dir = 0
fade_index = 0
fade_patterns = {
 0b0000000000000000.1,
 0b1000100010001000.1,
 0b1100110011001100.1,
 0b1110111011101110.1,
}
function fade()
 if fade_dir != 0 then
  fade_index += (frame % 3 == 0) and fade_dir or 0
    
  if fade_patterns[fade_index] == nil then
   fade_dir = 0
   return
  end
  
  fillp(fade_patterns[fade_index])
  rectfill(0, 0, 128, 128, 1)
  fillp()
  menu.grace = 10
 end
end

function start_fade()
 fade_dir =  1
 fade_index = 1
end

function find_name(tbl, n)
 for i in all(tbl) do
  if i.name != nil and i.name == n then
   return i
  end
 end
end

function lighten(c)
 lighten_map = {
  1, 13, 8, 11, 15, 13, 7, 7, 14, 10, 7, 6, 6, 14, 6, 7
 }
 
 return lighten_map[c+1]
end

function dir_offset(d)
 if d == "⬆️" then
  return 0, -1
 elseif d == "⬇️" then
 	return 0, 1
 elseif d == "⬅️" then
  return -1, 0
 elseif d == "➡️" then
  return 1, 0
 end
end

function inv_dir(d)
 if d == "⬆️" then
  return "⬇️"
 elseif d == "⬇️" then
 	return "⬆️"
 elseif d == "⬅️" then
  return "➡️"
 elseif d == "➡️" then
  return "⬅️"
 end
 return nil
end

function dist(c1, c2)
 return sqrt( ((c2.x - c1.x)^2) + ((c2.y - c1.y)^2))
end

--[[ debug tools

function dbg.p(i)
 cls()
 if type(i) == "table" then
  dbg.p_tbl(i)
 else
  print(i, 0, 0, 8)
  print("", 0, 6)
 end
 stop()
end

function dbg.p_tbl(tbl)
 y = 6
 print("--table--", 0, 0, 8)
 for k,v in pairs(tbl) do
  if type(v) == "table" then
   print(k..": table("..#v..")", 0, y, 8)
  elseif type(v) == "boolean" then
  	print(k..": "..(v and "true" or "false"), 0, y, 8)
  elseif type(v) == "function" then
  	print(k..": func()", 0, y, 8)
  else
   print(k..": "..v, 0, y, 8)
  end
  y += 6
 end
 
 print("", 0, y, 8)
end

--]]

-->8
-- cursor
crs = {
 x=7,
 y=7,
 drawing=false
}
crs.spr = 1

draw_nodes = {}
last_node = {}
_cell = {}

--custom btnp delay
poke(0x05f5c, 8)
poke(0x05f5d, 4)

function _update_cursor()
 if menu.active == nil and menu.grace == 0 then
		cursor_input()
	end
	_cell = get_cell()
	--animation
	crs.spr = crs.drawing and tick(4, 5, .5) or tick(1, 2, .75)
end

function _draw_cursor()
 spr(crs.spr, 
  crs.x * grid.cell_size, 
  crs.y * grid.cell_size
 )
end

function cursor_input()
 d = nil
 if btnp(⬅️) then
		crs.x = mid(0, crs.x - 1,  grid.size - 1)
	 d = "⬅️"
	end
	if btnp(➡️) then
	 crs.x = mid(0, crs.x +  1,  grid.size - 1)
	 d = "➡️"
	end
	if btnp(⬇️) then
  crs.y = mid(0, crs.y +  1,  grid.size - 1)
	 d = "⬇️"
	end
	if btnp(⬆️) then
	 crs.y = mid(0, crs.y - 1,  grid.size - 1)
	 d = "⬆️"
	end
	
	if btn(❎) == false and crs.drawing then
	 end_drawing()
	end
	
	if crs.drawing == false then
		--hit
		if btnp(🅾️) then
		 if #_cell.inv == 0 and #_cell.outbox == 0 then
				do_cell_action()
			else
			 x, y = get_coords()
			 new_float_text(x, y, "+ "..summarize_inv(_cell))
			 inv_add_all(_cell.inv)
			 inv_add_all(_cell.outbox)
			 _cell.inv = {}
			 _cell.outbox = {}
			 sfx(21)
			end
		end
		
		--select
		if btnp(❎) then
		 if _cell.tile.name == "space elevator" then
		  open_menu("elevator")
		 else
				open_menu("context")
		 end
		end
		
	elseif d != nil then
	 add_draw_node(d)
	end
	
end

function start_drawing(name)
 crs.drawing = true
 draw_nodes = {}
 menu.active = nil
 add_draw_node(nil)
end

function end_drawing()
 crs.drawing = false
 if last_node != nil and #draw_nodes > 0 and _cell.tile.invuln != true then
  n = draw_nodes[#draw_nodes]
  n.d_out = get_bld_nbr(_cell) or n.d_out
 
		build_belt(n)
 end
 
 draw_nodes = {}
end

function add_draw_node(dir_in)
 if last_node != nil then
  last_node.d_out = dir_in
 end
 
 -- first node should look at neighbors
 if dir_in == nil then
  dir_in = inv_dir(get_bld_nbr(_cell))
 end
 
 local dir_out = dir_in
 last_node = add(draw_nodes, 
  { 
   x = crs.x,
   y = crs.y,
   d_in = dir_in,
   d_out = dir_out,
  })
  
 if #draw_nodes > 0 then
	 for node in all(draw_nodes) do
		 build_belt(node)
	 end
 end
end



-->8
-- grid
grid = {
 cell_size=8,
 size=16,
 data={}
}

belt_frame = 1

function _init_grid()
 valid_res_spots = {}
 
 for i=1,grid.size,1 do
  for j=1, grid.size,1 do
  	t=rnd_tile_nat()
  	if fget(mget(i - 1, j-1), 0) then
  	 t={
  	 	name="blocked", 
  	 	anims={},
  	 	invuln=true,
  	 }  	 
  	end
  	
  	if fget(mget(i - 1, j-1), 1) then
  	 t={
  	 	name="space elevator", 
  	 	anims={83, 85, 86, 87},
  	 	man_made=true,
  	 	has_inv=false,
  	 }  	 
  	end
  	
  	cell = {
	    x=i,
	    y=j,
	    frame=1,
	    hp=t.hp != nil and t.hp or 0,
	    tile = t,
	    inv={},
	    prc_tkr=0,
	    outbox={}
	   }
  	
	  add(grid.data, cell)
	  
	  if t.name != "blocked" and t.name != "space elevator" then
	   add(valid_res_spots, cell)
	  end
	  
  end
 end
 
 --place resources
 for res in all(tile_types_res) do
  spot = valid_res_spots[flr(rnd(#valid_res_spots)) + 1]
  spot.tile = res
  spot.hp = res.hp
  del(valid_res_spots, spot)
 end
end

function _update_grid()
 next_belt_frame = wrap(belt_frame, 1, 1, 3)
 belt_frame = tick_wait(belt_frame, next_belt_frame, 10, true)
 
 for i=1,#grid.data,1 do
  cell = grid.data[i]
  
  if cell.pwr == true and cell_paused != true then
 	 next_frame = wrap(cell.frame, 1, 1, #cell.tile.anims)
 	 cell.frame = tick_wait(cell.frame, next_frame, .5)
	 end
	 
  --update hp
  if cell.tile.hp != nil then
   cell.hp = mid(-1, cell.hp +  .02,  cell.tile.hp)
  end
  
  cell.pwr = has_pwr(cell)
  
  --process stuff
  if cell.tile.prc != nil and (cell.tile.pwr == true or cell.pwr == true) and cell.paused == false then
   cell.prc_tkr += 1
   
   --process!
   if cell.prc_tkr >= cell.tile.prc_time then
    process(cell)
   end
   
   --output
   if #cell.outbox > 0 then
    try_output(cell)
   end
   
  end
 end
end


function _draw_grid()
 for i=1,#grid.data,1 do
  local cell = grid.data[i]
  local c_x, c_y = get_coords(cell)
  if #cell.tile.anims > 0 then
	  --draw sprite
	  local sprite = cell.tile.anims[cell.frame] 
	  mset (
	   cell.x - 1,
	   cell.y - 1,
	   sprite
	  )
	 elseif cell.tile.name == "cleared" then --draw empty cell
	  mset (cell.x - 1, cell.y - 1, 16)
  end
  
  -- resources get redrawn
  if (cell.tile.recolor != nil) then
   draw_res(cell)
  end
  
  --belts get redrawn
	 if cell.tile.belt != nil then
	   draw_belt(cell)
	 end
  
  --miners get redrawn
	 if sub(cell.tile.name, -5) == "miner" then
	   draw_miner(cell)
	 end
	 
	 --empty cells with inventories
	 if (cell.tile.man_made == nil or cell.tile.name == "storage") and (#cell.inv > 0 or #cell.outbox > 0)then	  
	  draw_tiny_item(cell.inv[1] or cell.outbox[1], c_x+2, c_y+2)
	  	  
	  if #cell.inv > 1 then
 	  draw_tiny_item(cell.inv[2], c_x+4, c_y+3)
	  end
	  
	  if #cell.inv > 2 then
 	  draw_tiny_item(cell.inv[3], c_x+2, c_y+4)
	  end
	  
	  if #cell.inv > 3 then
 	  draw_tiny_item(cell.inv[4], c_x+4, c_y+5)
	  end
	 end
	 
	 --paused
	 if cell.paused == true then
			spr(tick(0, 45, 2), c_x - 3, c_y - 3)
	 end
	 
	 --pwr status
	 if cell.tile.man_made and cell.pwr == false and cur_goal > 1 then
			local offset = cell.tile.name=="space elevator" and 0 or 3
		 spr(tick(0, 46, 2), c_x - offset, c_y - offset)
	 end
  
 end
	 
end

function draw_res(cell)
	pal(cell.tile.recolor[1], cell.tile.recolor[2])
 spr (
  cell.tile.anims[1],
  (cell.x-1) * grid.cell_size, 
  (cell.y-1) * grid.cell_size
 )
 pal()
end

function draw_belt(cell)
 belt_colors = {12, 14, 8}
 local c_x, c_y = get_coords(cell)
 for c in all(belt_colors) do
  if cell.pwr == false or cell.paused == true or c == belt_colors[belt_frame] then
  	pal(c, 13)
  else
   pal(c, 6)
  end
 end
 
 spr (
  cell.tile.anims[1],
  c_x, 
  c_y
 )
 
 pal()
 
 local i1 = cell.inv[1]
 local i2 = cell.outbox[1] 
 if i1 != nil then
  draw_tiny_item(i1, c_x+3, c_y+3)
 end
 if i2 != nil then
  local o_x, o_y = dir_offset(cell.tile.output)
  draw_tiny_item(i2, c_x+3 + (2*o_x), c_y+3 + (2*o_y))
 end
end

function draw_miner(cell)
 clr = cell.miner_res.recolor
 pal(clr[1], clr[2])
 spr (
  cell.tile.anims[cell.frame],
  (cell.x-1) * grid.cell_size, 
  (cell.y-1) * grid.cell_size
 )
 pal()
end

function get_cell(x,y)
 x = x or crs.x
 y = y or crs.y
 grid_x = x + 1;
 grid_y = y + 1;
	i = (grid_x - 1) * grid.size
	i += grid_y
	
 return grid.data[i]
end

function get_index(x,y)
 grid_x = x + 1;
 grid_y = y + 1;
	i = (grid_x - 1) * grid.size
	i += grid_y
	
 return i
end

function get_coords(cell)
 cell = cell or _cell
 return 
  (cell.x - 1) * grid.cell_size,  
  (cell.y - 1) * grid.cell_size
end
-->8
--tiles
tile_types_nat = {}
tile_types_bld = {}
tile_types_res = {}
tile_types_belt = {}

function _init_tile_types()
 add_type_nat("", {}, 10)
 add_type_nat("tree", {21}, 1, 5, hit, "wood")
 add_type_nat("shroom", {37}, .3, 10, clear, "wood")
 add_type_nat("rock", {22}, 1, 5, hit, "limestone")
 add_type_nat("rock", {38}, 1, 5, hit, "limestone")
 
 add_type_belt("➡️➡️", "⬅️⬅️", 65, 80)
 add_type_belt("⬇️⬇️", "⬆️⬆️", 64, 81)
 
 add_type_belt("➡️⬇️", "⬆️⬅️", 97, 99)
 add_type_belt("⬇️⬅️", "➡️⬆️", 113, 115)
 add_type_belt("⬅️⬆️", "⬇️➡️", 112, 114)
 add_type_belt("⬆️➡️", "⬅️⬇️", 96, 98)
 
 add_type_bld("splitter", {60, 61}, dump_inv, 30)
 add_type_bld("constructor", {53, 54}, construct, 30 * 3)
 add_type_bld("smelter", {58, 59}, smelt, 30 * 2)
 add_type_bld("miner", {50, 51, 52}, mine, 30)
 add_type_bld("storage", {35}, dump_inv_to_belt, 30)
 add_type_bld("burner", {55, 56}, burn, 180, true, true)
 add_type_bld("pylon", {62, 63}, nil, 90, false, true)
 -- used for tutorial ui only
 add_type_bld("belt", {49})

	add_type_res("iron", 6, 60, "ore")
	add_type_res("limestone", 15, 50, nil)
	add_type_res("coal", 1, 10, nil)
	add_type_res("copper", 9, 50, "ore")
end

function add_type_nat(n, an, w, h, ac, r)
 add(tile_types_nat, {
  name=n,
  anims=an,
  weight=w,
  hp=h,
  act=ac,
  res=r
 })
end 

function add_type_bld(n, a, p, p_t, i, power)
 add(tile_types_bld, {
  name=n,
  anims=a,
  man_made=true,
  output="➡️⬇️⬅️⬆️",
  prc=p,
  prc_time=p_t,
  pwr=power and true or false,
  has_inv=i != false
 })
end

function add_type_belt(o, ro, s, rs)
 add(tile_types_belt, {
  belt=true,
  man_made=true,
  name="belt",
  orient=o,
  output=sub(o, 2),
  anims={s},
  prc=dump_inv,
  prc_time=30,
 })
 add(tile_types_belt, {
  belt=true,
  man_made=true,
  name="belt",
  orient=ro,
  output=sub(ro, 2),
  anims={rs},
  prc=dump_inv,
  prc_time=30,
 })
end

function add_type_res(n, c, h, r)
 add(tile_types_res, {
  name=n,
  recolor={12, c},
  anims={34},
  invuln=true,
  act=hit,
  hp=h,
  res=r and n.." "..r or n
 })
end

function rnd_tile_nat()
 total_weight = 0
 for tile in all(tile_types_nat) do
  total_weight += tile.weight
 end
 
 running_weight = 0
 random = rnd(total_weight)
 for tile in all(tile_types_nat) do
  running_weight += tile.weight
  if (running_weight >= random) then
  	return tile
  end
 end
 
 return tile_types_nat[0]
end

function get_bld(n)
 return find_name(tile_types_bld, n)
end

function draw_bld(n, x, y, c1, c2)
 if c1 != nil then
  pal(c1, c2)
 end
 spr(get_bld(n).anims[1], x, y)
 pal()
end

function build_miner()
 _cell.miner_res = _cell.tile
 build("miner")
 _cell.dsp_name = _cell.miner_res.name.." miner"
end

function build_belt(node)
 local cell = get_cell(node.x, node.y)
 local i = node.d_in
 local o = node.d_out
 cell.paused = false
 
 t = dd
 
 if i == nil and o == nil then
  i = "➡️"
  o = "➡️"
 end
 
 if cell.tile.invuln or
 	(cell.tile.man_made and cell.tile.belt != true)
 then
  return
 end
 
 if i == nil then
  i = o
 end
	
 for b in all(tile_types_belt) do
  if b.orient == i..o then
   cell.tile = b
   break
  end
 end
end

function reverse_belt()
 close_menu()
 local o = _cell.tile.orient
 local n = {}
 n.x = _cell.x - 1
 n.y = _cell.y - 1
 n.d_in = inv_dir(sub(o, 2, 2))
 n.d_out = inv_dir(sub(o, 1, 1))
 build_belt(n)
end

function change_belt()
 _cell.tile = tile_types_belt[ceil(rnd() * #tile_types_belt)]
end

function get_bld_nbr(cell)
 local dirs = {"⬆️", "⬇️", "⬅️", "➡️"}
 for d=1, #dirs do
  local x, y = dir_offset(dirs[d])
  local o_cell = get_cell(cell.x + x - 1, cell.y + y - 1)
  local o_t = o_cell.tile

  if o_t.man_made == true and o_t.belt == nil and o_t.name != "space elevator" and o_t.name != "pylon" then
   return dirs[d]
  end
 end
end

--tile actions
function do_cell_action()
 if (_cell.tile.act != nil) _cell.tile.act(cell)
end

function hit()
 if (_cell.hp != nil) then
  -- shake(.05)
  _cell.hp -= 1;
  local x, y = get_coords()
  if (_cell.hp <= 0) then
   -- give resource!
   
   new_float_text(x, y, "+1 ".._cell.tile.res)
   inv_add(_cell.tile.res)
   shake(.1)
   _cell.hp = _cell.tile.hp
   if _cell.tile.invuln == nil then
    clear()
   else
   	sfx(21)
   end
  
  else
   fx_hit(x, y)
  end
 end
end

function build(name)
 tile = get_bld(name)
 _cell.tile = tile
 _cell.flipx = false
 _cell.flipy = false
 _cell.pwr = #pwr_src > 0 and pwr_src[1].pwr
 _cell.paused = false
 
 if tile.pwr then
  add(pwr_src, _cell)
  _cell.prc_tkr = _cell.tile.prc_time - 10
 end
 
 close_menu()
 local c_x, c_y = get_coords()
 fx_build(c_x, c_y, _cell.tile.pwr == true)
end

function clear()
 if sub(_cell.tile.name, -5) == "miner" then
  _cell.tile = _cell.miner_res
  _cell.dsp_name = nil
 elseif _cell.tile.invuln != true then
  if _cell.tile.pwr then
	  del(pwr_src, _cell)
	 end
	 
	 --kill power if we destroy burner
	 if _cell.tile.name == "burner" then
		 for p in all(pwr_src) do
		  p.pwr = false
		 end
	 end
	 
  _cell.tile = {name="cleared", anims={}}
 end
 _cell.paused = false
 close_menu()
 local c_x, c_y = get_coords()
 fx_boom(c_x, c_y)
end

function pause()
 _cell.paused = not _cell.paused
end

function set_recipe(r)
 _cell.recipe = r
 close_menu()
end

-- processes
function process(cell)
 if #cell.outbox == 0 then
  cell.tile.prc(cell) 
  cell.prc_tkr = 0
 end
end

function try_output(cell)
 local o = get_output_cell(cell)
 
 local did_output = false
 for i in all(cell.outbox) do
  if in_ready(o, i) == true then
   did_output = true
   add(o.inv, i)
   del(cell.outbox, i) 
  end
 end
 
 if did_output == true 
  and _cell.tile.belt == true 
 then
  o.prc_tkr = 1
 end
 
end

function mine(cell)
 add(cell.outbox, cell.miner_res.res)
end

function smelt(cell)
 for r in all(recipes) do
  if r.prc == "smelt" then
   if r.input == cell.inv[1] then
    del(cell.inv, r.input)
		 	cell.outbox = {r.output}
		 	return
   end 
  end
 end
 
 -- if no recipes, just output
 cell.outbox = {cell.inv[1]}
 del(cell.inv, cell.inv[1])
end

function check_recipe(cell)
 local r = cell.recipe
 if (r == null) return nil, nil
 
 local in1_found, in2_found = false, false
 for i in all(cell.inv) do
  if i == r.input and in1_found == false then
   in1_found = true
  elseif i == r.input2 then
   in2_found = true
  end
 end
 
 return in1_found, in2_found
end

function construct(cell)
 local r = cell.recipe
 if (r == null) return nil, nil
 
 in1_found, in2_found = check_recipe(cell)
 
 if in1_found and (r.input2 == nil or in2_found) then
  del(cell.inv, r.input)
  if r.input2 != nil then
   del(cell.inv, r.input2)
  end
 	cell.outbox = {r.output}
 end
end

function burn(cell)
 local fueled = false
 for i in all(cell.inv) do
  local itm = find_name(item_defs, i)
  if i == "wood" or i == "coal" or i == "biomass" then
   del(cell.inv, i)
   fueled = true
   break
  end
 end
 
 for p in all(pwr_src) do
  p.pwr = fueled
 end
 
end

function dump_inv(cell)
 if #cell.inv > 0 and #cell.outbox == 0 then
  add(cell.outbox, cell.inv[1])
  del(cell.inv, cell.inv[1])
 end
end

function dump_inv_to_belt(cell)
 o_cell = get_output_cell(cell, true)
 if o_cell != nil and #cell.inv > 0 and #cell.outbox == 0 then
  add(cell.outbox, cell.inv[1])
  del(cell.inv, cell.inv[1])
 end
end

function in_ready(cell, itm)
 if cell.tile.belt then
  return belt_frame == 1 and #cell.inv == 0
 
 -- handle recipes
 elseif cell.tile.name=="constructor" then
 	if (cell.recipe == nil or #cell.inv >= 5) return false
 	if (#cell.inv < 3) return true
 	
		
 	in1_found, in2_found = check_recipe(cell)
 	
 	-- has 1 ingredient, needs the other
 	if in1_found == true and in2_found == false then
	    
		return itm == cell.recipe.input2
 	elseif in2_found == true and in1_found == false then
 		return itm == cell.recipe.input
	elseif in2_found == false and in1_found == false then
		return itm == cell.recipe.input or itm == cell.recipe.input2
 	end
 	
 	return true
 	
 elseif cell.tile.name == "storage" then
  return #cell.inv <= max_inv
 elseif cell.tile.man_made then
  return #cell.inv < 5
 end
 
 return true 
end

-- helpers
function is_empty(cell)
 return #cell.tile.anims == 0 and cell.tile.name != "blocked" and cell.tile.name != "space elevator"
end


-- find all valid neihbors, find best one, fallback to right
function get_output_cell(cell, good_only)
	local o = cell.tile.output
	local t = cell.tile
	
 if o == nil then
  return nil
 end
 
 local valid_nbrs = {}
 local good_nbrs = {}
 for n=1, #o do
  local c = sub(o,n,n)
  local x, y = dir_offset(c)
  local o_cell = get_cell(cell.x + x - 1, cell.y + y - 1)
  local o_t = o_cell.tile
  
  if o_t.belt and sub(o_t.orient, 1, 1) == c then
   add(good_nbrs, o_cell)
  elseif t.belt == true and o_t.man_made != nil then
   add(good_nbrs, o_cell)
  elseif is_empty(o_cell) or (o_t.output != inv_dir(c)) then
   add(valid_nbrs, o_cell)
  end
 end
 
 if #good_nbrs > 0 then
  return good_nbrs[1 + flr(rnd(#good_nbrs))]
 end
 
 if good_only == true then
  return nil
 end
 
 if #valid_nbrs == 0 and #good_nbrs == 0 then
  local char = #o == 1 and o or "➡️"
  local x, y = dir_offset(char)
  return get_cell(cell.x + x - 1, cell.y + y - 1)
 end
 
 return valid_nbrs[1 + flr(rnd(#valid_nbrs))]
end
-->8
--ui
menu = {
 active="main",
 grace=0,
 sel_act=nil,
 sel_⬆️⬇️ = 1,
 sel_⬅️➡️ = 0,
 sel = 1
}
float_text = {
 x=0,
 y=0,
 y_lim=0,
 msg=nil
}

function _draw_ui()
	menu.sel_⬆️⬇️ = 1
	menu.sel_⬅️➡️ = 0
	
 local c_x, c_y = get_coords()
 local t = _cell.tile
 
 --pwr overlay
 if _cell.tile.pwr then
  draw_pwr_coverage()
 end
 
 --menu
 if menu.active == "tut1" then
  draw_tut_1(9, 36)
 elseif menu.active == "tut2" then
  draw_tut_2(9, 36)
 elseif menu.active == "tut3" then
  draw_tut_3(9, 36)
 elseif menu.active == "tut4" then
  draw_tut_4(9, 36)
 elseif menu.active == "tut5" then
  draw_tut_5(9, 36)
 elseif menu.active == "context" then
  draw_context_menu()
 elseif menu.active == "build" then
  draw_build_menu()
 elseif menu.active == "recipes" then
  draw_recipes_menu()
 elseif menu.active == "inventory" then
  draw_inv_menu()
 elseif menu.active == "elevator" then
  draw_elevator_menu() 
 else
  print("🅾️ gather              menu ❎", 5, 120, 1)
 end
 
 --header
 if (
     menu.active == nil or
     sub(menu.active, 1, 3) != "tut"
    ) and 
    (
	    (
	     is_empty(_cell) == false and 
	     t.name != "blocked"
	    ) or #_cell.inv > 0
	   ) 
 then
 	draw_header(_cell)
 end
 
 --float text
 if float_text.msg != nil then
  print(float_text.msg, float_text.x + 6, float_text.y + 1, 1)
  print(float_text.msg, float_text.x + 5, float_text.y + 1, 1)
  print(float_text.msg, float_text.x + 5, float_text.y, 7)
 end
 
 --[[debug
 if watch != nil then
  print(watch, 1, 1, 8)
 end
 --]]
 
 --full screen ui
 if menu.active == "win" then
  draw_win()
 elseif menu.active == "main" then
  draw_main()
 end
 
 -- for cart art
 --palt(0, false)
 --sspr(0, 104, 128, 16, 0, 20)
 --palt()
end

function _update_ui()
 menu.grace = mid(0, menu.grace - 1,  10)
 if menu.active != nil then
  menu_input()
 end
 
 if float_text.msg != nil then
  float_text.y -= .3;
  if float_text.y < float_text.y_lim then
   float_text.msg = nil
  end
 end
end


function new_float_text(nx, ny, nm)
 float_text = {
  x=nx,
  y=ny,
  msg=nm,
  y_lim=ny - 10;
 }
end

function menu_input()
 if menu.grace == 0 then
		if btnp(⬇️) then
		 menu.sel += menu.sel_⬆️⬇️
		end
		if btnp(⬆️) then
		 menu.sel -= menu.sel_⬆️⬇️
		end 
		if btnp(➡️) then
		 menu.sel += menu.sel_⬅️➡️
		end
		if btnp(⬅️) then
		 menu.sel -= menu.sel_⬅️➡️
		end
	 if btnp(🅾️) then
		 close_menu()
		end
		if btnp(❎) then
		 if menu.sel_act and menu.sel_act.a then
		  menu.sel_act.a(menu.sel_act.n)
		 end
		end
	end
end

function draw_recipes_menu()
 local left = 8
 local top = 32
 local i_box_left = left + 73
 
 local t = _cell.tile
 
 if crs.x < (grid.size / 2) then
  left = 48
  i_box_left = 7
 end
 
 if (crs.y < 4) top = 24
 
 draw_ui_box(left, top, left+64, top+64)
 
 print("◆recipes◆", left + 15, top + 5, 1)
 
 local i=0
 local opt_count = 7
 local first_opt = min(menu.sel, #recipes - opt_count)
 
 for r in all(recipes) do
  if r.prc == "construct" then
  
	  if  (i >= first_opt - 1) 
	  and (i < first_opt + opt_count) then
		  y = top + 20 + ((i - first_opt) * 7)
		  if menu.sel == (i + 1) then
		   circfill(left+4, y+2, 1, 12)
		   menu.sel_act = {n=r, a=set_recipe}
		   draw_ing_box(r.input, r.input2, r.output, i_box_left)
		  end
		  print(r.output, left+8, y, 1)
	  end
	  
	  i += 1
  end  
 end
 
 if menu.sel > i then
  menu.sel = 1
 end
 if menu.sel < 1 then
  menu.sel = i
 end
end

function draw_ing_box(i, i2, o, x)
 local y = 32
 local i_y = 35
 local i_x = i2 != nil and x + 3 or x + 9
 draw_ui_box(x, y, x + 32, y+6)
 
 rectfill(i_x, i_y, i_x + 7, i_y + 7, 5)
 draw_item(i, i_x, i_y)
 i_x += 9
 
 if i2 != nil then
  print("+", i_x, i_y + 2, 1)
  i_x += 4
  rectfill(i_x, i_y, i_x + 7, i_y + 7, 5)
  draw_item(i2, i_x, i_y)
  i_x += 8
 end
 print(":  ", i_x, i_y + 2, 1)
 
 i_x += 5
 rectfill(i_x, i_y, i_x + 7, i_y + 7, 5)
 draw_item(o, i_x, i_y)
end




function draw_elevator_menu()
 elevator_opened = true
 local left = 9
 local top = 24
 draw_ui_box(left + 16, top - 13, left + 86, top + 12, 9)
 if cur_goal > #goals then
  print("◆ you win! ◆", left + 28, top - 8, 1)
 else
  print("◆ goal "..cur_goal.." of "..#goals.." ◆", left + 21, top - 8, 1)
 end
 
 draw_ui_box(left, top, left + 102, top + 72)
 
 local g = goals[cur_goal]
 local x = left + 8
 local itm_x = x + 14
 local y = top + 8
 local met = true
 
 if cur_goal == 2 then
 	met = _cell.pwr
	 spr(met == true and 44 or 43, x + 2, y + 12)
	 spr(46, x + 12, y + 12)
	 if met == false then
		 print("build a burner\nnearby and put \nsome coal/wood in \nits inventory", x + 24, y + 12, 1)
  else
   print("we've got power!", x + 24, y + 13, 1)
  end
 elseif cur_goal > #goals then
  print("wow, you have completed \nthe space elevator!\n\nthank you for playing!\n\nps: go check out \n           satisfactory!", x, y, 1)
 else
  local objs = g.objectives
	 for i=1, #objs do
	  o = objs[i]
	  has = player.inv[o.item]
	  met = met and has >= o.cnt
	 	spr(has >= o.cnt and 44 or 43, x, y)
	 	rectfill(itm_x, y, itm_x + 7, y+7, 5)
	  draw_item(o.item, itm_x, y)
	  draw_item_bar(y+7, itm_x, itm_x+7, o.cnt)
	  print(o.cnt.." " ..o.item, itm_x+11, y + 1, 1)
	
	  draw_bar(y + 10, x + 96, x + 56, has / o.cnt, 9, 5) 
	  
	  y += 16
	 end
	 
 end
 
 
 if met then
  rect(left + 37, top + 56, left + 72, top+74, tick(6, 9, .9))
  draw_ui_box(left + 39, top + 58, left + 63, top+65, 9)
  print("send", left + 47, top + 63, 1)
  menu.sel_act = {n="", a=send_goal}
 else 
  draw_ui_box(left + 16, top + 58, left + 86, top+65, 5)
  print(cur_goal == 2 and "   needs power!" or "missing materials", left + 22, top + 63, 1)
  menu.sel_act = nil
 end
 
 
end

function draw_inv_menu()
 t = _cell.tile
 
 menu.sel_⬅️➡️ = 1
 menu.sel_⬆️⬇️ = 6
 total_options = #item_defs
 if t.man_made != nil then
  total_options += 5
 end
 
 if menu.sel > total_options then
  menu.sel = 1
 end
 if menu.sel < 1 then
  menu.sel = total_options
 end
 
 left = 8
 top = 48
 detail_left = 68
 
 if crs.x < (grid.size / 2) then
  left = 64
  detail_left = 4
 end
 
 --cell inv
 sel_index = 1
 if _cell.tile.has_inv == true then
  draw_ui_box(left, top - 15, left+49, top - 9) 
  
  spr(_cell.tile.anims[_cell.frame], left + 2, top - 12)
  
	 for i=1, 5 do
		 x = left + 11 + ((i - 1) * 9)
		 y = top - 12
		 rectfill(x, y, x + 7, y+7, 5)
		 
	  item  = _cell.inv[i]
		 if item != nil then
		  draw_item(item, x, y)
		 end
		 
		 if menu.sel == i then
		  spr(1, x, y)
		  if item != nil then
		  	draw_item_detail(item, 1, detail_left)
		  	menu.sel_act = {n=i, a=take}
		  else 
		  	menu.sel_act = nil
		  end	
		 end
		end
		sel_index = 6
	end
 
 --player inv
 draw_ui_box(left, top, left+49, top+40)
 print("◆inventory◆", left + 3, top + 4, 1)
 
 cols = 6
 iter = 0
 for k,v in pairs(player.inv) do
  x = left + 2 + (9 * (iter % cols))
  y = top  + 10 + (9 * flr(iter / cols))
  
  rectfill(x, y, x+7, y+7, 5)
  if v > 0 then
   draw_item(k, x, y)
   draw_item_bar(y+7, x, x+7, v)
  end
  
  if menu.sel == iter + sel_index then
   spr(1, x, y)
   if v > 0 then
    menu.sel_act = {n=k, a=give}
    draw_item_detail(k, v, detail_left)
   else
    menu.sel_act = nil
   end
		 
  end
  
  iter += 1
 end
end

function draw_context_menu()
 left = 8
 top = 32
 
 t = _cell.tile
 
 if (crs.x < (grid.size / 2)) left = 64
 
 if (crs.y < 4) top = 24
 
 draw_ui_box(left, top, left+48, top+64)
 
 opts = {}
 
 if _cell.tile.act != nil then
  add(opts, {n="gather", a=do_cell_action})
 end
 
  -- if empty
 if is_empty(_cell) then
  add(opts, {n="build", a=open_menu})
 end
 
 if _cell.tile.name == "constructor" then
  add(opts, {n="recipes", a=open_menu})
 end
 
 add(opts, {n="inventory", a=open_menu})
 
 --if resource
 if cur_goal >= 3 and find_name(tile_types_res, t.name) != nil then
  add(opts, {n="build miner", a=build_miner})
 end
 
 --if pausable
 if t.man_made == true and t.pwr != true then
  add(opts, {n=_cell.paused == true and "start" or "pause", a=pause})
 end
 
 if t.belt == true then
  add(opts, {n="reverse", a=reverse_belt})
  add(opts, {n="change", a=change_belt})
 end
 
 --if destructible
 if is_empty(_cell) == false and t.invuln != true then
  add(opts, {n="destroy", a=clear})
 end
 
 print("◆menu◆", left + 12, top + 4, 1)
 i = 0
 sel = 1 + ((menu.sel-1) % #opts)
 for m in all(opts) do
  y = top + 16 + (i * (40 / (#opts - 1)))
  if sel == i+1 then
   circfill(left+4, y+2, 1, 12)
   menu.sel_act = m
  end
  print(m.n, left+8, y, 1)
  i += 1
 end
end

function draw_build_menu()
 local left = 8
 local top = 32
 
 local t = _cell.tile
 
 if (crs.x < (grid.size / 2)) left = 64
 
 if (crs.y < 4) top = 24
 
 draw_ui_box(left, top, left+48, top+64)
 
 opts = {
  {n="belt (drag)", u=3, a=start_drawing},
  {n="smelter", u=4, a=build},
  {n="constructor", u=5, a=build},
  {n="storage", u=4, a=build},
  {n="splitter", u=5, a=build},
  --{n="storage", a=build}
 }
 
 if burner_placed() then
  add(opts, {n="pylon", u=2, a=build})
 else
  add(opts, {n="burner", u=2, a=build})
 end
  
 print("◆build◆", left + 10, top + 4, 1)
 
 local i = 1
 local sel = 1 + ((menu.sel-1) % #opts)
 for m in all(opts) do
  if m.u <= cur_goal then
	  y = top + 4 + (i * (46 / (#opts - 1)))
	  if sel == i then
	   circfill(left+4, y+2, 1, 12)
	   menu.sel_act = m
	  end
	  print(m.n, left+8, y, 1)
	  i += 1
  end
 end
 
 if sel >= i then
  menu.sel = 1
 end
 
 if i == 1 then
  print("none unlocked", left + 3, top + 16, 8)
 end
end

function close_menu()
 menu.active = nil
 menu.grace = 3
 win_fade = 45
 sfx(22)
end

function start_game()
 start_fade()
 menu.active = "tut1"
 menu.grace = 10
end

function open_menu(m)
 if menu.grace <= 0 then
 	menu.active = m
 	menu.sel = 1
 	menu.grace = 3
  sfx(22)
 end
end

function draw_header(cell)
 local t = cell.tile
 local top = 1
 local life_y = top + 14
 local drawer_y = top + 17
 local inv_x = 72
 if (crs.y < 4) then
  top = 110
  life_y = top + 1
  drawer_y = top - 9
 end
 
 --inv drawer
 if menu.active != "inventory" and t.has_inv then
  -- position drawers
  tp = top == 1 and drawer_y - 5 or drawer_y - 3
  btm = top == 1 and drawer_y + 3 or drawer_y + 5
 
  draw_ui_box(inv_x, tp, inv_x + 40, btm)
 end
 
 --recipe drawer
 if cell.tile.name == "constructor" then
  -- position drawers
  tp = top == 1 and drawer_y - 6 or drawer_y
  btm = top == 1 and drawer_y or drawer_y + 5
  t_tp = top == 1 and drawer_y or drawer_y + 3
  
  draw_ui_box(7, tp, 7 + 56, btm, 13) 
  print(sub(cell.recipe and ":"..cell.recipe.output or ":no recipe", 1, 15), 10, t_tp, 1)
 end
 
 draw_ui_box(4, top, 116, top+8)
 
 --text
 msg = cell.dsp_name or t.name
 inv_summary = summarize_inv(cell)
 if (is_empty(cell) or (t.name == "storage") and #cell.inv > 0) then
  msg = #cell.inv.." "..inv_summary
 end
 
 t_center = 64 - flr(#msg*2)
 clr = sub(msg, -4) == "etc." and 2 or 1 
 msg ="● "..msg.." ●"
 
 print(msg, t_center - 12, top + 5, clr)

 --hp
 if t.hp != nil then
  draw_bar(life_y, 12, 115, cell.hp / cell.tile.hp, 8, 13) 
	end
	
	if cell.pwr and t.prc != nil then
  draw_bar(life_y, 12, 115, cell.prc_tkr / t.prc_time, 9, 13)
 end
	
	--inv boxes
	if menu.active != "inventory" and t.has_inv then
	 for i=1, 5 do
	  --1,41,9
		 x = inv_x + 2 + ((i - 1) * 9)
		 y = drawer_y
		 rectfill(x, y, x + 7, y+7, 5)
		 
		 if #cell.inv >= i then
		  draw_item(cell.inv[i], x, y)
		 end		 
		 
		end
		
	end
	
end

function draw_bar(y, min_bar, max_bar, v, c, c2) 
 local real_min = min(min_bar, max_bar)
 local real_max = max(min_bar, max_bar)
 
 l = ((1 - v) * min_bar) + (v * max_bar)
 if (l > real_max) l = real_max
 if (l < real_min) l = real_min
 if c2 != nil then
  line(min_bar, y, max_bar, y, c2)
 end
 if v != 0 then
  line(min_bar, y, l, y, c)
 end
 
end

function draw_item_bar(y, min_bar, max_bar, v)
 if v > 1 then
  draw_bar(y, min_bar, max_bar, v / 10, 9)
 end
 
 if v > 10 then
  draw_bar(y, min_bar, max_bar, v / 100, 10)
 end
 
 if v > 100 then
  draw_bar(y, min_bar, max_bar, v / max_inv, 7)
 end
end

function draw_ui_box(x1, y1, x2, y2, c)
 pal(6, c or 6) 
 
 --corners
 spr(32, x1, y1)
 spr(32, x2, y1, 1, 1, 1)
 spr(32, x2, y2, 1, 1, 1, 1)
 spr(32, x1, y2, 1, 1, false, 1)
 
 --body
 for i=x1+8, x2-4, 2 do
  spr(33, i, y1)
  spr(33, i, y2, 1, 1, false, true)
 end
 
 local y = 0
 for i=y1+8, y2-4, 2 do
  spr(48, x1, i)
  spr(48, x2, i, 1, 1, true, true)
 end
 
 rectfill(x1+8, y1+8, x2, y2, c or 6)
 pal()
end

function draw_item_detail(k, v, x)
 draw_ui_box(x, 82, x + 48, 87)
 local txt = v.." "..k
 txt = sub(txt, 0, 13)
 print(txt, x + 2, 86, 1)  
end

-- draw tut 1 window
function draw_tut_1(left, top)
 draw_tut_window(left, top)

 print("◆ tutorial ◆", left + 28, top - 8, 1)

 top += 6
 left += 4
 print("welcome to unsatisfactory!", left, top, 1)
 print("complete goals to progress \nand unlock factory parts.\n\nselect the space elevator\nto view your current goal.", left, top + 12, 2)

 top += 3

 spr(tick(0, 42, .5), 32, 8)
end

function draw_tut_2(left, top)
 draw_tut_window(left, top)
 print("◆ great work! ◆", left + 21, top - 8, 1)
 top += 6
 left += 4
 print("time to power up!", left, top, 1)
 print("build a burner close \nto the space elevator\n\nmake sure it has some coal \nor wood in its inventory!", left, top + 12, 2)

 top += 3

 print("new!", left + 6, top + 45, 1)
 draw_bld("burner", left + 4, top + 51, 12, 1)
 draw_bld("pylon", left + 14, top + 51)

 spr(tick(0, 42, .5), 32, 8)
end

function draw_tut_3(left, top)
 draw_tut_window(left, top)
 print("◆ powerful! ◆", left + 26, top - 8, 1)
 top += 6
 left += 4
 print("time to start automating!", left, top, 1)
 print("build miners on resources;\nremember they need power!\n\nbuild conveyor belts by \nholding and dragging", left, top + 12, 2)

 top += 3

 print("new!", left + 6, top + 43, 1)
 draw_bld("miner", left + 4, top + 50, 12, 1)
 draw_bld("belt", left + 14, top + 50)

 spr(tick(0, 42, .5), 32, 8)
end

function draw_tut_4(left, top)
 draw_tut_window(left, top)
 print("◆ heck yea! ◆", left + 26, top - 8, 1)
 top += 6
 left += 4
 print("time to smelt!", left, top, 1)
 print("smelters turn ore into \ningots.\n\nstorage holds items and \ncan output to a belt.", left, top + 12, 2)

 print("new!", left + 7, top + 43, 1)
 draw_bld("smelter", left + 4, top + 50)
 draw_bld("storage", left + 14, top + 50, 6, 7)
end


function draw_tut_5(left, top)
 draw_tut_window(left, top)
 
 print("◆ nice! ◆", left + 30, top - 8, 1)
 top += 6
 left += 4
 print("all buildings unlocked!", left, top, 1)
 print("constructors turn 1 or 2 \nitems into something new.\n\nsplitters redirect belts.", left, top + 12, 2)

 print("new!", left + 7, top + 43, 1)
 draw_bld("constructor", left + 4, top + 50, 6, 11)
 draw_bld("splitter", left + 14, top + 50)
end

win_fade = 45
function draw_win()
 win_fade = mid(-1, win_fade - 1,  999)
 rectfill(-10, -10, 138, 138, 0)
 
 for i=1,60 do
  circfill(i % 14 * i + i, i % 3 * i + i, ((frame + i) / i) % 10 < 8 and 1 or 0, 7)
 end

 fillp(tick(0b1010010110100101.1, 0b0101101001011010.1, .1))
 circfill(64, 230, 120, 1)
 fillp()
 spr(121, 60, 120)
 spr(105, 60, 120 - 8)
 spr(121, 60, 120 - 16)
 spr(105, 60, 120 - 24)
 spr(121, 60, 120 - 32)
 spr(tick(89, 90, 1), 60, 120 - 40)
 
 if win_fade < 0 then
  sspr(0, 96, 127, 31, 0, 16)
 end
 
 menu.sel_act = {n="", a=close_menu}
end


win_fade = 45
function draw_main()
 rectfill(-10, -10, 138, 138, 0)
 
 for i=1,60 do
  circfill(i % 14 * i + i, i % 3 * i + i, ((frame + i) / i) % 10 < 8 and 1 or 0, 7)
 end

 fillp(tick(0b1010010110100101.1, 0b0101101001011010.1, .1))
 circfill(64, 230, 120, 1)
 fillp()

 sspr(0, 96, 127, 31, 0, 16)
 print(tick("◆ start", "   start", 1), 40, 61, 9)
 
 print("a retro demake of satisfactory\nby devon grandahl", 5, 94, 1)
 
 menu.sel_act = {n="", a=start_game}
end

function draw_tut_window(left, top)
 draw_ui_box(left + 16, top - 13, left + 86, top + 12, 9)
 draw_ui_box(left, top, left + 102, top + 64)

 top += 8

 rect(left + 32, top + 42, left + 72, top+59, tick(6, 9, .9))
 draw_ui_box(left + 34, top + 44, left + 63, top+50, 9)
 print("ok", left + 48, top + 48, 1)
 menu.sel_act = {n="", a=close_menu}
end
-->8
--inventory + items + goals
player = {
 inv={}
}

item_defs = {}
recipes = {}

max_inv = 999

goals = {}
cur_goal = 1

function _init_items()
 def_item("wood,23,4,1")
 def_item("coal,23,1,1")
 def_item("copper ore,23,9,1")
  def_item("copper ingot,24,9,2")
  def_item("wire,26,9,2")
  def_item("cable,26,1,2")
  def_item("copper plate,25,9,2")
 def_item("limestone,23,15,1")
  def_item("concrete,24,15,2")
 def_item("iron ore,23,13,1")
  def_item("iron ingot,24,13,2")
  def_item("iron plate,25,13,2")
  def_item("iron rod,26,13,1")
  def_item("strong plate,25,2,2") 
		def_item("screw,27,13,1")
		def_item("frame,40,14,2")
		def_item("rotor,40,1,2") 
	def_item("steel ingot,24,12,1") 
		def_item("steel pipe,26,12,1") 
		def_item("stator,40,12,1")
	def_item("motor,40,2,2")  
	def_item("crct board,25,11,1")  
	def_item("computer,40,11,2")  

 for i in all(item_defs) do
  player.inv[i.name] = 0
 end
 
 inv_add("wood", 20)
end

function _init_recipes()
 def_recipe("smelt,copper ore,,copper ingot")
 def_recipe("smelt,iron ore,,iron ingot")  
 def_recipe("smelt,limestone,,concrete")  
 def_recipe("smelt,wood,,coal")
 
 def_recipe("construct,iron ingot,iron ingot,iron plate")  
 def_recipe("construct,iron ingot,,iron rod") 
 def_recipe("construct,copper ingot,,wire") 
 def_recipe("construct,wire,wire,cable")
 def_recipe("construct,copper ingot,copper ingot,copper plate")        
 def_recipe("construct,iron rod,,screw")        
 def_recipe("construct,iron rod,screw,rotor")
 def_recipe("construct,iron plate,screw,strong plate")
 def_recipe("construct,strong plate,iron rod,frame")
 def_recipe("construct,iron ingot,coal,steel ingot")
 def_recipe("construct,steel ingot,steel ingot,steel pipe")
 def_recipe("construct,steel pipe,wire,stator")
 def_recipe("construct,rotor,stator,motor")
 def_recipe("construct,rotor,cable,crct board")
 def_recipe("construct,crct board,cable,computer")
end

function _init_goals()
 def_goal({"limestone", "wood", "coal"}, {1, 3, 1})
 def_goal({"fake_pwr"}, {1})
 def_goal({"copper ore", "limestone", "coal"}, {10, 30, 5})
 def_goal({"copper ingot", "iron ingot", "limestone"}, {30, 30, 60})
 def_goal({"wire", "iron plate", "steel ingot"}, {30, 20, 20})
 def_goal({"cable", "screw"}, {20, 20})
 def_goal({"strong plate", "copper plate", "concrete"}, {20, 20, 20})
 def_goal({"rotor", "frame", "steel pipe"}, {25, 30, 30})
 def_goal({"stator", "concrete"}, {10, 100})
 def_goal({"motor", "computer"}, {20, 30})
end

function def_item(data)
 d = split(data)
 add(item_defs, {
  name=d[1],
  s=d[2],
  clr=d[3],
  size=d[4]
 })
end

function def_recipe(data)
 d = split(data)
 add(recipes, {
  name=d[4],
  prc=d[1],
  input=d[2],
  input2=d[3] != "" and d[3] or nil,
  output=d[4]
 })
end

function def_goal(itm, c)
 local goal = {
  objectives={},
  msg=m
 }
 
 for i=1, #itm do
  add(goal.objectives,
   {
    item = itm[i],
    cnt = c[i],
   })
 end
 
 add(goals, goal)
end

function send_goal()
 if cur_goal > #goals then
  start_fade()
  menu.active = "win"
  return
 end
 local objs = goals[cur_goal].objectives
 for i=1, #objs do
  o = objs[i]
  inv_del(o.item, o.cnt)
 end
 
 sfx(18)
 shake(.1)
 
 cur_goal += 1


 if cur_goal > #goals then
  -- leave menu open
 music()
 elseif cur_goal == 2 then
  open_menu("tut2")
 elseif cur_goal == 3 then
  open_menu("tut3")
 elseif cur_goal == 4 then
  open_menu("tut4")
 elseif cur_goal == 5 then
  open_menu("tut5")
 else
  close_menu()
 end
 
end

function inv_add(item, num)
 local inv = player.inv
 local num = num or 1
 if inv[item] != nil then
  inv[item] = mid(0, inv[item] +  num,  max_inv)
 else
  inv[item]=num
 end
end

function inv_del(item, num)
 local inv = player.inv
 if inv[item] != nil then
  inv[item] = mid(0, inv[item] - num,  max_inv)
 end
 
 if inv[item] == 0 then
  del(inv, item)
 end
end

function inv_add_all(items) 
 for i in all(items) do
  inv_add(i)
 end
end

function inv_get(tbl, index)
 local i = 1
 for k,v in pairs(tbl) do
  if index == 1 then
   return k
  end
  i += 1
 end
end

function take(i)
 if _cell.inv[i] != nil then
	 inv_add(_cell.inv[i])
	 del(_cell.inv, _cell.inv[i])
	 
  sfx(22)
 end
 
end

function give(i)
 if #_cell.inv < 5 or (#_cell.inv <= max_inv and _cell.tile.name == "storage")then
	 add(_cell.inv, i)
	 inv_del(i, 1)
  sfx(22)
  
  if _cell.tile.name == "burner" and _cell.pwr == false then
   _cell.prc_tkr = _cell.tile.prc_time - 5
  end
 end
end

function draw_tiny_item(i, x, y)
 i = find_name(item_defs, i)
 if i.size == 2 then
  rectfill(x, y, x+1, y+1, i.clr)
 	pset(x, y, lighten(i.clr))
 else
 	rectfill(x, y, x+1, y, i.clr)
 	pset(x, y, lighten(i.clr))
 end
end

function draw_item(i, x, y)
 i = find_name(item_defs, i)
 pal(13, i.clr)
 pal(14, lighten(i.clr))
 spr(i.s, x, y)
 pal()
end

function summarize_inv(cell)
 s = cell.inv[1] or cell.outbox[1]
 for i in all(cell.inv or cell.outbox) do
  if i != s then
   return s.." etc."
  end
 end 
 
 return s
end
-->8
--power + extras
pwr_src = {}

function has_pwr(cell)
 if cell.tile.man_made == nil then
  return true
 end
 
 if cell.pwr and cell.tile.pwr == true then
  return true
 end
 
 for p in all(pwr_src) do
  if p.pwr and dist(cell, p) < 5 then
   return true
  end
 end
 
 return false
end

function draw_pwr_coverage()
  for p in all(pwr_src) do
   c_x, c_y = get_coords(p)
	  --draw_faded_circle(c_x + 4, c_y + 4, 36, cell.pwr and 10 or 2, true)
	  
   t = 4 + (flr(frame / 2) % 22)
   for i=t, 36, 22 do
    circ(c_x + 4, c_y + 4, i, p.pwr and 10 or 1)
   end
   
   circ(c_x + 4, c_y + 4, 36, p.pwr and 9 or 2)
  
  end
end

function burner_placed()
 for p in all(pwr_src) do
  if p.tile.name == "burner" then
   return true
  end
 end
 	
	return false
end

function _draw_pwr_lines()
 local src = nil
 for p in all(pwr_src) do
  if p.tile.name == "burner" then
   src = p
   break
  end
 end
 
 for p in all(pwr_src) do
	 if src != nil and src != p then
		 local s_x, s_y = get_coords(src)
		 local d_x, d_y = get_coords(p)
		 s_x += 3
		 d_x += 3
		 s_y += 1
		 d_y += 1
		 
		 local m_x = (s_x + d_x) / 2
		 local m_y = (s_y + d_y) / 2
		 m_y += 2
		 
		
		 line(s_x, s_y, m_x, m_y, 1)
		 line(m_x, m_y, d_x, d_y, 1)
	 end 
 end 
end


--extras
animals = {}
manta_spawned = false
manta = {
 anims = {128, 130, 132, 130, 128},
}

bird = {
 anims = {134, 134, 134, 134, 135},
}

function _update_extras() 
 if manta_spawned == false then
  if flr(rnd(2000)) == 2 then
   add(animals, {
    n="manta",
    anims = manta.anims,
    anim_dly = 1,
    x=140,
    y=rnd(116) + 8,
    frame=1,
    m_x=-.2,
    m_y=0,
   })
   manta_spawned = true
  end
 end
 
 if frame < 3 or flr(rnd(500)) == 2 then
  add(animals, {
   n="bird",
   anims = bird.anims,
   anim_dly=.5,
   x=-20,
   y=flr(rnd(160)) - 100,
   frame=1,
   m_x=.2,
   m_y=.2,
  })
 end
 
 for a in all(animals) do
  a.x += a.m_x
  a.y += a.m_y
  if a.x < -32 or a.x > 160 then
   if a.n == "manta" then
    manta_spawned = false
    del(animals, a)
   end
  else
   next_frame = wrap(a.frame, 1, 1, #a.anims)
 	 a.frame = tick_wait(a.frame, next_frame, a.anim_dly)
  end
 end
end

function _draw_animals()
 for a in all(animals) do
  if a.n == "manta" then
   draw_manta(a.anims[a.frame], a.x, a.y, 2, 2)
  else
   spr(a.anims[a.frame], a.x, a.y)
  end
 end
end

function draw_manta(s, x, y)
 spr(136, x + 12, y + 12)
 fillp()
 
 pal()
 spr(s, x, y, 2, 2)
end

-- fx
fx = {}
elevator_opened = false

function _update_fx()
 for f in all(fx) do
  f.frame += .2
  f.hp -= 1
  if f.hp <= 0 then
   del(fx, f)
  end
 end
end

function _draw_fx()
	for f in all(fx) do
	 spr(f.anims[flr(f.frame)], f.x, f.y)
	end
	
	if elevator_opened == false then
  spr(tick(0, 42, .5), 32, 8)
	end
end

function fx_boom(f_x, f_y)
 add(fx, {
  anims={160, 161, 162},
  hp=30,
  x=f_x,
  y=f_y,
  frame=1
 })
 
 sfx(16)
 --shake(.1)
end

function fx_hit(f_x, f_y)
 add(fx, {
  anims={177, 178},
  hp=20,
  x=f_x,
  y=f_y,
  frame=1,
 })
 
 sfx(19)
 --shake(.1)
end

function fx_build(f_x, f_y, pwr)
 add(fx, {
  anims={163, 164, 165},
  hp=30,
  x=f_x,
  y=f_y,
  frame=1
 })
 
 sfx(17)
 if pwr != nil and pwr == true then
  sfx(20)
 end
 --shake(.1)
end

__gfx__
00000000770000770000000000000000000aa00000000000000000000000000000000000000000000000000000000000ccccccccbbf7cccccccccccccccccccc
0000000070000007077007700000000000000000000aa000000000000000000000000000000000000000000000000000ccccccccbbf7cccccc7ccccccccc7ccc
000000000000000007000070008008000900009000000000000000000000000000000000000000000000000000777700ccccccccbbff7cccccccc7cccccccccc
00000000000000000000000000082000a009900a0a0000a0000000000000000000000000000000000000000000799600ccccccccbbbf7ccccccccccccccccc7c
00000000000000000000000000028000a009900a0a0000a0000000000000000000000000000000000000000000799600cbbbbbbcbbff7cccccccccccc77ccccc
000000000000000007000070008008000900009000000000000000000000000000000000000000000000000000766600bbbbbbbbbfbff7ccfccc7cccccc77ccf
0000000070000007077007700000000000000000000aa000000000000000000000000000000000000000000000000000bbbbbbbbbbbff7ccffccccccccccccff
00000000770000770000000000000000000aa00000000000000000000000000000000000000000000000000000000000bbbbbbbbbbff7cccfffccccccccccfff
bbbbbbbbbbbbbbbb3333333300000000bbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000e0000000000000000000cccc7fbbbbbbbbbbcccc7fffff7ccccc
bbbbbbbbbbb3bbbb3333333300000000bbbbb3bbbb3333bbbbbbbbbb0000000000000000000ede00000000e000000000cccc7ffbfbbffffbccccc7fff7cccccc
bbbbbbbbb33bbbbb3333333300000000bb333bbbbb3f333bbbbbddbb000000000000000000eddde000000e0000000000cccc7fbbfff77fffc7cccc7f7ccccccc
bbbbbbbbbbbb3bbb3333333300000000b33333bbb333355bbbbd6ddb000e0000000ee0000eddddde0000d0000000e000ccccc7fb7f7cc77fccccccc7cccccccc
bbbbbbbbbbbbb33b3333333300000000b333333bb3333e5bbbd6dd5b00ddd00000edde00edddddd0000d0000000d0000cccc7ffbc7ccccc7cccccc7ccc77cccc
bbbbbbbbbb3bbbbb3333333300000000bb3333bbb3f3355bb35dd553000d000000dddd000ddddd0000d0000000000000ccc7ffbbcccccccccccccccccccc77cc
bbbbbbbbbbb3bbbb3333333300000000bbbb3bbbbb3355bbbb35553b000000000000000000ddd0000d00000000000000ccc7fffbccccccccccc7cccccccccccc
bbbbbbbbbbbbbbbb3333333300000000bbbbbbbbbbb44bbbbbbbbbbb0000000000000000000d00000000000000000000ccc7ffbbcccccccccccccccccccccccc
0011111111111111bbbbbbbb955aa55900000000bbbbbbbbbbbbbbbbbbbbbbbb000000000000000000077000000000dd000000990000000001111a1000888800
0115555555555555bbbbbbbb5666666500000000bbbbbbbbbbbdddbbbbbbbbbb00000000000000000079970000000ddd000009a9000000001188a811088aa880
1166666666666666bbbbbbbb5666666500000000bb8882bbbbdd6ddbbbbb88bb00eeee0000000000079999700000ddd000009a9000080800188a8881088aa880
1666666666666666bb4444bba666666a00000000b8888e2bbdddd5dbbbb8f88b00eddd000000000079999997dd0ddd009909a9000008080018aaaa81088aa880
1666666666666666b4c7cc5ba666666a00000000b8f8222bb5d5555bbbb2882b000dd0000000000077799777ddddd0009a9a90000008080018888a81088aa880
1666666666666666b4cccc535666666500000000bbb22bbb33511133b2bb22bb00eddd0000000000007997000ddd000009a90000000000001888a88108888880
1666666666666666b54cc5535666666500000000bbbbbbbbbb3333bbbbbbbbbb00eedd00000000000079970000d000000090000000000000118a8811088aa880
1666666666666666b3544533955aa55900000000bbbbbbbbbbbbbbbbbbbbbbbb00000000000000000077770000000000000000000000000001a1111000888800
16666666bbbbbbbbaaabbaa9aaabbaa9aaabbaa9b666666bb6aaa66bbbb1bbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaabbbbbbbbbbbbbbbbbbb
16666666bbbbbbbbabaa99b9abaa99b9abaa99b966aaa6666a999aa6bbbb1bbbbbb1bbbbbb9999bbb91bb19bb9b11b9bbbbaabbbbbb99bbbbbb6dbbbbbb6dbbb
1666666655555555abb76b39abb67b39abb66b396a999aa66997999dbb9119bbbb9119bbb999999bb91ba19bb961169b5aa99aa55aa99aa5bbaaa9bbbb777abb
1666666666d66d665b4664355b4764355b4674355997999559999995559aa955559a19555d1991d5591bb19559b11b956999999669999996bbb6dbb3bbb6dbb3
1666666666d66d665ac67da55ac66da55ac76da55999999559797795569aa965569aa9655d1111d5599bb995599339956999999669999996bbaaa933bb777a33
1666666655555555b9c45c93b9c54c93b9c44c936979779d6999999db99a8993b998a993bdd11dd3b9999993b99999935995599559955995bbb6d33bbbb6d33b
1666666633333333b4cccc53b4cccc53b4cccc536995599d6995599db9988993b9988993b999999399555599995555993395593333911933bb66dd3bbb66dd3b
16666666bbbbbbbbb4445553b4445553b4445553b45665d3b45665d3b2b11323b2b11323b2b2232322b3332222b33322bb5dd5bbbb5dd5bbbbbbbbbbbbbbbbbb
bb56653bbbbbbbbbcccccc776686686655cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb5cc53bbbbbbbbbccccc87766666666558ccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb56653b55555555cccc8877666666665588cccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb5ee53b6c6e6686ccc888776666666655288ccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb56653b6c6e6686cc88887666688666552288cc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb56653b55555555b8888886688bb2265222288c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb58853b33333333b8888888888332222222228b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb56653bbbbbbbbbbbbbb55bb3333333335533330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbb56653bccca999cccca9cccc999acccccca9cccccca9cccccca9ccc0000000000000c00000007000000000000000000000000000000000000000000
bbbbbbbbbb58853bcca92ccccc2a92ccccc29acccc2a92cccc2a92cccc2a92cc0000000000000600000006000000000000000000000000000000000000000000
55555555bb56653bcca9c222222a9222222c9acc222a9222222a9222222a922200000000d000050dd000050d0000000000000000000000000000000000000000
6866e6c6bb56653bcc992cccc2aaaa2cccc299ccc2aaaa2cc2aaaa2cc2aaaa2c000000002dda05d22dda05d20000000000000000000000000000000000000000
6866e6c6bb5ee53bbbc999ccc6666d5ccc999cccc6666d5cc6666d5cc6666d5c0000000022290922222909220000000000000000000000000000000000000000
55555555bb56653bbbbb993c361199533b99333336cc115336111c53369a11530000000000905090009050900000000000000000000000000000000000000000
33333333bb5cc53bbbbaa993369a11533aa9933b3611995336cc115336111c530000000000950590009505900000000000000000000000000000000000000000
bbbbbbbbbb56653bbb555553bddddd53b55555bbbddddd53bddddd53bddddd530000000000905090009050900000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000950090000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000007905090000000000000000000000000000000000000000000000000
bb995555555599bbbb995555555599bb00000000000000000000000000000000000000000a90059c000000000000000000000000000000000000000000000000
bb9566866c66593bbb9566c66866593b00000000000000000000000000000000000000007a959991000000000000000000000000000000000000000000000000
bb56e6866c6e653bbb56e6c6686e653b0000000000000000000000000000000000000000a9904991000000000000000000000000000000000000000000000000
bb5665555556653bbb5665555556653b0000000000000000000000000000000000000000a9904991000000000000000000000000000000000000000000000000
bb5cc5333358853bbb588533335cc53b0000000000000000000000000000000000000000aa904991000000000000000000000000000000000000000000000000
bb5665bbbb56653bbb5665bbbb56653b00000000000000000000000000000000000000000a959991000000000000000000000000000000000000000000000000
bb5665bbbb56653bbb5665bbbb56653b00000000000000000000000000000000000000000a950091000000000000000000000000000000000000000000000000
bb5885bbbb5cc53bbb5cc5bbbb58853b00000000000000000000000000000000000000000a905091000000000000000000000000000000000000000000000000
bb5665555556653bbb5665555556653b000000000000000000000000000000000000000000900591000000000000000000000000000000000000000000000000
bb56e6c6686e653bbb56e6866c6e653b000000000000000000000000000000000000000007905091000000000000000000000000000000000000000000000000
bb9566c66866593bbb9566866c66593b00000000000000000000000000000000000000000a950091000000000000000000000000000000000000000000000000
bb9955555555993bbb9955555555993b00000000000000000000000000000000000000000a905091000000000000000000000000000000000000000000000000
bbb333333333333bbbb333333333333b00000000000000000000000000000000000000000a900591000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000a905091000000000000000000000000000000000000000000000000
00000011000000000000000000000000000000000000000000001000000100000055050000000000000000000000000000000000000000000000000000000000
000001dd100000000000011110000000000000000000000000011000000010000555050000000000000000000000000000000000000000000000000000000000
00001dddd10000000000155551000000000011111100000000000000000000005555050500000000000000000000000000000000000000000000000000000000
0001dddddd1000000001dddddd100000000155555510000000000000000000005555050500000000000000000000000000000000000000000000000000000000
001ddd666dd11000001dd6666dd11000001ddd666dd1000000000000000000005555050500000000000000000000000000000000000000000000000000000000
01dd666d55dd110001dd666d55d1110001dd666d55d1110000000000000000005555050500000000000000000000000000000000000000000000000000000000
01c666ddddddd10001c666ddddddd10001c666ddddddd10000000050000005000555050000000000000000000000000000000000000000000000000000000000
1d1dddddddddd1601d1dddddddddd1661d1dddddddddd16000000550000000500055050000000000000000000000000000000000000000000000000000000000
1d1dddddddddd1661d1dddddddddd1601d1dddddddddd16600000000000000000000000000000000000000000000000000000000000000000000000000000000
01c666ddddddd10001c666ddddddd10001c666ddddddd10000000000000000000000000000000000000000000000000000000000000000000000000000000000
01dd666d55dd110001dd666d55d1110001dd666d55d1110000000000000000000000000000000000000000000000000000000000000000000000000000000000
001ddd666dd11000001dd6666dd11000001ddd666dd1000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001dddddd1000000001dddddd100000000155555510000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001dddd10000000000155551000000000011111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000001dd100000000000011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
500100155000001550000000bbbbbbbbbbbbbbbb6666666600000000000000000000000000000000000000000000000000000000000000000000000000000000
05d50d500000500000105000bbbbbbbbbbbb666b6aa9999500000000000000000000000000000000000000000000000000000000000000000000000000000000
0015d5000010100000000000bbbbbbbbbbaa995b6aa9a99500000000000000000000000000000000000000000000000000000000000000000000000000000000
015555510050005000000000bbba9bbbbba99a5b6999999500000000000000000000000000000000000000000000000000000000000000000000000000000000
01d0566d0100000001005010bbb995bbbb99995b69999a9500000000000000000000000000000000000000000000000000000000000000000000000000000000
1d555ddd0050501000000000bbb555bbbb9a995b69a9999500000000000000000000000000000000000000000000000000000000000000000000000000000000
0d5dd5d01001055000010010bbbbbbbbbb55555b6999999500000000000000000000000000000000000000000000000000000000000000000000000000000000
d0011d0d1000000500000000bbbbbbbbbbbbbbbb6555555500000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000050000010500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001010500000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000005000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000010000000100501000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000101500001001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555500000000000
00000005555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550000000000
000000055aa55aa55aa555a555777755557777777777777777777555777755777777755777555557777777777777777777775557777755577559950000000000
000000055aa55aa55aaa55a557755755557775555555755555775557755755775555555777555577557755555755557755577557755775577559950000000000
000000055aa55aa55aaaa5a557755555577577555557755555775557755555775555557757755577555555557755557755577557755775557779550000000000
000000055aa55aa55a1aaaa555777555577577555557755555775555777555775775557757755577555555557755557755577557757755557779500000000000
000000055aa55aa55a51aaa555577755775777755557755555775555577755775555577577775577555555557755557755577557757555555775500000000000
00000005599559955955199556556655665116655556655555665556556655665555566555665566556655556655556655566556656655555665000000000000
00000005519999155955519556666155665556655556655556666556666155665555566555665516666155556655551666661556651665555665000000000000
00000005551111555155551551111555115551155551155551111551111555115555511555115551111555551155555111115551155115555115000000000000
00000001555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550000000000000
00000000111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000
__label__
ccccccccccccccccccccccccccca999cccca9cccc999accccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc7ccccccccccccccccccccca92ccccc2a92ccccc29acccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7ccccc
cccccccccccccccccccccccccca9c222222a9222222c9accccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7cc
cccccc7ccccccccccccccccccc992cccc2aaaa2cccc299cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c77ccccccbbbbbbccbbbbbbcbbc999ccc6666d5ccc999ccccbbbbbbccbbbbbbccbbbbbbccbbbbbbccbbbbbbccbbbbbbccbbbbbbccbbbbbbccbbbbbbccccccccc
ccc77ccfbbbbbbbbbbbbbbbbbbbb993c361199533b993333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbfccc7ccc
ccccccffbbbbbbbbbbbbbbbbbbbaa993369a11533aa9933bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbffcccccc
cccccfffbbbbbbbbbbbbbbbbbb555553bddddd53b55555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbfffccccc
cccccfbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb955aa559bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbfccccc
cccccffbbbb3bbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbb56666665bbbbbbbbbbbbbbbbbbbdddbbbbb1dbbbbbbbbbbbbbbbbbbbbbfccccc
cccccfbbb33bbbbbbbbbbbbbbbbbbbbbb33bbbbbbbbbbbbbbb9955555555555556666665bbbbbbbbbbbbbbbbbbdd6ddbbb1aa9bbbbbbbbbbbbbbbbbbbbffcccc
ccccccfbbbbb3bbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbb9566d66d6d66d6a666666abbbbbbbbbbbbbbbbbdddd5dbbb16dbb3bbbbbbbbbbbbbbbbbbbfcccc
cccccffbbbbbb33bbbbbbbbbbbbbbbbbbbbbb33bbbbbbbbbbb56d6d66d6d66d6a666666abbbbbbbbbbbbbbbbb5d5555bb1aaa933bbbbbbbbbbbbbbbbbbffcccc
ccccffbbbb3bbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbb5665555555555556666665bbbbbbbbbbbbbbbb335111331bb6d33bbbbbbbbbbbbbbbbbbfbffccc
ccccfffbbbb3bbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbb5dd5333333333356666665bbbbbbbbbbbbbbbbbb3333b1bb66dd3bbbbbbbbbbbbbbbbbbbbffccc
ccccffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb5665bbbbbbbbbb955aa559bbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbffcccc
cccccfbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb56653bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbfccccc
cccccffbbbbdddbbbbbbbbbbbbbdddbbbbbbbbbbbbbbbbbbbb5dd53bbbbdddbbbbbdddbbbb3333bbbbbbbbbbbb3331bbbb3333bbbbb3bbbbbbbbbbbbbbfccccc
cccccfbbbbdd6ddbbbbbbbbbbbdd6ddbbbbbbbbbbbbbbbbbbb56653bbbdd6ddbbbdd6ddbbb3f333bbbbbbbbbbb3f313bbb3f333bb33bbbbbbbbbbbbbbbffcccc
ccccccfbbdddd5dbbbbbbbbbbdddd5dbbbbbbbbbbbbbbbbbbb56653bbdddd5dbbdddd5dbb333355bbbbbbbbbb333155bb333355bbbbb3bbbbbbbbbbbbbbfcccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555500000000000
00000005555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550000000000
000000055aa55aa55aa555a555777755557777777777777777777555777755777777755777555557777777777777777777775557777755577559950000000000
000000055aa55aa55aaa55a557755755557775555555755555775557755755775555555777555577557755555755557755577557755775577559950000000000
000000055aa55aa55aaaa5a557755555577577555557755555775557755555775555557757755577555555557755557755577557755775557779550000000000
000000055aa55aa55a1aaaa555777555577577555557755555775555777555775775557757755577555555557755557755577557757755557779500000000000
000000055aa55aa55a51aaa555577755775777755557755555775555577755775555577577775577555555557755557755577557757555555775500000000000
00000005599559955955199556556655665116655556655555665556556655665555566555665566556655556655556655566556656655555665000000000000
00000005519999155955519556666155665556655556655556666556666155665555566555665516666155556655551666661556651665555665000000000000
00000005551111555155551551111555115551155551155551111551111555115555511555115551111555551155555111115551155115555115000000000000
00000001555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550000000000000
00000000111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccffbbbbbbbbbbbd6dd5bbbbbbbbbbbd6dd5bb3333e5bbb5dd53bbbbbbbbbbbd6dd5bb8f8222b1bbbbbbbbbd6dd5bbbbbbbbbb5d5555bbbbbb33bbbffcccc
ccccffbbbbbbbbbbb35dd553bbbbbbbbb35dd553b3f3355bbb56653bbbbbbbbbb35dd553bbb22bb1bbbbbbbbb35dd553bbbbbbbb33511133bb3bbbbbbfbffccc
ccccfffbbbbbbbbbbb35553bbbbbbbbbbb35553bbb3355bbbb5dd53bbbbbbbbbbb35553bbbbbbbb1bbbbbbbbbb35553bbbbbbbbbbb3333bbbbb3bbbbbbbffccc
ccccffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb44bbbbb56653bbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbffcccc
cccccfbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb955aa559bb56653bbbbbbbbbbbbbbbbbbbbbb1bb955aa559bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbfccccc
cccccffbbbb1dbbbbbb3bbbbbbbbbbbbbbbbbbbb56666665bb56653bbbb3bbbbb91bb19bbbbb1bbb56666665bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbfccccc
cccccfbbbbaa19bbb33bbbbbbb99555555555555567f6665bb56653bb33bbbbbb91ba19b5555155556a9666555555555555599bbbbbbbbbbbbbbbbbbbbffcccc
ccccccfbbbb6d1b3bbbb3bbbbb97f6666667f666a6667f6abb56653bbbbb3bbb591bb1956d6196d6a666a96a666a9666666a993bbbbbbbbbbbbbbbbbbbbfcccc
cccccffbbbaaa913bbbbb33bbb56d666666d6666a67f666abb5dd53bbbbbb33b599bb9956d16d6d6a6a9666a6666d666666d653bbbbbbbbbbbbbbbbbbbffcccc
ccccffbbbbb6d3311b3bbbbbbb5665555555555556667f65bb56653bbb3bbbbbb9999993515555555666a965555555555556653bbbbbbbbbbbbbbbbbbfbffccc
ccccfffbbb66dd3bb1b3bbbbbb5665333333333356666665bb56653bbbb3bbbb995555993133333356666665333333333356653bbbbbbbbbbbbbbbbbbbbffccc
ccccffbbbbbbbbbbbb1bbbbbbb5665bbbbbbbbbb955aa559bb56653bbbbbbbbb22b333221bbbbbbb955aa559bbbbbbbbbb56653bbbbbbbbbbbbbbbbbbbffcccc
cccccfbbbbbbbbbbbbb1bbbbbb56653bbbbbbbbbbb56653bbb56653bbbbbbbbbbb566531bbbbbbbbbb56653bbbbbbbbbbb56653bbbbbbbbbbbbbbbbbbbfccccc
cccccffbbbbbbbbbbbbb1bbbbb56653bbbbdddbbbb56653bbb56653bbbbbbbbbbb56651bbbbbbbbbbb56653bbbbbbbbbbb56653bbbbbbbbbbbbbbbbbbbfccccc
cccccfbbbbbbbbbbbbbbb1bbbb56653bbbdd6ddbbb56653bbb56653bbbbbbbbbbb56613bbbbbbbbbbb56653bbbbbddbbbb56653bbbbbbbbbbbbbbbbbbbffcccc
ccccccfbbbbbbbbbbbbbbb1bbb57f53bbdddd5dbbb57f53bbb56653bbbbbbbbbbb5dd13bbbbbbbbbbb5dd53bbbbd6ddbbb5a953bbbbbbbbbbbbbbbbbbbbfcccc
cccccffbbbbbbbbbbbbbbbb1bb5dd53bb5d5555bbb56653bbb5dd53bbbbbbbbbbb56153bbbbbbbbbbb56653bbbd6dd5bbb5dd53bbbbbbbbbbbbbbbbbbbffcccc
ccccffbbbbbbbbbbbbbbbbbb1b56653b33511133bb57f53bbb56653bbbbbbbbbbb51653bbbbbbbbbbb5a953bb35dd553bb56653bbbbbbbbbbbbbbbbbbfbffccc
ccccfffbbbbbbbbbbbbbbbbbb116653bbb3333bbbb56653bbb56653bbbbbbbbbbb16653bbbbbbbbbbb56653bbb35553bbb56653bbbbbbbbbbbbbbbbbbbbffccc
ccccffbbbbbbbbbbbbbbbbbbbb51653bbbbbbbbbbb56653bbb56653bbbbbbbbbb156653bbbbbbbbbbb56653bbbbbbbbbbb56653bbbbbbbbbbbbbbbbbbbffcccc
cccccfbbbbbbbbbbbbbbbbbbbb56153bbbbbbbbbbb5665bbb666666bbbbbbbbb915aa559bbbbbbbbbbbbbbbbbbbbbbbbbb5665bbbbbbbbbbaaabbaa9bbfccccc
cccccffbbbb3bbbbbbbbbbbbbb56613bbbbbbbbbbb5665bb66aaa666bbbbbbbb16666665bbbbbbbbb91bb19bbbbbbbbbbb5665bbbbbbbbbbabaa99b9bbfccccc
cccccfbbb33bbbbbbbbbbbbbbb56651bbbbbbbbbbb5665556a999aa6555555515666666555555555b91ba19bbbbbbbbbbb56655555555555abb76b39bbffcccc
ccccccfbbbbb3bbbbbbbbbbbbb57f531bbbbbbbbbb57f7f6599799956a9a9616a666666a666a9666591bb195bbbbbbbbbb5a9666666a96665b466435bbbfcccc
cccccffbbbbbb33bbbbbbbbbbb5dd53b11bbbbbbbb9566665999999569999166a666666a66699666599bb995bbbbbbbbbb9566666666d6665a9679a5bbffcccc
ccccffbbbb3bbbbbbbbbbbbbbb56653bbb1bbbbbbb9955556979779d555551555666666555555555b9999993bbbbbbbbbb99555555555555b9945993bfbffccc
ccccfffbbbb3bbbbbbbbbbbbbb56653bbbb11bbbbbb333336995599d33331333566666653333333399555599bbbbbbbbbbb3333333333333b4999953bbbffccc
ccccffbbbbbbbbbbbbbbbbbbbb56653bbbbbb1bbbbbbbbbbb45665d3bbb1bbbb955aa559bbbbbbbb22b33322bbbbbbbbbbbbbbbbbbbbbbbbb4445553bbffcccc
cccccfbbaaabbaa9bbbbbbbbbb56653bbbbbbb1bbbbbbbbbbbbbbbbbbb1bbbbbbb56653bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbfccccc
cccccffbabaa99b9bbbbbbbbbb56653bbb3333b11bb3bbbbbbbbbbbbb1bbbbbbbb56653bbbbbbbbbbbbbbbbbbbb3bbbbbbbdddbbb111dbbbbbbbbbbbbbfccccc
cccccfbbabb76b39555555555556653bbb3f333bb13bbbbbbbbbbbbbb1bbddbbbb56653bbbbbbbbbbbbbbbbbb33bbbbbbbdd11111baaa9bbbbbbbbbbbbffcccc
ccccccfb5b4664356667f6666667f53bb333355bbb113bbbbbbbbbbb1bbd6ddbbb5dd53bbbbbbbbbbbbbbbbbbbbb3bbb1111d5dbbbb6dbb3bbbbbbbbbbbfcccc
cccccffb5af67fa5666d66666666593bb3333e5bbbbb133bbbbbbbb1bbd6dd5bbb56653bbbbbbbbbbbbbbbbbbbb11111b5d5555bbbaaa933bbbbbbbbbbffcccc
ccccffbbb9f45f93555555555555993bb3f3355bbb3bb11bbbbbbb1bb35dd553bb56653bbbbbbbbbbbbbbb11111bbbbb33511133bbb6d33bbbbbbbbbbfbffccc
ccccfffbb4ffff53333333333333333bbb3355bbbbb3bbb1bbbbb1bbbb35553bbb56653bbbbbbbbbbb1111bbbbb3bbbbbb3333bbbb66dd3bbbbbbbbbbbbffccc
ccccffbbb4445553bbbbbbbbbbbbbbbbbbb44bbbbbbbbbbb1bbbb1bbbbbbbbbbbb56653b1111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbffcccc
cccccfbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1111bbbbb11111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb955aa559bbfccccc
cccccffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1111111bbbbbbbb5665bbbbbbbbbbbbbbbbbbb91bb19bbbbbbbbbbbbbbbbb56666665bbfccccc
cccccfbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1119bbbbbbddbbbb5665555555555555555555b91ba19b555555555555555556a96665bbffcccc
ccccccfbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb519aa955bbbd6ddbbb5a9666666d6666666d6666591bb195666a9666666d6666a699a96abbbfcccc
cccccffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb169aa965bbd6dd5bbb999666666d6666666d6666599bb99566699666666d6666a6a9996abbffcccc
ccccffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1b99a8993b35dd553bb9955555555555555555555b999999355555555555555555699a965bfbffccc
ccccfffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1b9988993bb35553bbbb33333333333333333333399555599333333333333333356669965bbbffccc
ccccffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bb2b11323bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb22b33322bbbbbbbbbbbbbbbb955aa559bbffcccc
cccccfbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbb56653bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbfccccc
cccccffbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbb1bbbbb5d153bbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbdddbbbb3333bbbbbbbbbbbbfccccc
cccccfbbbbbbbbbbbbbbbbbbbbbbbbbbb33bbbbbbbb1bbbbbb56653bbbbbbbbbb33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbdd6ddbbb3f333bbbbbbbbbbbffcccc
ccccccfbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbb1bbbbbbb5d153bbbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbdddd5dbb333355bbbbbbbbbbbbfcccc
cccccffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33bb1bbbbbbbb5dd53bbbbbbbbbbbbbb33bbbbbbbbbbbbbbbbbbbbbbbbbb5d5555bb3333e5bbbbbbbbbbbffcccc
ccccffbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbb1bbbbbbbbb56653bbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbb33511133b3f3355bbbbbbbbbbfbffccc
ccccfffbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbb1bbbbbbbbbb56653bbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333bbbb3355bbbbbbbbbbbbbffccc
ccccffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbbb56653bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb44bbbbbbbbbbbbbffcccc
cccccfbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1bbbbbbbbbbb5665bbbbbbbbbbbbbbbbbb955aa559bbbbbbbbbbbbbbbbbbbbbbbbaaabbaa9bbbbbbbbbbfccccc
cccccffbbbbbbbbbb91bb19bbbbbbbbbbbbbb1bbbb3333bbbb5d15bbbbbbbbbbbbbbbbbb56666665bbbbbbbbbbbbbbbbbbbbbbbbabaa99b9bbbbbbbbbbfccccc
cccccfbbbbbbbbbbb91ba19b55555555555519bbbb3f333bbb566555555555555555555556d16665555555555555555555555555abb76b39bbbbddbbbbffcccc
ccccccfbbbbbbbbb591bb1956666d6666661593bb333355bbb5d16666d1d16666d1d1666a666d16a666d1666666d1666666d16665b466435bbbd6ddbbbbfcccc
cccccffbbbbbbbbb599bb9956666d666661d653bb3333e5bbb9566666666d6666666d666a6d1666a6666d6666666d6666666d6665a1671a5bbd6dd5bbbffcccc
ccccffbbbbbbbbbbb9999993555555555156653bb3f3355bbb99555555555555555555555666d165555555555555555555555555b9145193b35dd553bfbffccc
ccccfffbbbbbbbbb99555599333333331356653bbb3355bbbbb33333333333333333333356666665333333333333333333333333b4111153bb35553bbbbffccc
ccccffbbbbbbbbbb22b33322bbbbbb11bb56653bbbb44bbbbbbbbbbbbbbbbbbbbbbbbbbb955aa559bbbbbbbbbbbbbbbbbbbbbbbbb4445553bbbbbbbbbbffcccc
cccccfbbbbbbbbbbbbbbbbbbbbbbb1bbbb56653bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb56653bbbbbbbbbbbbbbbbbaaabbaa9bbbbbbbbbbbbbbbbbbfccccc
cccccffbbbbbbbbbbbbbbbbbbbbb1bbbbb56653bbbbdddbbbbb3bbbbbbbbbbbbbbbbbbbbbb56653bbbbbbbbbbbbbbbbbabaa99b9bbbbbbbbbbbbbbbbbbfccccc
cccccfbbbbbbbbbbbbbbbbbbbbb1bbbbbb56653bbbdd6ddbb33bbbbbbbbbbbbbbb9955555556653bbb99555555555555abb76b39bbbbbbbbbbbbbbbbbbffcccc
ccccccfbbbbbbbbbbbbbbbbbbb1bbbbbbb56653bbdddd5dbbbbb3bbbbbbbbbbbbb9d16666d1d153bbb9ed6d66eded6665b466435bbbbbbbbbbbbbbbbbbbfcccc
cccccffbbbbbbbbbbbbbbbbbb1bbbbbbbb5dd53bb5d5555bbbbbb33bbbbbbbbbbb56d6666666593bbb56d6d66666d6665ad67da5bbbbbbbbbbbbbbbbbbffcccc
ccccffbbbbbbbbbbbbbbbbbb1bbbbbbbbb56653b33511133bb3bbbbbbbbbbbbbbb5d15555555993bbb5ed55555555555b9d45d93bbbbbbbbbbbbbbbbbfbffccc
ccccfffbbbbbbbbbbbbbbb11bbbbbbbbbb56653bbb3333bbbbb3bbbbbbbbbbbbbb5665333333333bbb5dd53333333333b4dddd53bbbbbbbbbbbbbbbbbbbffccc
ccccffbbbbbbbbbbbbbbb1bbbbbbbbbbbb56653bbbbbbbbbbbbbbbbbbbbbbbbbbb5665bbbbbbbbbbbb5665bbbbbbbbbbb4445553bbbbbbbbbbbbbbbbbbffcccc
cccccfbbbbbbbbbbbbbb1bbbbbbbbbbb955aa559bbbbbbbbbbbbbbbbbbbbbbbbb666666bbbbbbbbbbb56653bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbfccccc
cccccffbbbbbbbbbbbb1dbbbbbb3bbbb56666665bbbbbbbbbbbbbbbbbbbbbbbb66aaa666bbbbbbbbbb5dd53bbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbfccccc
cccccfbbbbbbddbbbbaaa9bbb33bbbbb566666655555555555555555555555556a999aa6555555555556653bbbbbbbbbbb8882bbb33bbbbbbbbbbbbbbbffcccc
ccccccfbbbbd6ddbbbb6dbb3bbbb3bbba666666a6666d6666666d6666666d666599799956eded6d66eded53bbbbbbbbbb8888e2bbbbb3bbbbbbbbbbbbbbfcccc
cccccffbbbd6dd5bbbaaa933bbbbb33ba666666a6666d6666666d6666666d666599999956d66d6d66d66593bbbbbbbbbb8f8222bbbbbb33bbbbbbbbbbbffcccc
ccccffbbb35dd553bbb6d33bbb3bbbbb566666655555555555555555555555556979779d555555555155993bbbbbbbbbbbb22bbbbb3bbbbbbbbbbbbbbfbffccc
ccccfffbbb35553bbb66dd3bbbb3bbbb566666653333333333333333333333336995599d333333331133333bbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbbffccc
ccccffbbbbbbbbbbbbbbbbbbbbbbbbbb955aa559bbbbbbbbbbbbbbbbbbbbbbbbb45665d3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbffcccc
cccccfbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbfccccc
cccccffbbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbfccccc
cccccfbbbbbbddbbb33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3f333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbffcccc
ccccccfbbbbd6ddbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb335355bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbfcccc
cccccffbbbd6dd5bbbbbb33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3553e5bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbffcccc
ccccffbbb35dd553bb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3f3355bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbfbffccc
ccccfffbbb35553bbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3355bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbffccc
ccccffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb44bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbffcccc
cccccf11111bbbbbbb11b111b111b1b1b111b111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb111b111b11bb1b1bbbbbb11111ccccc
ccccc11ffb11fffbf1bff1f1fb1ff1f1f1bff1f1fbbffffbfbbffffbfbbffffbfbbffffbfbbffffbfbbffffbfbbffffbf111f1fbf1b1f1f1fbbff11b1c11cccc
c7ccc11f1f11cffff1fcc111ff1cc111f11cc11ffffccffffffccffffffccffffffccffffffccffffffccffffffccffff1f1c11ff1f1c1f1fffcc111c111cccc
ccccc11ccf11cccfc1c1c1c1cf1cc1c1c1ccc1c1cfcccccfcfcccccfcfcccccfcfcccccfcfcccccfcfcccccfcfcccccfc1c1c1cfc1c1c1c1cfccc11f1c11cccc
cccccc11111cccccc111c1c1cc1cc1c1c111c1c1ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1c1c111c1c1cc11cccccc111117cccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77cc
ccc7cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

__gff__
0000000000000000000000000101010100000000000000000000000001010101000000000000000000000000000000000000000000000000000000000000000000000303030000000000000000000000000001030103030300000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0f0c0c5255540c0c0c0c0c0c0c0c0c0e22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c11101011101010111010111010100d22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c10101110101110101010101011100d22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c10111010111011101110101410100d22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c10101010141010111010111010110d22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c10111010101111101011101110100d22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c10101011101010101011111010100d22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c11101010101111101114101011100d22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c10111011111010111010111010100d22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c10101010101410101011101010100d22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c10101011101010111010101014100d22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c10111110101011101010101110100d22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c10101010111110101110111010100d22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c10101110101410111011101011100d22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c10111010101010101010101010100d22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1e1d1d1d1d1d1d1d1d1d1d1d1d1d1d1f22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010a00200407304000211000f6000c6110060004073026000061300000000000000004073000000c0210000018615026000061103600040730360004033026000c6000000004033000000061100000006110c600
011400200011000110001100011000110001100011000110001100011000110001100011000110001130010002110021100211002113041000b10005100001000010000100021100211002110021130010000000
011e00000973109735097310973509731097350973109735097310973509731097350973109735097310973306731067350673106735067310673506731067350673106735067310673506731067350673106735
391e00000607303000060730000018615000000061600000006160000006073000001861500000000000000006073030000607300000186150000000611000000061600000090730000018615000000000000000
011e0000150202100121721210002802221022280222102215020210012172100000210222802621022280231202021001217210000028022210222802621022120202100121721000002102228026210221c023
011000000973109731097310973109731097310973509725097150971509715097150971509715097150971500000000000000000000000000000000000000000000000000000000000000000000000000000000
c91e00001755214552145021455000500125001450015500005001455017550185501755001500145501e50017550145501450014550005001250014500155001e5001455017550185501c550015001455000500
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500000067002640036400164002643026200162301725000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500001b050250531d0530806001740017200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010700001c0511d0501d0501d0501d0502e0002205222052220522205222052220522205525000250001800014000120000000000000000000000000000000000000000000000000000000000000000000000000
010300000c61000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000170002700027000274202752027600276002762027620276202732027220271500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400000c0201005005700057000570005700057000570005700057000670006700107001170011700107000e7000e7000e70009700097000970000000000000000000000000000000000000000000000000000
010300000c0101c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 03040544
00 03040544
04 06424344
00 07044344

