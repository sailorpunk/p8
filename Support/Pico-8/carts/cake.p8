pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--cake monsters
--by three twins games

function _init()
	cartdata("ttg_cake")
	last_level=dget(0)
	version="v2.0"
	map_setup()
	monster_setup()
	menu_setup()
	timer=0
	timer_instructions=0
	timer_level=45
	total_levels=36
	game_over=false
	anim=true
	menu=true
	init_intro()
	particles={}
	continued=false
	t=0
	fl=0
	shake=0
	alltilemaps={}
	allmonsters={}
end

function _update()
	t+=1
	if mode=="intro" then
		update_intro()
	elseif mode=="logo" then
		update_logo()
	elseif mode=="outro" then
		update_outro()
	elseif mode=="title" then
		if not menu and not game_over and not level_screen then
			update_particles()
			check_cakes()
			timer_instructions+=1
			if not check_win() then
				get_state()
				move_monster()
				animate_monster()
				if btnp(❎) and not btn(🅾️) then
					reload()
					set_level()
					sfx(8)
				end
				if btnp(🅾️) and not btn(❎) then
					undo()
				end
				if btn(❎) and btn(🅾️) and level<total_levels then
					timer=0
					level+=1
					level_screen=true
					level_screen_setup()
					--set_level()
				end
			end
			check_win()
		elseif menu then
			update_menu()
		elseif level_screen then
			update_level_screen()
		elseif game_over then
			if btn(❎) then
				last_level=0
				dset(0,last_level)
				extcmd("reset")
			end
		end
	end
end

function _draw()
	if mode=="intro" then
		draw_intro()
	elseif mode=="logo" then
		draw_logo()
	elseif mode=="outro" then
		draw_outro()
	elseif mode=="title" then
		cls(1)
		if not menu and not game_over and not level_screen then
			draw_map()
			draw_monster()
			draw_particles()
			if #monsters>0 then
				local scol=6
				if t%30<15 then
					scol=6
				else
					scol=7
				end
				string="❎ to reset / 🅾️ to undo"
				print(string,mapx*8+59-#string*2,mapy*8+121,scol)
				string="level: "..level.."/"..total_levels
				print(string,mapx*8+63-#string*2,mapy*8+2,6)	
			end	
		elseif menu then
			draw_menu()
			draw_particles()
			print(version,1,1,5)
		elseif level_screen	then
			if (level==1 and rectt==nil)
			or continued then
				cls(1)
				fillp(▒)
				rectfill(0,0,127,127,0)
				fillp()
			else
				draw_map()
				draw_monster()
			end
			draw_level_screen()
		elseif game_over then
			draw_win()
		end
	end
	--print(#alltilemaps,mapx*8,mapy*8,7)
end
-->8
--map and particles code

function map_setup()
	--map tile settings
	wall={16,17,18,19,20,21,22,23}
	cake={17,18,19,20,21,22,23}
	red_cake=17
	yellow_cake=18
	blue_cake=19
	green_cake=20
	purple_cake=21
	orange_cake=22
	brown_cake=23
	floor=32
	trap={48}
end

function draw_map()
	--moves the camera to the quadrant the monsters are in
	--camera(mapx*8,mapy*8)
	doshake()
	if fl>0 then
		fl-=1
		cls(2)
	else
		cls(1)
	end
	fillp(▒)
	rectfill(mapx*8,mapy*8,mapx*8+127,mapy*8+127,0)
	fillp()
	map(0,0,0,0,128,64)
end

function is_tile(tile_type,x,y)
	--returns what kind of tile the coordinates hold
	tile=mget(x,y)
	for i=1,#tile_type do
		if tile==tile_type[i] then
			return true
		end
	end	
	return false
end

function can_move(x,y)
	--returns if the player can move
	if is_tile(wall,x,y) then
		return false
	else
		return true
	end
end

function eat_cake(monster_color,x,y)
	--swaps a cake tile for a floor tile
	mset(x,y,floor)
	sfx(0)
	create_particles(monster_color,x*8+4,y*8+4)
end

function create_particles(pmonster_color,px,py,istrap)
	for i=1,10 do
		local p={}
		p.x=px
		p.y=py
		p.ang=rnd()
		p.sx=sin(p.ang)/(0.4+rnd())
		p.sy=cos(p.ang)/(0.4+rnd())
		p.age=rnd(10)
		p.maxage=30
		p.size=4
		if pmonster_color==1 then
			p.cs={9,8,2}
		elseif pmonster_color==2 then
			p.cs={15,10,9}
		elseif pmonster_color==3 then
			p.cs={7,12,1}
		elseif pmonster_color==4 then
			p.cs={10,11,3}
		elseif pmonster_color==5 then
			p.cs={14,2,1}
		elseif pmonster_color==6 then
			p.cs={10,9,8}
		elseif pmonster_color==7 then
			p.cs={9,4,5}
		end
		if istrap then
			p.cs={7,6,5}
			p.sx=sin(p.ang)*(1+rnd())
			p.sy=cos(p.ang)*(1+rnd())
		end
		add(particles,p)	
	end
end

function create_spark(px,py)
	for i=1,2 do
		local p={}
		p.x=px
		p.y=py
		if rnd()<0.5 then
			p.ang=rnd(15)/100
		else
			p.ang=rnd(15)/100+0.85
		end
		p.sx=sin(p.ang)/(1+rnd())
		p.sy=cos(p.ang)/(1+rnd())
		p.age=rnd(5)
		p.maxage=10
		p.size=2
		p.cs={6,7}
		p.spark=true
		add(particles,p)	
	end
end

function update_particles()
	
end

function draw_particles()
	for p in all(particles) do
		p.x+=p.sx
		p.y+=p.sy
		p.age+=1
		p.sx*=0.9
		p.sy*=0.9
		if p.age>p.maxage then
			del(particles,p)
		end
		if not p.spark then
			if p.age<10 then
				p.size=4
				p.ci=1
			elseif p.age<15 then
				p.size=4
				p.ci=2
			elseif p.age<20 then
				p.size=3
				p.ci=2
			elseif p.age<25 then
				p.size=2
				p.ci=3
			elseif p.age<p.maxage then
				p.size=1
				p.ci=3
			end
			circfill(p.x,p.y,p.size,p.cs[p.ci])
			if p.size>1 then
				circ(p.x,p.y,p.size,p.cs[p.ci+1])
			end
		else
			if p.age<5 then
				p.size=1
				circfill(p.x,p.y,p.size,p.cs[1])
			elseif p.age<p.maxage then
				p.c=6
				pset(p.x,p.y,p.cs[2])
			end
		end
	end
end

function reset_tiles() 
	--resets tiles with same layout as level 28
	for y=54,57 do
		for x=54,57 do
			mset(x,y,floor)
		end
	end
end

function doshake()
	local shakex=rnd(shake)-(shake/2)
	local shakey=rnd(shake)-(shake/2)
	camera(mapx*8+shakex,mapy*8+shakey)
	
	if shake>10 then
		shake*=0.9
	else
		shake-=1
		if shake<1 then
			shake=0
		end
	end
end
		
-->8
 --player code

function monster_setup()
	--assign sprite numbers to different monsters
	red_monster=1
	yellow_monster=2
	blue_monster=3
	green_monster=4
	purple_monster=5
	orange_monster=6
	brown_monster=7
	--create table that will hold monsters
	monsters={}
	--add monsters to the table for the menu screen
	make_monster(red_monster,2.5,10)
	make_monster(orange_monster,4.5,10)
	make_monster(yellow_monster,6.5,10)
	make_monster(green_monster,8.5,10)
	make_monster(blue_monster,10.5,10)
	make_monster(purple_monster,12.5,10)
end

function make_monster(sprite,x,y)
	--create monster and add it to monster list
	local monster={
		sprite=sprite,
		x=x,
		y=y
		}
	monster.anim_frames={1,2,3,4,5,6}
	monster.frame=ceil(rnd(#monster.anim_frames))
	monster.anim_speed=0.4
	monster.spr=monster.anim_frames[monster.frame]
	monster.flash=0
	add(monsters,monster)
	--set map coordinates based on monster
	mapx=flr(monster.x/16)*16
	mapy=flr(monster.y/16)*16
end

function animate_monster()
	for monster in all(monsters) do
		monster.frame+=monster.anim_speed
		if flr(monster.frame)>#monster.anim_frames then
			monster.frame=1
		end
		monster.spr=monster.anim_frames[flr(monster.frame)]
		if monster.spr==3 then
			if rnd()<0.2 then
				create_spark(monster.x*8+4,monster.y*8+5,false)
			end
		end
	end
end

function draw_monster()
	if #monsters>0 then
		for monster in all(monsters) do
			set_monster_color(monster)
			flash(monster)
			if level_screen then
				monster.spr=1
			end
			spr(monster.spr,monster.x*8,monster.y*8)
			pal()
		end
	else
		wait-=1
		if wait<=0 then
		cls(1)
			rect(mapx*8+28,mapy*8+53,mapx*8+100,mapy*8+83,5)
			rectfill(mapx*8+29,mapy*8+54,mapx*8+99,mapy*8+82,6)
			print("no monsters left!",mapx*8+31,mapy*8+56,13)
			print("❎ to reset",mapx*8+31,mapy*8+66,13)
			print("🅾️ to undo",mapx*8+31,mapy*8+76,13)
		end
	end
end

function flash(obj)
	if obj.flash>0 then
		obj.flash-=1
		if t%12<4 then
			for i=0,15 do
				pal(i,7)
			end
		end
	end
end

function move_monster()
	--first we check what the next two tiles are
	for monster in all(monsters) do
		monster.newx=monster.x
		monster.newy=monster.y
		monster.xbeyond=monster.x
		monster.ybeyond=monster.y
		new_color=monster.sprite
	
		if btnp(⬅️) then
			monster.newx-=1
			monster.xbeyond=monster.newx-1
		end
		if btnp(➡️) then
			monster.newx+=1
			monster.xbeyond=monster.newx+1
		end
		if btnp(⬆️) then
			monster.newy-=1
			monster.ybeyond=monster.newy-1
		end
		if btnp(⬇️) then
			monster.newy+=1
			monster.ybeyond=monster.newy+1
		end
		
		--we check for traps
		if is_tile(trap,monster.newx,monster.newy) then
			create_particles(new_color,monster.newx*8+4,monster.newy*8+4,true)
			del(monsters,monster)
			shake=20
			fl=10
			if #monsters==0 then
				wait=30
			end
			sfx(1)
		end
		--we check if the monster can eat the cake
		interact_with_cake(monster)
		--we check if the monster has to eat another monster
		interact_with_monster(monster)
		--we check if the monster needs to change color
		monster.sprite=new_color
		--then we check if the monster can move
		if can_move(monster.newx,monster.newy) then
			monster.x=mid(0,monster.newx,127)
			monster.y=mid(0,monster.newy,127)
		end
	end
end

function interact_with_cake(m)
	--eat the cake if it's same color
	local monster_color=m.sprite
	local x=m.newx
	local y=m.newy
	if is_tile(cake,x,y) and
	same_color(monster_color,x,y) then
		eat_cake(monster_color,x,y)
		m.flash=20
		check_cakes()
		if cakes==0 then
			if level==total_levels then
				sfx(5)
			else
				sfx(4)
			end
		end
	end
end

function same_color(monster_color,x,y)
	--16 is the distance between cakes and monsters of the same color in the sprite editor 
	tile=mget(x,y)
	if tile-monster_color==16 then
		return true
	else
		return false
	end
end

--function interact_with_monster(x,y,xbeyond,ybeyond,monster_color)
function interact_with_monster(monster)
	--we eat a monster when we move if it is adjacent to us and blocked by a wall
	local x=monster.newx
	local y=monster.newy
	local xbeyond=monster.xbeyond
	local ybeyond=monster.ybeyond
	local monster_color=monster.sprite
	tile=mget(xbeyond,ybeyond)
	if is_tile(wall,xbeyond,ybeyond) and
	there_is_monster(x,y)	then
		there_is_monster(x,y)
		local nc=change_color(monster_color,food_color)
		create_particles(nc,x*8+4,y*8+4)
		monster.flash=20
		shake=6
		fl=4
	end
end

function there_is_monster(x,y)
	for monster in all(monsters) do
		if monster.x==x and
		monster.y==y and
		tile-monster.sprite!=16 then
			--store monsters color in new variable
			food_color=monster.sprite
			--eat the monster 
			del(monsters,monster) 
			sfx(2)
			return true
		end
	end
end

function change_color(monster_color,food_color)
	--change color if monsters have different colors
	if monster_color!=food_color then
		if monster_color==red_monster then
			if food_color==yellow_monster then
				new_color=orange_monster
			elseif food_color==blue_monster then
				new_color=purple_monster
			else
				new_color=brown_monster
			end
		elseif monster_color==yellow_monster then
			if food_color==red_monster then
				new_color=orange_monster
			elseif food_color==blue_monster then
				new_color=green_monster
			else
				new_color=brown_monster
			end
		elseif monster_color==blue_monster then
			if food_color==red_monster then
				new_color=purple_monster
			elseif food_color==yellow_monster then
				new_color=green_monster
			else
				new_color=brown_monster
			end
		else
			new_color=brown_monster
		end
	else
		new_color=monster_color
	end
	return new_color
end

function set_level()
	allmonsters={}
	alltilemaps={}
	monsters={} 
	if level==1 then
		make_monster(red_monster,6,7 )
	elseif level==2 then   
		make_monster(red_monster,19,3)
		make_monster(yellow_monster,28,5)
		make_monster(blue_monster,20,11)
		make_monster(green_monster,25,11)
	elseif level==3 then
		make_monster(red_monster,36,6)
		make_monster(yellow_monster,38,9)
	elseif level==4 then
		make_monster(red_monster,53,7)
		make_monster(blue_monster,57,7)
	elseif level==5 then
		make_monster(red_monster,69,4)
		make_monster(yellow_monster,70,4)
		make_monster(blue_monster,71,4)
		make_monster(purple_monster,72,4)
		make_monster(orange_monster,73,4)
		make_monster(green_monster,74,4)
	elseif level==6 then
		make_monster(yellow_monster,83,5)
		make_monster(blue_monster,83,6)
	elseif level==7 then
		make_monster(red_monster,102,6)
		make_monster(blue_monster,104,8)
	elseif level==8 then
		make_monster(red_monster,118,6)
		make_monster(blue_monster,118,7)
	elseif level==9 then
		make_monster(red_monster,5,22)
		make_monster(yellow_monster,5,25)
		make_monster(blue_monster,9,22)
		make_monster(blue_monster,9,25)
	elseif level==10 then
		make_monster(yellow_monster,21,24)
		make_monster(blue_monster,25,22)
	elseif level==11 then
		make_monster(red_monster,38,22)
		make_monster(yellow_monster,38,25)
		make_monster(blue_monster,41,22)
	elseif level==12 then
		make_monster(blue_monster,52,19)
		make_monster(yellow_monster,52,23)
		make_monster(yellow_monster,52,24)
		make_monster(red_monster,52,28)
	elseif level==13 then
		make_monster(red_monster,69,21)
		make_monster(yellow_monster,69,22)
		make_monster(red_monster,69,23)
		make_monster(yellow_monster,69,24)
		make_monster(blue_monster,71,21)
		make_monster(blue_monster,71,22)
		make_monster(blue_monster,71,23)
		make_monster(blue_monster,71,24)
		make_monster(yellow_monster,73,21)
		make_monster(red_monster,73,22)
		make_monster(yellow_monster,73,23)
		make_monster(red_monster,73,24)
	elseif level==14 then
		make_monster(red_monster,86,21)
		make_monster(yellow_monster,86,25)
		make_monster(blue_monster,88,21)
		make_monster(yellow_monster,88,25)
	elseif level==15 then
		make_monster(purple_monster,105,22)
	elseif level==16 then
		make_monster(red_monster,118,22)
		make_monster(red_monster,118,23)
		make_monster(yellow_monster,118,24)
		make_monster(red_monster,120,22)
		make_monster(yellow_monster,120,23)
		make_monster(yellow_monster,120,24)
	elseif level==17 then
		make_monster(blue_monster,6,38) 
		make_monster(yellow_monster,6,39) 
		make_monster(yellow_monster,6,40) 
		make_monster(blue_monster,6,41)
		make_monster(blue_monster,9,38) 
		make_monster(yellow_monster,9,39) 
		make_monster(yellow_monster,9,40) 
		make_monster(blue_monster,9,41) 
	elseif level==18 then
		make_monster(red_monster,21,38) 
		make_monster(blue_monster,21,40) 
		make_monster(red_monster,25,38) 
		make_monster(blue_monster,25,40) 
	elseif level==19 then
		make_monster(red_monster,38,39) 
		make_monster(blue_monster,40,39) 
	elseif level==20 then
		make_monster(red_monster,53,39)
		make_monster(blue_monster,58,38)
	elseif level==21 then
		make_monster(red_monster,70,38)
		make_monster(yellow_monster,70,39)
	elseif level==22 then
		make_monster(yellow_monster,85,37)
		make_monster(blue_monster,87,37)
		make_monster(red_monster,87,38)
		make_monster(yellow_monster,89,37)
	elseif level==23 then
		make_monster(red_monster,104,40)
		make_monster(blue_monster,107,36)
	elseif level==24 then
		make_monster(red_monster,116,36)
		make_monster(red_monster,117,36)
		make_monster(red_monster,118,36)
		make_monster(yellow_monster,116,38)
		make_monster(yellow_monster,117,38)
		make_monster(yellow_monster,118,38)
		make_monster(blue_monster,116,40)
		make_monster(blue_monster,117,40)
		make_monster(blue_monster,118,40)
	elseif level==25 then
		make_monster(red_monster,6,54)
		make_monster(blue_monster,7,57)
		make_monster(yellow_monster,9,54)
		make_monster(yellow_monster,9,57)
	elseif level==26 then
		make_monster(red_monster,19,51)
		make_monster(blue_monster,19,59)
		make_monster(yellow_monster,27,51)
		make_monster(green_monster,27,59)
	elseif level==27 then
		make_monster(blue_monster,38,53)
		make_monster(red_monster,38,54)
		make_monster(red_monster,39,54)
		make_monster(blue_monster,40,53)	
		make_monster(yellow_monster,40,54)	
	--level 28 looks similar to a lot other levels, so we use it as a blueprint
	elseif level==28 then
		reset_tiles()
		mset(54,54,green_cake)
		mset(54,57,green_cake)
		mset(55,57,green_cake)
		mset(56,57,green_cake)
		mset(57,54,green_cake)
		mset(57,57,green_cake)
		make_monster(yellow_monster,54,55)
		make_monster(blue_monster,54,56)
		make_monster(yellow_monster,55,54)
		make_monster(blue_monster,55,55)
		make_monster(blue_monster,55,56)
		make_monster(blue_monster,56,54)
		make_monster(yellow_monster,56,55)
		make_monster(blue_monster,56,56)
		make_monster(blue_monster,57,55)
		make_monster(blue_monster,57,56)
	elseif level==29 then
		reset_tiles()
		mset(56,55,orange_cake)
		mset(54,56,red_cake)
		mset(54,57,blue_cake)
		mset(55,56,blue_cake)
		mset(55,57,red_cake)
		mset(56,56,yellow_cake)
		mset(56,57,yellow_cake)
		mset(57,56,orange_cake)
		mset(57,57,orange_cake)
		make_monster(blue_monster,54,54)
		make_monster(red_monster,55,54)
		make_monster(yellow_monster,57,54)
	elseif level==30 then
		make_monster(green_monster,72,53)
		make_monster(red_monster,72,54)
		make_monster(yellow_monster,72,56)
		make_monster(blue_monster,72,57)
	elseif level==31 then
		reset_tiles()
		mset(54,56,orange_cake)
		mset(55,56,orange_cake)
		mset(56,56,orange_cake)
		mset(57,56,orange_cake)
		mset(54,57,yellow_cake)
		mset(55,57,yellow_cake)
		mset(56,57,yellow_cake)
		mset(57,57,yellow_cake)
		make_monster(yellow_monster,54,54)
		make_monster(yellow_monster,55,54)
		make_monster(yellow_monster,56,54)
		make_monster(yellow_monster,57,54)
		make_monster(red_monster,57,55)
	elseif level==32 then
		make_monster(yellow_monster,85,54)
		make_monster(red_monster,85,56)
		make_monster(yellow_monster,85,57)
		make_monster(blue_monster,86,55)
		make_monster(blue_monster,87,55)
		make_monster(yellow_monster,88,54)
		make_monster(red_monster,88,56)
		make_monster(yellow_monster,88,57)
	elseif level==33 then
		reset_tiles()
		mset(54,54,yellow_cake)
		mset(54,57,yellow_cake)
		mset(57,57,yellow_cake)
		mset(57,54,yellow_cake)
		mset(55,57,green_cake)
		mset(56,57,blue_cake)
		make_monster(yellow_monster,54,55)
		make_monster(blue_monster,55,54)
		make_monster(blue_monster,55,55)
		make_monster(blue_monster,56,54)
		make_monster(yellow_monster,56,55)
		make_monster(blue_monster,57,55)
	elseif level==34 then
		make_monster(yellow_monster,102,55)
		make_monster(yellow_monster,104,55)
		make_monster(yellow_monster,103,56)
		make_monster(red_monster,103,55)
	elseif level==35 then
		reset_tiles()
		mset(54,54,yellow_cake)
		mset(55,54,yellow_cake)
		mset(56,54,yellow_cake)
		mset(57,54,yellow_cake)
		mset(54,55,red_cake)
		mset(55,55,red_cake)
		mset(56,55,red_cake)
		mset(57,55,red_cake)
		mset(54,56,blue_cake)
		mset(55,56,blue_cake)
		mset(56,56,blue_cake)
		mset(57,56,blue_cake)
		make_monster(yellow_monster,54,57)
		make_monster(red_monster,55,57)
		make_monster(blue_monster,56,57)
	elseif level==36 then
		make_monster(yellow_monster,119,52)
		make_monster(blue_monster,119,54)
		make_monster(yellow_monster,120,55)
		make_monster(red_monster,118,56)
		make_monster(blue_monster,119,57)
		make_monster(orange_monster,119,59)
	end
	--this avoids being able to undo before moving each level
	get_tilemap()
	get_monsters()
end

function set_monster_color(m)
	if m.sprite==yellow_monster then
		pal(9,15)
		pal(8,10)
		pal(2,9)
	elseif m.sprite==blue_monster then
		pal(9,6)
		pal(8,12)
		pal(2,1)	
	elseif m.sprite==green_monster then
		pal(9,10)
		pal(8,11)
		pal(2,3)
	elseif m.sprite==purple_monster then
		pal(9,14)
		pal(8,2)
		pal(2,1)	
	elseif m.sprite==orange_monster then
		pal(9,10)
		pal(8,9)
		pal(2,8)	
	elseif m.sprite==brown_monster then
		pal(9,9)
		pal(8,4)
		pal(2,5)	
	end
end
-->8
--win/lose code

function check_cakes()
	--checks how many cakes there are
	cakes=0
	for x=mapx,mapx+15 do
		for y=mapy,mapy+15 do
			if is_tile(cake,x,y) then
				cakes+=1
			end
		end
	end
end

function check_win()
	--if there are no cakes we move to next level or win game
	if cakes==0 then
		--end game
		if level==total_levels then
			game_over=true
		--after a pause we move to next level
		else
			timer+=1
			if timer>=timer_level then
				timer=0
				level+=1
				level_screen_setup()
				level_screen=true
				--set_level()
			end
		end
		return true
	else
		return false
	end
end

function draw_win()
	camera()
	cls(13)
	string="well, you really"
	string2="took the cake!"
	string3="you win!"
	string4="press ❎ to play again"
	print(string,63-#string*2+1,45+1,1)
	print(string,63-#string*2,45,6)
	print(string2,63-#string2*2+1,53+1,1)
	print(string2,63-#string2*2,53,6)
	print(string3,63-#string3*2,68,6)
	print(string4,63-#string4*2,76,6)
end
-->8
--level screens code

function level_screen_setup()
	timer_level_screen=120
	particles={}
	init_rect()
	last_level=level
	dset(0,last_level)
	--sfx(6)
end

function update_level_screen()
	timer+=1
	update_rect()
	if timer>=timer_level_screen then
		timer=0
		sfx(8)
		level_screen=false
	end
end

function init_rect()
	rects={}
	for i=1,8 do
		local r={}
		if i%2==0 then
			r.x1=-128
			r.x2=-1
			r.dx=2
		else
			r.x1=128
			r.x2=255
			r.dx=-2
		end
		r.targetx=0
		r.y1=(i-1)*16
		r.y2=i*16
		add(rects,r)
	end
	rectt=nil
end

function update_rect()
	for i=1,#rects do
		ease(rects[i])
		if rectt!=nil and rectt<=t then
			set_level()
			continued=false
			if i%2==0 then
				rects[i].targetx=140
			else
				rects[i].targetx=140
			end
		end
	end
end

function draw_level_screen()
	camera()
	for i=1,#rects do
		local r=rects[i]
		rectfill(r.x1,r.y1,r.x2,r.y2,13)
		if i==4 then
			if level==total_levels then
				cprint("final challenge",r.x1+64,r.y1+7,1)
			else
				cprint("level "..level,r.x1+64,r.y1+7,1)
			end
		end
		if i==5 then
			if level==1 then
				cprint("welcome to cake monsters!",r.x1+64,r.y1+2,6)
				cprint("monsters like eating cake",r.x1+64,r.y1+8,6)
			elseif level==2 then
				string="you move all the monsters"
				cprint(string,r.x1+64,r.y1+2,6)
			elseif level==3 then
				string="monsters only like"
				string2="their own cake"
				cprint(string,r.x1+64,r.y1+2,6)
				cprint(string2,r.x1+64,r.y1+8,6)
			elseif level==4 then
				string="monsters mix when"
				string2="they get eaten"
				cprint(string,r.x1+64,r.y1+2,6)
				cprint(string2,r.x1+64,r.y1+8,6)
			elseif level==5 then
				string="brown + any color = brown"
				cprint(string,r.x1+64,r.y1+2,6)
			elseif level==6 then
				string="have fun!"
				cprint(string,r.x1+64,r.y1+2,6)
			elseif level==12 then
				string="piece of cake, right?"
				cprint(string,r.x1+64,r.y1+2,6)
			elseif level==15 then
				string="tiles destroy monsters"
				spr(48,r.x1+62-#string*2,r.y1+2)
				cprint(string,r.x1+73,r.y1+4,6)
			elseif level==21 then
				string="you're caking"
				string2="this look easy"
				cprint(string,r.x1+64,r.y1+2,6)
				cprint(string2,r.x1+64,r.y1+8,6)
			elseif level==26 then
				string="let's cake it"
				string2="to the next tier"
				cprint(string,r.x1+64,r.y1+2,6)
				cprint(string2,r.x1+64,r.y1+8,6)
			elseif level==31 then
				string="you're getting batter"
				cprint(string,r.x1+64,r.y1+2,6)
			elseif level==33 then
				string="icing on the cake"
				cprint(string,r.x1+64,r.y1+2,6)
			elseif level==35 then
				string="will you cake"
				string2="it out alive?"
				cprint(string,r.x1+64,r.y1+2,6)
				cprint(string2,r.x1+64,r.y1+8,6)
			elseif level==36 then
				string="dough you have"
				string2="what it cakes?"
				cprint(string,r.x1+64,r.y1+2,6)
				cprint(string2,r.x1+64,r.y1+8,6)
			end
		end
	end
end

function ease(obj) 
	obj.dx=(obj.targetx-obj.x1)/7
	obj.x1+=obj.dx
	obj.x2+=obj.dx
	if abs(obj.targetx-obj.x1)<0.7
	and abs(obj.targetx-obj.x1)>0 then
		obj.x1=obj.targetx
		obj.x2=obj.targetx+127
		rectt=t+66
	end
end

function cprint(str,x,y,c)
	print(str,x-#str*2,y,c)
end
-->8
--menu code

function menu_setup()
	timer_menu=20
	create_title()
end

function create_title()
	--creates a table where we will store the title's letters
	title={}
	--we add letters to title 
	letter_sprite=50
	letter_x=12
	letter_y=22
	letter_dy=1
	for i=1,13 do
		letter={sprite=letter_sprite,x=letter_x,y=letter_y,dy=letter_dy}
		add(title,letter)
		letter_sprite+=1
		letter_x+=8
		letter_y+=letter_dy
		if letter_y>25 or letter_y<19 then	
			letter_dy=-letter_dy
		end
	end
end

function update_menu()
	--monsters move to eat cakes
	timer+=1
	animate_monster()
	if timer>=timer_menu then
		timer=0
		for monster in all(monsters) do
			if monster.y<12 then
				monster.y+=1
				if monster.y==12 then
					create_particles(monster.sprite,monster.x*8+4,monster.y*8+4)
					sfx(0)
				end
			else
				anim=false
			end
		end
	end
	update_title()
	--press x to start game
	if btnp(❎) and not anim then
		sfx(7)
		level=1
		last_level=0
		dset(0,last_level)
		menu=false
		level_screen_setup()
		level_screen=true
		set_level(level)
	end
	if last_level!=0 then
		if btnp(🅾️) and not anim then
		sfx(7)
		level=last_level
		continued=true
		menu=false
		level_screen_setup()
		level_screen=true
		set_level(level)
	end
	end
end

function update_title()
	--makes title letters bounce
	if timer%2==0 then
		for letter in all(title) do
			letter.y+=letter.dy
			if letter.y>25 or letter.y<19 then	
				letter.dy=-letter.dy
			end
		end
	end
end

function draw_menu()
	camera()
	cls(1)
	fillp(▒)
	rectfill(0,0,127,127,0)
	fillp()
	rect(3,15,124,57,5)
	rectfill(4,16,123,56,13)
--	fillp(🅾️)
--	rectfill(4,16,123,56,13)
--	fillp()
	line(title[1].x-2,37,title[13].x+8,37,6)
	draw_title()
	if not anim then
		if t%30<15 then
			if last_level!=0 then
				string="🅾️ to continue/❎ to start  "
			else
				string="press ❎ to start"
			end
			print(string,63-#string*2,45,7)
		end
	end
	draw_wall()
	rectfill(2.5*8,10*8,13.5*8,13*8,13)
	draw_monster()
	--draw cake only if monsters haven't reached them
	if monsters[1].y<12 then
		spr(red_cake,2.5*8,12*8)
		spr(orange_cake,4.5*8,12*8)
		spr(yellow_cake,6.5*8,12*8)
		spr(green_cake,8.5*8,12*8)
		spr(blue_cake,10.5*8,12*8)
		spr(purple_cake,12.5*8,12*8)
	end
end

function draw_title()
	for letter in all(title) do
		--draw outline
		for i=0,15 do
			if t%12<8 then
				pal(i,7)
			else
				pal(i,14)
			end
		end
		spr(letter.sprite,letter.x-1,letter.y)
		spr(letter.sprite,letter.x+1,letter.y)
		spr(letter.sprite,letter.x,letter.y-1)
		spr(letter.sprite,letter.x,letter.y+1)
		pal()
		spr(letter.sprite,letter.x,letter.y)
	end
end

function draw_wall()
	--draws walls around monsters and cake
	for i=1.5,13.5 do
		spr(16,i*8,9*8)
	end
	for i=1.5,13.5 do
		spr(16,i*8,13*8)
	end
	for i=9,12 do
		spr(16,1.5*8,i*8)
	end
	for i=9,12 do
		spr(16,13.5*8,i*8)
	end
end
-->8
--undo code

function undo()
	--gets info to draw previous tilemap and deletes it
	local i=1
	if #alltilemaps>1 then
		sfx(9)
		local tilem=alltilemaps[#alltilemaps]
		for x=mapx,mapx+15 do
			for y=mapy,mapy+15 do
				mset(x,y,tilem[i])
				i+=1
			end
		end
		del(alltilemaps,alltilemaps[#alltilemaps])
	else
		sfx(10)
	end
	--gets info to draw monsters' previous position
	if #allmonsters>0 then
		monsters={}
		local pmons=allmonsters[#allmonsters]
		for pmonster in all(pmons) do
			--local monster=pmonster
			local monster={
				sprite=pmonster.sprite,
				x=pmonster.x,
				y=pmonster.y,
				anim_frames=pmonster.anim_frames,
				frame=pmonster.frame,
				anim_speed=pmonster.anim_speed
				}
				monster.spr=pmonster.spr
				monster.flash=pmonster.flash
			add(monsters,monster)
		end
		del(allmonsters,allmonsters[#allmonsters])
	end
end

function get_state()
	--gets current state of screen
	if btnp(⬆️) or
	btnp(⬇️) or
	btnp(➡️) or
	btnp(⬅️) then	
		--gets tilemap 
		get_tilemap()
		--gets monsters 
		get_monsters()
	end
end

function get_tilemap()
	--gets the tiles as they are on the screen
	--table that holds all the tiles
	tilemap={}
	for x=mapx,mapx+15 do
		for y=mapy,mapy+15 do
			tile=mget(x,y)
			add(tilemap,tile)
		end
	end
	add(alltilemaps,tilemap)
end

function get_monsters()
	--gets info of all monsters
	pmonsters={}
	for monster in all(monsters) do
		local pmonster={
			sprite=monster.sprite,
			x=monster.x,
			y=monster.y,
			anim_frames=monster.anim_frames,
			frame=monster.frame,
			anim_speed=monster.anim_speed
			}
			pmonster.spr=monster.spr
			pmonster.flash=monster.flash
		add(pmonsters,pmonster)
	end
	add(allmonsters,pmonsters)
end
-->8
--logo functions

function init_intro()
	intro_music=63
	outro_music=62
	beep_1=61
	beep_2=60
	beep_3=59
	end_color=1 --title screen color for game
	bubble_size=8 --size of the grid cells
	bubble_color=15
	bubble_r=0
	bubbles={}
	for y=bubble_size,127,bubble_size*2 do
		for x=bubble_size,127,bubble_size*2 do
			bubble={}
			bubble.x=x
			bubble.y=y
			add(bubbles,bubble)
		end
	end
	mode="intro"
	sfx(intro_music)
end

function update_intro()
	if bubble_r<12 then
		bubble_r+=0.6
	else
		mode="logo"
		logo_timer=0
		logo_r_1=1
		logo_r_2=1
		logo_r_3=1
	end
end

function draw_intro()
	cls(1)
	fillp(▒)
	rectfill(0,0,127,127,0)
	fillp()
	for bubble in all(bubbles) do
		circfill(bubble.x,bubble.y,bubble_r,bubble_color)
	end
end

function update_logo()
	logo_timer+=1
	--logo stays on screen for 3 seconds
	if logo_timer==10 then
		sfx(beep_1)
	elseif logo_timer==20 then
		sfx(beep_2)
	elseif logo_timer==30 then
		sfx(beep_3)
	elseif logo_timer>90 then
		mode="outro"
		sfx(outro_music)
		--make bubbles small again
		bubble_r=0
		--same color as the title screen
		bubble_color=end_color
	end
end

function draw_logo()
	name="three twins games"
	if logo_timer>10 then
		circfill(56,52,logo_r_1,12)
		circ(56,52,logo_r_1,1)
		if logo_r_1<8 then
			logo_r_1+=1
		end
		string="three"
		if logo_timer>20 then
			circfill(64,52,logo_r_2,9)
			circ(64,52,logo_r_2,1)
			if logo_r_2<8 then
				logo_r_2+=1
			end
			string="three twins"
			if logo_timer>30 then
				circfill(72,52,logo_r_3,11)
				circ(72,52,logo_r_3,1)
				if logo_r_3<8 then
					logo_r_3+=1
				end
				string=name
			end
		end
		print(string,64-#name*2,64,1)
	end
end
function update_outro()
	if bubble_r<127 then
		bubble_r+=3+rnd()
	else
		mode="title"
		sfx(3)
	end
end

function draw_outro()
	draw_logo()
	for i=1,10 do
		local x=16+rnd(96)
		local y=16+rnd(96)
		circfill(x,y,bubble_r,bubble_color)
		fillp(▒)
		circfill(x,y,bubble_r,0)
		fillp()
	end
end

function _draw_outro()
	draw_logo()
	rectfill(0,127,127,127-bubble_r,bubble_color)
end



__gfx__
00000000009988000099880000998800009988000099880000998800000000000099880000ffaa000066cc0000aabb0000ee220000aa99000099440000000000
0000000009877880098778800987788009822880098228800982288000000000098888800faaaaa006ccccc00abbbbb00e2222200a9999900944444000000000
007007009881788298817882988178829881788298822882988178820000000097188712f71aa719675cc751a71bb713e7522751a71997189714471500000000
000770009888888298888882988888829888888298888882988888820000000097688762f76aa769676cc761a76bb763e7622761a76997689764476500000000
000770008817718288177182811771128817718288111182888118820000000088888882aaaaaaa9ccccccc1bbbbbbb322222221999999984444444500000000
0070070008888820081111200811112008111120088888200888882000000000088888200aaaaa900ccccc100bbbbb3002222210099999800444445000000000
00000000008822000088820008111180008882000088220000882200000000000088220000aa990000cc110000bb330000221100009988000044550000000000
00000000002002000020020000888800002002000020020000200200000000000020020000900900001001000030030000100100008008000050050000000000
55555555ddddd222ddddd999ddddd111ddddd333ddddd111ddddd888ddddd5550099880000998800000000000000000000000000000000000000000000000000
57777775ddd22222ddd99999ddd11111ddd33333ddd11111ddd88888ddd555550988888009888880000000000000000000000000000000000000000000000000
576666d5d2222222d9999999d1111111d3333333d1111111d8888888d55555559178817298888882000000000000000000000000000000000000000000000000
576666d5d8888882daaaaaa9dcccccc1dbbbbbb3d2222221d9999998d44444459678867292288222000000000000000000000000000000000000000000000000
576666d5d8888882daaaaaa9dcccccc1dbbbbbb3d2222221d9999998d44444458888888288888882000000000000000000000000000000000000000000000000
576666d5d2222222d9999999d1111111d3333333d1111111d8888888d55555550888882008888820000000000000000000000000000000000000000000000000
57ddddd5d8888882daaaaaa9dcccccc1dbbbbbb3d2222221d9999998d44444450088220000882200000000000000000000000000000000000000000000000000
55555555d8888882daaaaaa9dcccccc1dbbbbbb3d2222221d9999998d44444450020020000200200000000000000000000000000000000000000000000000000
dddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dd6666dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dd6dd6dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dd6dd6dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dd6666dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7dddddd7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d7d77d7d000000000888800008888800880008008888880000000000800088000888800088000800088888008888880088888800888880000888880000000000
dd7887dd000000009900090090009900990009009900000000000000990999009000990099000900990000000099000099000000990009009900000000000000
d788887d00000000aa000000a000aa00aa00a000aa00000000000000a0a0aa00a000aa00aaa00a00aa00000000aa0000aa000000aa000a00aa00000000000000
d788887d00000000bb000000bbbbbb00bbbb0000bbbbb00000000000b0b0bb00b000bb00bb0b0b000bbbb00000bb0000bbbbb000bb000b000bbbb00000000000
dd7887dd00000000cc000000c000cc00cc00c000cc00000000000000c000cc00c000cc00cc00cc000000cc0000cc0000cc000000ccccc0000000cc0000000000
d7d77d7d000000001100010010001100110001001100000000000000100011001000110011000100000011000011000011000000110010000000110000000000
7dddddd7000000000222200020002200220002002222220000000000200022000222200022000200222220000022000022222200220002002222200000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000010101010100010101010100000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000101010100000101010100000000000001010101010101010100000000
00000000000000000000000000000000000000000000000000000000000000000000011111110100015151510100000000000000000000000000000000000000
00000000000000000000000000000000000000000101010101010100000000000000000151310101010131020100000000000001020202021111110100000000
00000000000101010101010000000000000000000101010101010100000000000000011111110101015151510100000000000101010101010101010101000000
00000000000101010101010000000000000000000102010201020100000000000000000131020202020202310100000000000001020202020202020100000000
00000000000102414102010000000000000000000102510351020100000000000000010302020202020202030100000000000102020201510102020201000000
00000000000102211121010000000000000000000102010201020100000000000000000101020101010102010100000000000001020202022121210100000000
00000000000102030302010000000000000000000111510351110100000000000000010103020203020203010100000000000111030201020103030201000000
00000000000102112111010000000000000000000102010201020100000000000000000001020103030102010000000000000001020202020202020100000000
00000000000102030302010000000000000000000102510351020100000000000000010302020202020202030100000000000102030202020202310201000000
00000000000102021121010000000000000000000102020202020100000000000000000001023102020102010000000000000101020202023131310101000000
00000000000102414102010000000000000000000101010101010100000000000000015151510101013131310100000000000101010101010101010101000000
00000000000102022111010000000000000000000102010101020100000000000000000101020101010102010100000000000102020202020202020201000000
00000000000101010101010000000000000000000000000000000000000000000000015151510100013131310100000000000000000000000000000000000000
00000000000101010101010000000000000000000141416141410100000000000000000131020202020202310100000000000102510202610202410201000000
00000000000000000000000000000000000000000000000000000000000000000000010101010100010101010100000000000000000000000000000000000000
00000000000000000000000000000000000000000101010101010100000000000000000151310101010131510100000000000102020202020202020201000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000101010100000101010100000000000101010101010101010101000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000102020201024102010202020100000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000102020201020202010202020100000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101000000000000
00000000000000000000000000000000000102020231013101110202020100000000000000010101010100000000000000000000000000000000000000000000
00000000000101010101010000000000000000000000000000000000000000000000000001010101010101000000000000000000000161026101000000000000
00000000000101010101010000000000000101013102020202021101010100000000000000010202020100000000000000000000000101010101010000000000
00000000000131210202010000000000000000000101010101010100000000000000000001610211026101000000000000000000000102020201000000000000
00000000000102610202010000000000000102020102014101020102020100000000000000010202020100000000000000000000000102020202010000000000
00000000000121310201010000000000000000000102020202610100000000000000000001022102210201000000000000000000000131023101000000000000
00000000000102020202010000000000000121024102210231021102310100000000000000010251020100000000000000000000000102020202010000000000
00000000000101010202010000000000000000000102020202410100000000000000000001110202021101000000000000000000000111210201000000000000
00000000000141410202010000000000000102020102011101020102020100000000000000011102110100000000000000000000000102020202010000000000
00000000000111410201010000000000000000000102020202510100000000000000000001022102210201000000000000000000000102211101000000000000
00000000000111023102010000000000000101010202020202022101010100000000000000013141310100000000000000000000000102020202010000000000
00000000000141110202010000000000000000000102020202410100000000000000000001610211026101000000000000000000000131023101000000000000
00000000000101010101010000000000000102020202012101210202020100000000000000010101010100000000000000000000000101010101010000000000
00000000000101010101010000000000000000000101010101010100000000000000000001010101010101000000000000000000000102020201000000000000
00000000000000000000000000000000000102020201020202010202020100000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000141024101000000000000
00000000000000000000000000000000000102020201021102010202020100000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101000000000000
00000000000000000000000000000000000101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000
__label__
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077770000077777000770007000777777000000000070007700007777000077000700007777700077777700077777700077777000007777700000000
00000000788887000788888707887078707888888700000000787078870078888700788707870078888870788888870788888870788888700078888870000000
00000007997779707977799707997079707997777000000000799799970797779970799707970799777700077997700799777700799777970799777700000000
00000007aa7007007a777aa707aa77a7007aa77700000000007a7a7aa707a707aa707aaa77a707aa777000007aa70007aa7770007aa707a707aa777000000000
00000007bb7000007bbbbbb707bbbb70007bbbbb70000000007b7b7bb707b707bb707bb7b7b7007bbbb700007bb70007bbbbb7007bb777b7007bbbb700000000
00000007cc7007007c777cc707cc77c7007cc77700000000007c777cc707c707cc707cc77cc7000777cc70007cc70007cc7770007ccccc70000777cc70000000
00000007117771707170711707117071707117777000000000717071170717771170711707170077771170007117000711777700711771700077771170000000
00000000722227007270722707227072707222222700000000727072270072222700722707270722222700007227000722222270722707270722222700000000
00000000077770000700077000770007000777777000000000070007700007777000077000700077777000000770000077777700077000700077777000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000007770707077707770777000007770707077707700077000000770777077707770077000000000000000000000000000000
00000000000000000000000000000000700707070707000700000000700707007007070700000007000707077707000700000000000000000000000000000000
00000000000000000000000000000000700777077007700770000000700707007007070777000007000777070707700777000000000000000000000000000000
00000000000000000000000000000000700707070707000700000000700777007007070007000007070707070707000007000000000000000000000000000000
00000000000000000000000000000000700707070707770777000000700777077707070770000007770707070707770770000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0
0d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d00
d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d999998888d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0
000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d000d00099999888888888888000d000d000d000d000d000d000d000d
d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d999888888888888888888d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0
0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d099988888888888888888888840d0d0d0d0d0d0d0d0d0d0d0d0d0d
d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d09988888888888888888888888440d0d0d0d0d0d0d0d0d0d0d0d0d0
0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d9998888888888888888888888888444d0d0d0d0d0d0d0d0d0d0d0d0d
ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd998888888889998888888888888888444ddd0ddd0ddd0ddd0ddd0ddd0
0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d99888888888922228888888888888888444d0d0d0d0d0d0d0d0d0d0d0d
d0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd9988888888882222228888888888888888444ddd0ddd0ddd0ddd0ddd0dd
0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d098888888888288888828888888888888888440d0d0d0d0d0d0d0d0d0d0d
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd998888888888886666888888888888888888444ddddddddddddddddddddd
0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0998888888888887777768888888888888888884440d0d0d0d0d0d0d0d0d0d
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd98888888888887777777688888888888888888844dddddddddddddddddddd
0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d9988888888888777777777628888888888888888444d0d0d0d0d0d0d0d0d0d
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd998888888888887777777776288888888888888884444dddddddddddddddddd
dd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0dd9888888888888777777777776288888888888888844440ddd0ddd0ddd0ddd0d
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd988888888888877771177777628888888888888888444dddddddddddddddddd
0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd0ddd88888888888888777117177776288888888888888884444d0ddd0ddd0ddd0ddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd888888888888887771111777f6288888888888888888444ddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd888888888888887771111777f6288888888888888888444ddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd8888888888888887777117777662888888888888888884442dddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd888888888888888877777777f628888888888888888884442dddddddddddddddd
ddddddddddddddddddddddddddddddddd11dddddddddddddddddddddddddddd88888888888888887777777f6628888888888888888884422dddddddddddddddd
ddddddddddddddddddddddddddddddddddd1ddddddddddddddddddddddddddd8888888888888888877777f66288888888888888888884422dddddddddddddddd
dddddddddddddddddddddddddddddddddddd1dddddddddddddddddddddddddd888888888888888888f77f662888888888888888888844422dddddddddddddddd
ddddddddddddddddddddddddddddddddddd1111dddddddddddddddddddddddd8888888888888888888ff6628888888888888888888844422dddddddddddddddd
dddddddddddddddddddddddddddddddddd17ee811111111dddddddddddddddd8888888888888888888222288888888888888888888844422dddddddddddddddd
ddddddddddddddddddddddddddddddddd18e8888ffff7771ddddddddddddddd8888888888998888888888888888889998888888888444222dddddddddddddddd
ddddddddddddddddddddddddddddd1111f888888f7777ff1ddddddddddddddd8888888889888888888888888888888889888888888444222dddddddddddddddd
dddddddddddddddddddddddddddd1f7777f8888f777ff881ddddddddddddddd8888888888888882222222222288888888888888888444222dddddddddddddddd
ddddddddddddddddddddddddddd1f5ff777ffff77ff88881ddddddddddddddd88888888888222211776d7761122222288888888884442222dddddddddddddddd
ddddddddddddddddddddddddddd14454f777777ff8888881dddddddddddddddd8888888881111111776d776111111122888888888444222ddddddddddddddddd
ddddddddddddddddddddddddddd144445fff77f888888221dddddddddddddddd8888888811111111776d776111111111288888888444222ddddddddddddddddd
ddddddddddddddddddddddddd11122444442f888888227f1dddddddddddddddd88888888111111117661761111111111288888888442222ddddddddddddddddd
ddddddddddddddddddddddd1167122244442f8888227f88111ddddddddddddddd888888111111111111111111111111128888888444222dddddddddddddddddd
dddddddddddddddddddddd16777122222442788227f88881761dddddddddddddd888888111111111111111111111111128888888442222dd6ddddddddddddddd
ddddddddddddddddddddd167711112222222f827f88888257761ddddddddddddd888888111111111111111111111111112888888442222dd6ddddddddddddddd
ddddddddddddddddddddd167177111222222f7f888882257d761dddddddddddddd8888811111111111111111111111111288888442222ddd6ddddddddddddddd
ddddddddddddddddddddd167177111111222f88888225577d761ddddddddddddddd88888111111122eeee88eeeee2211288888844222ddd6dddddddddddddddd
dddddddddddddddddddddd167111111111117888225577dd771dddddddddddddddd888881111112eeee887eeeeeeee21288888842222dd6ddd7ddddddddddddd
dddddddddddddddddddddd16677111111111f82255dddd77761ddddddddddddddddd888881111eeeee877eeeeeeee11288888844222ddd6dd7dddddddddddddd
ddddddddddddddddddddddd1166777111111f255dd77777611ddddddddddddddddddd88888811eeee87eeeeeeee112288888884222ddd6ddd7dddddddddddddd
ddddddddddddddddddddd6ddd11666677111957777766661ddddddddddddddddddddd88888888111eeeeeeee111278888888842222dd6ddd7ddddddddddddddd
ddddddddddddddddddddd6ddddd11116666666666661111ddddddddddddddddddddddd88888888881111111122287888888842222ddd6dd7dddddddddddddddd
dddddddddddddddddddddd66ddddddd111111111111dddddddddddddddddddddddddddd888888888822222228887778888842222ddd6ddd7dddddddddddddddd
dddddddddddddddddddddddd66dddddddddddddddddddddddddddddddddddddddddddddd888888888888888788877c888882222ddd6ddd7ddddddddddddddddd
dddddddddddddddddddddddddd6666dddddddddddddddddddddddddddddddddddddddddddd888888882222878888668888222dddd6ddd7dddddddddddddddddd
dddddddddddddddddddddd77dddddd6666dddddddddddddddddddddddddddddddddddddddd28888882998877c888888882222ddddddddddddddddddddddddddd
dddddddddddddddddddddddd77dddddddddddddddddddddddddddddddddddddddddddddddd222888888888866888888222002ddddddddddddddddddddddddddd
dddddddddddddddddddddddddd7777dddddddddddddddddddddddddddddddddddddddddddd202228888888888882222200052ddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddd77dddddddddddddddddddddddddddddddddddddddddd2200222dd222222722d20000522ddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd2220002dddddddd77dd20055222ddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd2222202ddddddd77cdd20522222ddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd222222dddddddd6ddd22222222ddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd222dddddddddddddd2222222ddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd7ddd2222dddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd6ddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd7dddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd6dddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd

__gff__
0000000000000000000000000000000003000000000000000000000000000000100000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000101010101010001010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000102020202010001012202020100000000000000000000000000000000000000000000000000000000000000000000000000010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000102020202010001020202020100000000000000000000000000000000000000000000000000000000000000000000000000010202020202020202010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000102020112010001020202020100000000000000000000000000000000000000000001010101010101010100000000000000010202020202020202010000000000010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000
0000000010101010101010000000000000102020202010001020202020100000000000101010101010101010000000000000001020202020202020100000000000000010202020202020202010000000000010202020202020202020131000000000000000101010101000000000000000000000001010101010100000000000
0000000010202020202010000000000000101010101010001010101010100000000000102020122020202010000000000000001020101010101020100000000000000010202020202020202010000000000010202020202020202020121000000000000000102013151000000000000000000000001020202020100000000000
0000000010202020202010000000000000000000000000000000000000000000000000101010101010102010000000000000001020202015202020100000000000000010201112131516142010000000000010101010102020101010101000000000000000102013111000000000000000000000001020202020100000000000
0000000010202020112010000000000000101010101010001010101010100000000000102020202020202010000000000000001020101010101020100000000000000010202020202020202010000000000000000000102020100000000000000000000000101520201000000000000000000000001015201515100000000000
0000000010202020202010000000000000102013202010001020202020100000000000102011202020202010000000000000001020202020202020100000000000000010202020202020202010000000000000000000102020100000000000000000000000101010101000000000000000000000001013111311100000000000
0000000010101010101010000000000000102020202010001020202014100000000000101010101010101010000000000000001010101010101010100000000000000010201717171717172010000000000000000000101414100000000000000000000000000000000000000000000000000000001010101010100000000000
0000000000000000000000000000000000102020202010001020202020100000000000000000000000000000000000000000000000000000000000000000000000000010202020202020202010000000000000000000101010100000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000102020202010001020202020100000000000000000000000000000000000000000000000000000000000000000000000000010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000101010101010001010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001013131313131313100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001020131313131313100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101010101313100000000000000000101010101010100000000000000000001010101010101000000000000000000010101000101010000000000000000000000000000000000000000000
0000000010101010101010000000000000000000101010101010100000000000000000000010101010101000000000000000000000000000101314100000000000000000102020202020100000000000000000001016202020161000000000000000001020202010202020100000000000000000001010101010000000000000
0000000010202014202010000000000000000000101313141320100000000000000000000010202020201000000000000000001010101010101212100000000000000000102020202020100000000000000000001020102010201000000000000000001020152030202020100000000000000000001020162010000000000000
0000000010202020202010000000000000000000102020202020100000000000000000000010112013201000000000000000001020121212121212100000000000000000102020202020100000000000000000001014202020141000000000000000001020202030202020100000000000000000001020302010000000000000
0000000010202020202010000000000000000000102012141212100000000000000000000010201620131000000000000000001020121212121212100000000000000000102020202020100000000000000000001010201620101000000000000000000010202030202010000000000000000000001020162010000000000000
0000000010202015202010000000000000000000101010101010100000000000000000000010202013201000000000000000001010101010101212100000000000000000101614151416100000000000000000001014201020141000000000000000000000102020201000000000000000000000001010101010000000000000
0000000010101010101010000000000000000000000000000000000000000000000000000010101010101000000000000000000000000000101116100000000000000000101010101010100000000000000000001010101010101000000000000000000000001020100000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101010101111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001020111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001011111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00040000165700f570095700557001570045700857000500015000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000500001a670156700e6703360033600336003360033600336003260000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
00040000151700f170091700517001170071700b170121700b1700110000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
010800001c0501c050210002a050250002a050210003505010000100001c00025000250002d000350003500000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000200005000070000b0002905036050000000b000070000500002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000200005000070000b000250502b05031050360503a0503a05035000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
210300001170011700137001370016700187001175211752137521375216752187521b7521f752277523375200702007020070200702007020070200702007020070200702007020070200702007020070200702
000600002f050340002f0500000038050380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000c00002475030750007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
001000001f75000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000f15000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000003335200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002735200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001835200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01160000377552b7551f7551675500005000050000500005167051f7052b705377050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
01160000167541f7542b7543775400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
