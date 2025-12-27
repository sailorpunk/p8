pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--nemonic crypt
--by nemo_dev
--6/21/2021

--[[

todo:

 bugfixing...
 there are always more bugs
  
]]


delay_set=30--time before turret is ready
tur_speed=.6--turret rotation speed

--do not touch :p legacy code
worldx=7
worldy=4

--pallet stuff
pallist=[[
red,0,2,8,14,1,13,5,3,11,3,10,133,7,6,8,12
blue,0,140,12,11,1,13,5,3,9,137,10,133,7,6,8,12]]
unlocklist=[[
green,0,3,11,138,1,13,5,3,9,137,10,133,7,6,8,12
orange,0,4,9,10,1,13,5,3,11,3,12,133,7,6,8,12
pink,0,141,14,143,1,13,5,3,11,3,10,133,7,6,8,12
yellow,0,131,10,135,1,13,5,3,12,140,12,133,7,6,8,12
white,0,6,7,135,1,13,5,3,11,3,10,133,7,6,8,12
paint red,0,2,8,14,5,7,6,6,11,3,11,3,7,6,8,7
paint blue,0,1,12,140,5,7,6,6,9,137,9,137,7,6,140,7
paint orange,0,137,9,10,5,7,6,6,14,141,14,141,7,6,9,7
paint green,0,3,11,138,5,7,6,6,8,2,8,2,7,6,11,7
monochrome,0,6,7,6,5,7,6,6,6,5,6,5,7,6,7,7
gameboy,138,131,3,131,139,131,3,3,131,3,131,3,138,3,131,3
demonic,0,136,8,8,130,2,128,133,12,140,10,5,7,6,136,12
higgs,0,5,10,135,128,134,5,3,6,5,6,5,7,6,10,6
aqua,0,131,12,138,1,140,131,143,11,3,10,140,7,9,12,11
splatoon,0,14,11,11,141,9,137,3,10,140,10,140,7,6,14,10
xmas,0,11,8,8,6,7,5,6,12,140,137,5,7,6,8,12
nemo,0,12,7,140,1,140,129,3,9,137,10,5,7,6,12,9
devskin,7,0,0,0,7,0,0,0,0,7,0,0,7,0,0,0]]
unlockstrs=split(unlocklist,"\n")
palstrs=split(pallist,"\n")




function _init()
	cartdata("nemonic")
	debug=""
	--directionals
	dirx=split("1,0,-1,0")
	diry=split("0,1,0,-1")
	//dirx={1,0,-1,0}
	//diry={0,1,0,-1}
	--initialize world
	mpos={}
	init_world()
	--trap stats
	trapct=120
	trapst=30
	--pause stuff
	pause=-1
	pfunction=function() end
	--set menu items
	menuitem(2,"retry dailycrypt",retry_daily)
	menuitem(3,"reset unlocks",resetunlocks)
	//hardmode=false
	start_game()
--	add_obj(150,94,2)
--	show_sash("hello world",2,0)
end

function start_game()
	--set unlocked pallets
	setunlockpal()
	--pallet select
	if (dget(4)==0) dset(4,1)
	palsel=dget(4)
	if #palstrs<palsel then
		palsel=1
		dset(4,1)
	end
	--set seed
	dc=false--daily crypt
	seed=stat(92)*.1+stat(91)*3.1+stat(90)*37.2
	date=oh(tostr(stat(91))).."/"..oh(tostr(stat(92))).."/"..oh(tostr(stat(90)))
	if dget(0)==seed then
		seed=rnd(999)
	else
		dc=true
	end
	--win screen variables
	win=false
	wint=0
	tcrdst=24
	showcryst=true
	winmode=0
	--stats
	totalkills=dget(3) or 0
	unlk=nil
	--map generation stuff
--	startrn=0
--	endrn=2
--	floor=0
--	clear={}
	wpos,wposx,wposy=0,0,0
	--player direction
	dirlx,dirly=0,0
	dirdx,dirdy=1,0
	anispeed=30--animation speed
	--eye directionals
	eyedirx=split("1,2,2,1,0,0,0,1,2")
	eyediry=split("1,1,0,0,0,1,2,2,2")
	//eyedirx={1,2,2,1,0,0,0,1,2}
	//eyediry={1,1,0,0,0,1,2,2,2}
	eyepos=1
	eyet=-1
	//dashcool=false
	set_bounce=10
	kills=0
	door=true
	ltime=time()
	--global tick
	t=0
	--hit/miss count
	hit=0
	shot=0
	//devskin=false
	--map stuff
	xtxt=true--tutorial
	mposx=0
	mposy=0
	camx=0
	camy=0
	camtx=0
	camty=0
	shake=0
	trapt=0--trap timer
	--spawn timer
	spawnt=0
	//trapset=false
	--tables
	particle={}
	uparticle={}
	turret={}
	bullet={}
	enemy={}
--	obj={}
	
	--sash
	//sash_vis=false
	--adding a sash initilizes 
	--all other needed variables
	
	--spawn first crystal
--	local ex,ey=get_rpos(endrn)
--	add_obj(ex*128+64,ey*128+58,1)
	
	ground_floor()
	
	--over stuff
	over=false
	overt=0
	gover_thiq1=0
	gover_thiq2=0
	gover_thiq3=0
	gover_textoff=128
	gover_choice="none"
end

function retry_daily()
	lock(wpos%8,wpos\8,false)
	dset(0,0)
	music(-1)
	start_game()
end

function _update()
	t+=1
	update_pause()
	if win then
		update_end()
		update_over()
		update_particle()
	else
		update_turret()
		update_player(player)
		update_enemy()
		update_bullet()
		update_particle()
		update_room()
		update_obj()
		update_sash()
		update_camera()
		update_over()
	end
	local ox,oy=0,0
	if shake>0 then
		ox=rnd(2*shake)-shake
		oy=rnd(2*shake)-shake
	end
	camera(camx+ox,camy+oy)
	//debug = player.hp > 0
end

function _draw()
	cls()
	setpal()
	if win then
		draw_end()
		draw_particle()
		draw_over()
	else
		draw_floor()
		draw_particle(true)
		draw_player()
		draw_bullet()
		draw_turret()
		draw_enemy()
		draw_obj()
		draw_particle()
		draw_sash()
		draw_over()
	end
	if debug~="" then
		print(debug,12+camx,12+camy,7)
	end
end

function init_win()
	win=true
	endt=time()
	crdst=100
	floor=6
end





-->8
--object 웃

----------
--player--
----------
function new_player(_hp)
	local rx,ry = get_rpos(startrn)
	local p={
		hp=_hp or 5,
		live=true,
		iframe=0,
		--positional stuff
		x=64+128*rx-3,
		y=64+128*ry-4,
		dx=0,
		dy=0,
		dirx=1,
		diry=0,
		w=4,
		h=8,
		r=3,
		--dash stuff
		dash=false,
		dasht=20,
		--turret stuff
		tur_ang=0,
		tur_sel=1,
		--room stuff
		fighting=false,
		--sprite stuff
		snum=0,
		sflip=false
	}
	if (not _hp) p.y+=8
	large_puff(p.x+p.w/2,p.y+p.h/2)
	return p
end

----------
--turret--
----------
function new_turret()
	local t={
		dist=0,
		tdist=9,
		delay=0,
		num=#turret,
	}
	return t
end

function fire_turret(_n)
	local t=turret[_n]
	if t.delay==0 and player.hp>0
	and player.fighting then
		local px,py=get_wpos(t)
		if mcol(px,py,1,1,0) then
			sfx(13)
			return true
		else
			sfx(1)
			shot+=1
			local pdx,pdy=2*cos(player.tur_ang+t.num/#turret),2*sin(player.tur_ang+t.num/#turret)
			add_bullet(px,py,pdx,pdy,5+5*floor,1,{2,1})
			t.delay=delay_set
			--particles
			medium_puff(get_wpos(t))
			return true
		end
	else
		return false
	end
end

----------
--bullet--
----------
function add_bullet(_x,_y,_dx,_dy,_bounce,_tpe,_pal)
	local b={
	bounce=_bounce,
	x=_x, y=_y,
	dx=_dx, dy=_dy,
	tpe=_tpe, cpal=_pal,
	flame=false
	}
	add(bullet,b)
end

function bullet_blast(_x,_y)
	local bnum=14
	local ao=rnd()
	for a=0,1,1/bnum do
		local dx,dy=1.5*cos(a+ao),1.5*sin(a+ao)
		add_bullet(_x,_y,dx,dy,1,3,{10,11})
	end
end

function delete_bullet(_b,_p)
	medium_puff(_b.x,_b.y,_b.cpal)
	if (_b.tpe==2 and not _p) bullet_blast(_b.x,_b.y)
	del(bullet,_b)
end

---------
--enemy--
---------
function new_enemy(_x,_y,_tpe,_elite)
	local e={
		hp=3,
		x=_x*8,
		y=_y*8,
		dx=0,
		dy=0,
		w=8,
		h=8,
		fdel=5,
		sflip=false,
		elite=_elite,
		tpe=_tpe,
		eid=#enemy
	}
	if (_elite) e.hp=5
	if _tpe==1 then
		e.h=5
	end
	if _tpe==3 then
		e.invt=20
	end
	return e
end

function add_obj(_x,_y,_tpe)
	add(obj,{x=_x,y=_y,tpe=_tpe})
end
-->8
--update ⬆️
function update_player(_p)
	local p=_p
	anispeed=30
	if p.live and not over then
		if (p.iframe>0) p.iframe-=1
		local nx,ny=p.x,p.y
		
		--pallet changing on floor 0
		if floor==0  
		and (wpos==0 or wpos==1) then
			if btnp(❎) then
				nextpal()
				large_puff(p.x+p.w/2,p.y+p.h/2)
			elseif btn(➡️) and btn(⬆️)
			and btn(⬅️) and btn(⬇️) 
			and not hardmode then
				hardmode=true
				show_sash("hardmode: enebled",2,1)
			end
--			debug=hardmode
			if (hardmode) p.hp=3
		end
		--make velocity 0 if slow
--		if (abs(p.dx)<.1) p.dx=0
--		if (abs(p.dy)<.1) p.dy=0
		--cape
		dirlx,dirly=0,0
		if abs(p.dx)>.3 then
			dirlx=1*sgn(p.dx)
		end
		if abs(p.dy)>.3 then
			dirly=1*sgn(p.dy)
		end
		--dash
		
		
		if btn(🅾️) and not dashcool
		and not dabort then
			sfx(0)
			p.dash=true
			p.dasht-=1
		elseif p.dash then
			p.dash=false
			dashcool=true
		end
		
		if p.dasht<=0 or dabort then
			p.dash=false
			dashcool=true
		end
		
		if p.dasht>=20 then
			dashcool=false
			p.dasht=20
		end
		if dashcool then
			p.dasht+=.5
		end
		
		
		local pdirx,pdiry=0,0
		local maxspeed=2
		local a=.7
		if p.dash then
			maxspeed=5
			a=2
			pdirx,pdiry=dirdx,dirdy
		end
		
		butt=false
		if btn(➡️) then
			butt=true
			pdirx+=1
			p.sflip=false
			anispeed=8
		end
		if (btn(⬅️)) then
			butt=true
			pdirx-=1
			p.sflip=true
			anispeed=8
		end
		if (btn(⬆️)) then
			butt=true
			pdiry-=1
			anispeed=8
		end
		if (btn(⬇️)) then
			butt=true
			pdiry+=1
			anispeed=8
		end
		
		--move player into room if not generated yet
		if not p.fighting
		and not clear[get_rnum(mposx,mposy)] then
			local rx,ry=p.x-camtx,p.y-camty--worldpos(p.x,p.y)
			if (rx<16) pdirx=1
			if (rx>110) pdirx=-1
			if (ry<16) pdiry=1
			if (ry>110) pdiry=-1
		end
		
		p.snum=(t\anispeed%2)
		
		--room clip fix
		local rdx,rdy=p.x+p.w/2-camtx,p.y+p.h/2-camty
		dabort=false
--		if floor>0 and
		if rdx<10 or rdx>118 then
			dabort=true
			p.dy,pdiry=0,0
		end
		if rdy<8 or rdy>118 then
			dabort=true
			p.dx,pdirx=0,0
		end
		
		if (pdirx==0) p.dx*=.8
		if (pdiry==0) p.dy*=.8
		
		
		accel(p,pdirx,pdiry,a,maxspeed)
		
		nx+=p.dx
		ny+=p.dy
		
		move(p,nx,ny)
		
		--eye movement
		if eyet>0 then
			eyet-=1
		elseif eyet==0 then
			eyet=-1
			eyepos=1
		end
		
		--particles
		if player.dash then
			local px=player.x+rnd(3)+1.5
			local py=player.y+rnd(3)+1.5
			local pdx,pdy=norm(player.dx,player.dy)
			pdx*=2 pdy*=2
			add_particle(2,px,py,pdx,pdy,15+rnd(15),{2,1},3)
		end
		
--		dirlx,dirly=dirx,diry
		if pdirx~=0 or pdiry~=0 then
			dirdx,dirdy=pdirx,pdiry
		end
		local nmposx,nmposy=(p.x+p.w/2)\128,(p.y+p.h/2)\128
		
		if mposx~=nmposx
		or mposy ~=nmposy then
			dashcool=true
		end
		
		
		
		mposx,mposy=nmposx,nmposy
		wpos=floormap[mposx+mposy*24]
		wposx,wposy=wpos%8,wpos\8
		camtx=mposx*128
		camty=mposy*128
		
		
		
		if not p.fighting
		--and wpos~=startrn
		and not clear[get_rnum(mposx,mposy)] then
--		and p.x-p.w/2-camtx>11
--		and p.x+p.w/2-camtx<116
--		and p.y-p.h/2-camty>11
--		and p.y+p.h/2-camty<116 then
			local rx,ry=p.x+p.w/2-camtx,p.y+p.h/2-camty
			if rx>12 and rx<116
			and ry>12 and ry<116 then
				gen_room(wpos%8,wpos\8)
			end
		elseif p.fighting
		and #enemy<=0 then
			if (xtxt) xtxt=false
			music(2)
			p.fighting=false
			lock(wpos%8,wpos\8,false)
			clear[get_rnum(mposx,mposy)]=true
		end
		
		
		--fire 
		local f=3
		if (trapset) f=2
		if trapt>trapst and not player.dash
		and mcol(p.x+1,p.y+1,p.w-2,p.h-2,f)
		and p.iframe==0 then
			sfx(4)
			damage_player()
		end
		--bullet hit detection
		if not player.dash 
		and p.iframe==0 then
			for b in all(bullet) do
				if aabb(p.x,p.y,p.w,p.h,b.x,b.y,0,0) then
					sfx(4)
					damage_player()
					if b.flame
					and player.hp>0 then
						damage_player()
					end
					delete_bullet(b,true)
				end
			end
			if p.iframe==0 and spawnt==0
			and ecoli(p.x,p.y,p,true) then
				sfx(5)
				damage_player()
			end
		end
		if p.hp<=0 then
			kill_player()
		end
	else
		if not over and isnot_savable() then
			endt=time()
			set_over()
		end
	end--end of live check
	--turret stuff
	local tim=time()
	p.tur_ang+=(tim-ltime)*tur_speed
	ltime=tim
	if p.tur_ang>=1 then
		p.tur_ang=0
	end
end

function isnot_savable()
	local ns=true
	for b in all(bullet) do
		ns=b.tpe~=1 and ns
	end
--	debug=ns
	return ns
end

function set_over()
	dset(3,dget(3)+kills)
	over=true
end

function damage_player()
	player.hp-=1
	player.iframe=30
	shake=3
end

function kill_player()
	sfx(8)
	music(4)
	player.live=false
	shake=10
	large_puff(player.x,player.y)
end

--tomove
function move(_o,_nx,_ny)
	--offset for player
	local o=0
	--bounce check
	local b=mag(_o.dx,_o.dy)>1.5
	if (_o==player) o=4 
	if not mcol(_nx,_ny+o,_o.w,_o.h-o)
	and not ecoli(_nx,_ny,_o) then
		_o.x,_o.y=_nx,_ny
	else
		if not mcol(_nx,_o.y+o,_o.w,_o.h-o)
		and not ecoli(_nx,_o.y,_o) then
			_o.x=_nx
		else
			if b then _o.dx*=-.9
			else _o.dx=0 end
		end
		if not mcol(_o.x,_ny+o,_o.w,_o.h-o)
		and not ecoli(_o.x,_ny,_o) then
			_o.y=_ny
		else
			if b then _o.dy*=-.9
			else _o.dy=0 end
		end
	end
end

function ecoli(_x,_y,_o,_b)
	if _o==player and not _b then
		return false
	end
	for e in all(enemy) do
		if e~=_o
		and aabb(_x,_y,_o.w,_o.h,e.x,e.y,e.w,e.h) then
			return true
		end
	end
	return false
end

function update_turret()
	for t in all(turret) do
		if player.live then
			if t.delay>0 then
				t.delay-=1
				t.tdist=4+5*(1-t.delay/delay_set)
			else
				t.tdist=9
			end
			
			if player.dash
			or not player.fighting then
				t.tdist=0
			end
		else
			t.tdist+=2
			player.tur_ang+=.01
		end
		t.dist+=(t.tdist-t.dist)/2
	end--end turret loop
	if btnp(❎) and floor~=0 and not player.dash 
	and not over then
		local f=fire_turret(player.tur_sel)
		if f then
			if (devskin) nextpal(true)
			--eye movement
			local tang=(player.tur_ang+(player.tur_sel-1)/#turret)+1/16
			if (tang>=1) tang-=1
			eyepos=tang\(1/8)+2
			eyet=15
			
			--turret change
			player.tur_sel-=1
			if player.tur_sel<=0 then
				player.tur_sel=#turret
			end
		else
			--nrr nrr sfx
		end
	end--end btn(❎)
end


function update_bullet()
	for b in all(bullet) do
		local nx=b.x+b.dx
		local ny=b.y+b.dy
		local tx,ty=worldpos(nx,ny)
		if fmget(tx,ty,0) then
--			sfx(2) 
			b.bounce-=1
			if b.flame then
				b.flame=false
				medium_puff(nx,ny,b.cpal)
			end
			
			tx,ty=worldpos(nx,b.y)
			if fmget(tx,ty,0) then
				b.dx*=-1
			else
				b.x=nx
			end
			tx,ty=worldpos(b.x,ny)
			if fmget(tx,ty,0) then
				b.dy*=-1
			else
				b.y=ny
			end
			small_puff(nx,ny,b.cpal)
		else
			b.x,b.y=nx,ny
		end
		
		if b.bounce<=0 then
			if (b.tpe==1) delete_bullet(b)
			delete_bullet(b)
		end
		
		--flame set
		local f=3
		if (trapset) f=2
		if trapt>trapst and b.tpe==1
		and fmget(tx,ty,f) then
			b.flame=true
		end
		
		if b.tpe==1 then
			if b.flame then
				b.cpal={3,3,1}
			else
				b.cpal={2,1}
			end
		end
		
		--particles
		local ptpe=1
		if (b.flame) ptpe=2
		local px=b.x+rnd(2)-1
		local py=b.y+rnd(2)-1
		local pl=10+rnd(5)
		add_particle(ptpe,px,py,0,0,pl,b.cpal,2)
	end
end

function update_enemy()
	if spawnt>0 then
		spawnt-=1
	else
		for i,e in ipairs(enemy) do
			local nx,ny=e.x,e.y
			--target palyer
			local dirx,diry=norm(player.x+player.w/2-e.x,player.y+player.h/2-e.y)
			local eoff=i/#enemy
			local a=.1
			local maxspeed=2
			local f=.8--friction
			if e.tpe==1 then
				--slime/flare
				a=2
				f=.9
				if e.elite and not over then
					f,a,maxspeed=.9,3,3
					local px,py=e.x+rnd(8),e.y+2
					add_particle(1,px,py,rnd()-.5,-1,4+rnd(2),{8,9})
				end
				if t%30~=flr(30*eoff)-1 then
					dirx,diry=0,0
				end
			elseif e.tpe==2 then
				--bat/wasp
				if dist(player.x,player.y,e.x,e.y)<40 then
					a*=-1
				end
				if player.live and t%120==flr(120*eoff)-1 then
					local btpe,bdx,bdy,bpal,bbnce=3,dirx*1.5,diry*1.5,{10,11},3
					if e.elite then
						btpe=2 bdx=dirx bdy=diry
						bbnce=1 bpal={10,11}
					end
					
					add_bullet(e.x,e.y,bdx,bdy,bbnce,btpe,bpal)
				end
			elseif e.tpe==3 then
				--ghost/eye
				maxspeed=1
				if e.elite and rnd()<.4 then
					local pc=13
					if (e.invt==-1) pc=4
					add_particle(2,e.x+rnd(4)+2,e.y+rnd(4)+2,0,0,25+rnd(15),{pc},2.5,true)
					maxspeed=1.5
					if e.invt>0 then
						e.invt-=1
					elseif e.invt==0 then
						medium_puff(e.x+e.w/2,e.y+e.h/2,{13})
						e.invt=-1
					end
				end
				
			end
			--friction
			if (dirx==0) e.dx*=f
			if (diry==0) e.dy*=f
			accel(e,dirx,diry,a,maxspeed)
			
			nx+=e.dx
			ny+=e.dy
			
			
			--face sprite
			if e.dx<0 then
				e.sflip=true
			else
				e.sflip=false
			end
			
			if e.tpe==3 then
				if not ecoli(nx,ny,e) then
					e.x,e.y=nx,ny
				else
					e.dx*=-1
					e.dy*=-1
				end
			else
				move(e,nx,ny)
			end
			--hit detection
			for b in all(bullet) do
				if b.tpe==1
				and aabb(e.x-1,e.y-1,e.w+2,e.h+2,b.x-1,b.y-1,2,2) then
					hit+=1
					sfx(3)
					e.hp-=1--★
					if e.tpe==3 and e.elite then
						e.invt=20
					end
					if (b.flame) e.hp-=1
					e.dx+=2*b.dx
					e.dy+=2*b.dy
					delete_bullet(b)
				end
			end
			
			if e.hp<=0 then
				sfx(6)
				local ppal={8,9}
				if (e.tpe==2) ppal={10,11}
				if (e.tpe==3) ppal={12,13}
				medium_puff(e.x+e.w/2,e.y+e.h/2,ppal,4,15+rnd(15))
				srand(seed+e.eid*.666+floor*10.1+mposx*.2+mposy*.3)
				if rnd()<.25 
				and not hardmode then
					add_obj(e.x+e.w/2,e.y+e.h/2,2)
				end
				del(enemy,e)
				kills+=1
				if not player.live and #enemy==0 then
					show_sash("sudden death",1,2)
					player.live=true
					player.hp=1
					player.iframe=30
					large_puff(player.x,player.y)
				end
			end
		end
	end
end

function update_room()
	if player.fighting then
		trapt+=1
		if trapt>=trapct then
			trapset=not trapset
			trapt=0
		end
	else
		trapt=0
	end
	
	local trapl=mpos[wpos].trap
	if (trapset) trapl=mpos[wpos].trap2
	if trapt~=0 then
		local ptpe=1
		if (trapt>trapst) ptpe=2
		for i=1,#trapl,2 do
			if rnd()<.5 and not over then
				local px=mposx*128+trapl[i]*8+4.5-rnd()
				local py=mposy*128+trapl[i+1]*8+3+rnd()
				add_particle(ptpe,px,py,1-rnd(2),-1-rnd(),5+(ptpe-1)*15-rnd(5),{8,9},3,true)
			end
		end
	end
	
	local torch=mpos[wpos].torch
	for i=1,#torch,2 do
		if rnd()<.75 then
			local px,py=torch[i],torch[i+1]
			px=px*8+4+mposx*128
			py=py*8+1+mposy*128
			local pcol={8,9}
			
			if clear[get_rnum(mposx,mposy)] then
				pcol={2,1}
				if dc then
					pcol={3,1}
				end
			end
			add_particle(2,px,py,.5-rnd(),-.5-rnd(),15-rnd(5),pcol,1.1,true)
		end
	end
end

function update_camera()
	local dx,dy=camtx-camx,camty-camy
	camx+=(dx)/2
	camy+=(dy)/2
	shake*=.8
	if shake<.25 then
		shake=0
	end
	if (abs(dx)<1) camx=camtx
	if (abs(dy)<1) camy=camty
end

function update_obj()
	for o in all(obj) do
		if o.tpe==1 then
			local dsty=abs(o.y-player.y)
			local dstx=abs(o.x-player.w/2-player.x)
			local close=dsty<8 and dstx<8
			if rnd()<.1 then
				local pspeed=1
				add_particle(4,o.x,o.y,rnd(pspeed)-pspeed/2,rnd(pspeed)-pspeed/2,60+rnd(60),{2,1},5)
			end
			if player.dash then
				
				if close then
					del(obj,o)
					
					if floor==5 then
						init_win()
					else
						new_floor()
						sfx(10)
						sfx(11)
					end
				end
			elseif close then
			player.dx*=-3
			player.dy*=-3
			end 
		elseif o.tpe==2 then
			local dsty=abs(o.y-player.y-player.h/2)
			local dstx=abs(o.x-player.x-player.w/2)
			local close=dsty<6 and dstx<6
			local mhp=5
			if (hardmode) mhp=3
			if player.hp<mhp and close 
			and player.live then
				sfx(9)
				player.hp+=1
				small_puff(o.x,o.y,{14})
				del(obj,o)
			end
		end
	end
end

function update_over()
	if over then
		if overt<1000 then
			overt+=1
		end
		local pa=rnd()
		local pspd=3+rnd(4)
		local pdx,pdy=pspd*cos(pa),pspd*sin(pa)
		local pr=1+overt/1.5
		if overt<120 then
			add_particle(5,player.x,player.y,pdx,pdy,600,{2},pr)
		end
		if overt==20 then
			if win then
				--win sfx
			else
				sfx(12)
			end
			music(-1)
		end
		if not unlk then
			unlk=checkunlock()
		end
		--reduce tokens here vvv
		if (overt>70) gover_thiq1+=(69-gover_thiq1)/8
		if (overt>78) gover_thiq2+=(69-gover_thiq2)/8
		if (overt>84) gover_thiq3+=(36-gover_thiq3)/8
		if (overt>86) gover_textoff+=(0-gover_textoff)/10
		
--		if (overt>70) gover_thiq1+=lerp(gover_thiq1,69,8)
--		if (overt>78) gover_thiq2+=lerp(gover_thiq2,69,8)
--		if (overt>84) gover_thiq3+=lerp(gover_thiq3,36,8)
--		if (overt>86) gover_textoff+=lerp(gover_textoff,0,10)
		
		
		if overt>60 then
			lock(wpos%8,wpos\8,false)
			if pause<0 then
				if btnp(🅾️) then
					gover_choice="new"
					sfx(9)
					pause=24
					pfunction=start_game
				elseif btnp(❎) and dc then
					gover_choice="retry"
					sfx(9)
					pause=24
					pfunction=retry_daily
				end
			end
		end
	end
end

--function lerp(v,tv,s)
--	return (tv-t)/s
--end

function update_end()
	wint+=1
	if winmode==0 then
		crdst+=(tcrdst-crdst)/18
		if wint>60 and tcrdst>0 then
			tcrdst-=1
		elseif tcrdst<1 and showcryst then
			showcryst=false
			mega_puff(64,64)
			large_puff(64,64)
			winmode=1
		end
	elseif winmode==1 then
		if rnd()<.1 then
			local pspeed=1
			add_particle(4,64,64,rnd(pspeed)-pspeed/2,rnd(pspeed)-pspeed/2,60+rnd(60),{2,1},5)
		end
		if btnp(🅾️) then
			player.x=64
			player.y=64
			mposx,mposy=0,0
			set_over()
		end
	end
end
-->8
--draw ∧
function draw_player()
	if floor==0 then
		sspr(66,0,62,15,14,22)--nemo
		sspr(96,39,32,20,77,17)--onic
		sspr(82,15,46,24,69,33)--crypt
--		print("project: balls",40,30,2)
--		palt(2,true)
--		for i=0,2 do
--			spr(16+16*i,12+12*i,80)
--		end
--		palt()
		print("BY NEMO_DEV",22,38,1)
		if (hardmode) print("hardmode",0,0,1)
		print("palette -",30,100,1)
		print(palname,70,100,2)
		print("press ❎ to change color",16,116,1)
		if (dc) print(oh(stat(91)).."/"..oh(stat(92)).."/"..stat(90),178,41,1)
		if (wpos==1 or wpos==2)
		and (dirlx~=0 or dirly~=0) then
			print("hold 🅾️",player.x-10,player.y-8,1)
			if (not btn(🅾️)) print("     🅾️",player.x-10,player.y-9,3)
		end
	elseif xtxt and not hardmode
	and player.live 
	and get_rnum(mposx,mposy)~=startrn then
		print("❎",player.x-2,player.y-8,1)
		if (not btn(❎)) print("❎",player.x-2,player.y-9,3)
	end 
	
	
	if player.live then
		palt(0,false)
		palt(11,true)
		local ifrmoff=0
		if player.iframe\5%2==1 then
			ifrmoff=8
		end
		if player.dash then
			circfill(player.x+2,player.y+2,2,2)
		else
			sspr(8+player.snum*4+ifrmoff,0,player.w,player.h,player.x,player.y,player.w,player.h,player.sflip)
			--eye
			local ex=player.x+eyedirx[eyepos]
			local ey=player.y+1+eyediry[eyepos]+player.snum
			if (not player.sflip) ex+=1
			pset(ex,ey,2)
			--cape
			local cx=player.x-1-dirlx
			if (player.sflip) cx+=2
			local cy=player.y+player.h-1-dirly
			local ccol=1
			if (ifrmoff>0) ccol=14
			line(cx,cy,cx+3,cy,ccol)
		end
		palt()
		setpal()
	else
		--player is dead
		--draw corpse
		spr(3,player.x-1,player.y)
	end
	--ui
	if wpos~=0 then
		camera(0,0)
		local hux=31
		if (hardmode) hux=19
		rectfill(0,0,hux,7,0)
		rect(-1,-1,hux,7,1)
		if player.hp>0 then
			for i=1,player.hp do
				print("♥",(i-1)*6,1,14)
			end
		end
		rectfill(0,7,7,31,0)
		rect(-1,7,7,31,1)
		local dc=2
		if (dashcool) dc=4
		rectfill(1,29,5,29-20*player.dasht/20,dc)
		camera(camx,camy)
	end
end

function draw_turret()
	for t in all(turret) do
		if t.dist>1 then
			local x,y=get_wpos(t)
			local sn=0
			if t.num+1==player.tur_sel then
				sn=1
			end
			if t.delay>0 then
				sn=2
			end
			spr_r(5+sn,0,x,y,1,1,false,false,0,4,player.tur_ang+t.num/#turret,0)
		end
	end
end

function draw_bullet()
	for b in all(bullet) do
		local r=1
		if (b.flame or b.tpe==2) r+=1
		circfill(b.x,b.y,r,b.cpal[1])
	end 
end

function draw_enemy()
	
	for e in all(enemy) do
		palt(0,false)
		palt(2,true)
		local s=16*e.tpe+t\e.fdel%4
		if (e.elite) s+=4
		if spawnt==0 then
			if e.tpe==3 and e.elite
			and e.invt==-1 then
				pal(12,0)
				pal(13,4)
				pal(14,4)
			end
			spr(s,e.x,e.y,1,1,e.sflip)
			setpal()
		else
			if spawnt>20 then
				fillp(░|0b.011)
			elseif spawnt>10 then
				fillp(▒|0b.011)
			end
			warpspr(s,e.x,e.y,1,1,spawnt/10)
			fillp()
		end
	end
	palt()
end


function draw_obj()
	for o in all(obj) do
		if o.tpe==1 then
			sspr(40,48,9,16,o.x-3.4+cos(t/69),o.y-11-2*sin(t/120))
		elseif o.tpe==2 then
			print("♥",o.x-2,o.y-3,14)
		end
	end
end

function draw_floor()
	for rpos,mp in pairs(floormap) do
		local rx,ry=get_rpos(rpos)
		local mx,my=mp%8,mp\8
		map(mx*16,my*16,rx*128,ry*128,16,16)
	end
end

function draw_over()
	local scrx,scry=mposx*128,mposy*128
	
	if (gover_thiq1>0) rectfill(scrx,scry+64-gover_thiq1,scrx+127,scry+64+gover_thiq1,1)
	if (gover_thiq2>0) rectfill(scrx,scry+64-gover_thiq2,scrx+127,scry+64+gover_thiq2,0)
	local yt,yb=scry+64-gover_thiq3,scry+64+gover_thiq3
	if gover_thiq3>0 then
		line(scrx,yt,scrx+127,yt,1)
		line(scrx,yb,scrx+127,yb,1)
		local h="\^t\^wgame over"
		local hc=14
		if win then
			h="\^t\^wcongrats"
			hc=2
		end
		print(h,scrx+28,scry-24+gover_thiq3,hc)
		
		local bm1c,bm2c=1,1
		local c=blinkcol({1,2,3,2},3)
		if gover_choice=="new" then
			bm1c=c
		elseif gover_choice=="retry" then
			bm2c=c
		end
		
		print("   press 🅾️ for new crypt",scrx+8-gover_textoff,scry+108+1.5*sin(t/60),bm1c)
		if (dc) print("press ❎ to retry daily crypt",scrx+8-gover_textoff,scry+115+1.5*sin(t/60),bm2c)
	end
	clip(0,64-gover_thiq3,128,2*gover_thiq3)
	if hardmode then
		print("hardmode",scrx+60+gover_thiq3,scry+93,2)
	end
	if overt>30 then
		local tx,ty=scrx+6,scry+38
		local dtime=(endt-startt)\1
		local m=oh(dtime\60)
		local s=oh(dtime%60)
--		if (#m<2) m="0"..m
--		if (#s<2) s="0"..s
		dtime=m..":"..s
		local acc=tostr(flr(hit/shot*100)).."%"
		local ltk=ceil(totalkills)
		if (overt>104) totalkills+=(dget(3)-totalkills)/24
		if (ltk~=ceil(totalkills)) sfx(3)
		local statvals={
		tostr(floor).."/6",
		dtime,
		acc,
		tostr(kills),
		ceil(totalkills)}
		local stats=[[
		   crystals -
		       time -
		   accuracy -
		      kills -
		total kills -]]
		if dc then 
			ty+=3
			stats="		    attempt -\n"..stats
			for i=#statvals,1,-1 do
				statvals[i+1]=statvals[i]
			end
			statvals[1]=attempt
			sprint("daily crypt : "..date,tx+10,ty-10,3,1)
		end
		local statstrs=split(stats,"\n")
		--pixel spacing
		local psp=60/#statstrs
		for i=1,#statstrs do
			local y=ty+psp*(i-1)
			sprint(statstrs[i],tx-7,y,2,1)
			print(statvals[i],tx+68+gover_textoff+sin((t+i*5)/30),y)
		end
	end
	clip()
	if unlk and unlk>0 
	and overt>100 then
--		debug=unlk
		print("+"..unlk.." new palette(s) unlocked",scrx+24,scry+123,3)
	end
end

function draw_end()
	camera()
	if showcryst then
		for i=1,6 do
			local a=i/6+t/120
			local x=60+crdst*cos(a)
			local y=56+crdst*sin(a)
--	circfill(x,y,3,2)
			sspr(40,48,9,16,x,y)
		end
	else
		sspr(56,48,17,16,56,56)
		if wint>170 then
			print("\^t\^wthanks for\n playing!",26,22,2)
		end
		if wint>180 then
			print("press 🅾️ to continue",24,100,1)
		end
	end
end
-->8
--map ●
--helper functions
function mcol(_x,_y,_w,_h,_f)
	local rx,ry=worldpos(_x,_y)
	local flag = _f or 0
	local collision=false
	for x=rx,rx+_w,_w do
		for y=ry,ry+_h,_h do
			if x>128*wposx and x<128*wposx+127
			and y>128*wposy and y<128*wposy+127 then
				if (fmget(x,y,flag)) collision=true
			end
		end
	end
	return collision
end

function worldpos(_x,_y)
	local rx,ry=_x-mposx*128,_y-128*mposy
	return rx+wposx*128,ry+wposy*128
end

function fmget(_x,_y,_f)
	return fget(mget(_x/8,_y/8),_f)
end

--world generator
function init_world()
	mpos={}
	for wx=0,7 do
		for wy=0,3 do
			local room={
				x=wx,
				y=wy,
				clear=false,
				doorpos={},
				spawnpoint={},
				trap={},
				trap2={},
				torch={}
			}

			for tx=0,15 do
				for ty=0,15 do
					local dx,dy=wx*16+tx,wy*16+ty
					local tspr=mget(dx,dy)
					if tspr<64 and tspt~=0 then
						add(room.spawnpoint,tspr\16)
						add(room.spawnpoint,tx)
						add(room.spawnpoint,ty)
						mset(dx,dy,64)
					elseif tspr==83 then
						add(room.doorpos,tx)
						add(room.doorpos,ty)
						mset(dx,dy,65)
					elseif tspr==84 then
						add(room.trap,tx)
						add(room.trap,ty)
					elseif tspr==68 then
						add(room.trap2,tx)
						add(room.trap2,ty)
					elseif tspr==86 then
						add(room.torch,tx)
						add(room.torch,ty)
					end
				end
			end
			mpos[wx+wy*8]=room
		end
	end
end

--world functions
function lock(_rx,_ry,_l)
	local r=mpos[_rx+8*_ry]
	for i=1,#r.doorpos,2 do
		local tx,ty=r.doorpos[i]+16*mposx,r.doorpos[i+1]+16*mposy
		local t=65
		if _l then
			digital_puff(tx*8+4,ty*8+4)
			t=83
		else
			for b in all(bullet) do
				delete_bullet(b)
			end
		end
		mset(16*_rx+r.doorpos[i],16*_ry+r.doorpos[i+1],t)
	end
end

function summon(_rx,_ry)
	srand(seed+wpos+100*floor)
	sfx(7)
	local rsp=mpos[_rx+_ry*8].spawnpoint
	local spawns=gen_nums(#rsp/3-1,min(floor,4))
	local elite_num=0
	if (floor>=3) elite_num=floor-2
	local elist=gen_nums(#spawns-1,elite_num)
	spawnt=30
	for e=1,#spawns do
		i=spawns[e]*3+1
		local elite=false
		for n=1,#elist do
			if (elist[n]+1==e) elite=true
		end
		add(enemy,new_enemy(16*mposx+rsp[i+1],16*mposy+rsp[i+2],rsp[i],elite))
	end
--	for i=1,#rsp,3 do
--		add(enemy,new_enemy(16*mposx+rsp[i+1],16*mposy+rsp[i+2],rsp[i]))
--	end
	music(0)
end

function gen_nums(_v,_n)
	local nums={}
	local cnums={}
	for i=0,_v do
		add(nums,i)
	end
	for i=1,_n do
		local sel=ceil(rnd(#nums))
		add(cnums,nums[sel])
		del(nums,nums[sel])
	end
	return cnums
end

function gen_room(_rx,_ry)
	lock(_rx,_ry,true)
	summon(_rx,_ry)
	player.fighting=true
end
-->8
--tools ♥
--pallet stuff
function nextpal()
	palsel+=1
	if (palsel>#palstrs) palsel=1
	dset(4,palsel)
end

function setpal()
	local p=split(palstrs[palsel],",",true)
	pal()
	palname=p[1]
	for c=0,15 do
		pal(c,p[c+2],1)
	end
end

--pause
function update_pause()
	if pause>0 then 
		pause-=1
	elseif pause==0 then
		pause=-1
		pfunction()
	end
end

--blink
function blinkcol(_t,_bs)
	local _bs=_bs or blinkspeed
	return _t[(t\_bs)%#_t+1]
end

--make a char 2 char long :o
--used for dates and times
function oh(_s)
	_s=tostr(_s)
	if (#_s<2) _s="0".._s
	return _s
end

--printing tools
function sprint(_s,_x,_y,_c1,_c2)
	print(_s,_x,_y+1,_c2)
	print(_s,_x,_y,_c1)
end

--vector maths
--normalizer
function norm(_x,_y)
	local m=mag(_x,_y)
	return _x/m,_y/m
end
--magnitude
function mag(_x,_y)
	return sqrt(_x^2+_y^2)
end

--distance
function dist(_x1,_y1,_x2,_y2)
	return sqrt((_x1-_x2)^2+(_y1-_y2)^2)
end

--accelerate
function accel(_o,_dirx,_diry,_a,_max)
	if _dirx~=0 or _diry~=0 then
		local dirx,diry=norm(_dirx,_diry)
		_o.dx+=dirx*_a
		_o.dy+=diry*_a
		local speed=mag(_o.dx,_o.dy)
		if speed>_max then
			_o.dx*=_max/speed
			_o.dy*=_max/speed
		end
	end
end

--returns global position of 
--passed turret
function get_wpos(_t)
	local ox=_t.dist*cos(player.tur_ang+_t.num/#turret)
	local oy=_t.dist*sin(player.tur_ang+_t.num/#turret)
	return player.x+player.w/2+ox,player.y+player.h/2+oy
end

--aabb
function aabb(ax,ay,aw,ah,bx,by,bw,bh)
	if ax + aw >= bx and ax <= bx + bw and ay + ah >= by and ay <= by+bh then return true end
	return false
end

--rotating sprite function
--by jihem, revised by huulong 
function spr_r(i, j, x, y, w, h, flip_x, flip_y, pivot_x, pivot_y, angle, transparent_color)
 -- precompute pixel values from tile indices: sprite source top-left, sprite size
 local sx = 8 * i
 local sy = 8 * j
 local sw = 8 * w
 local sh = 8 * h

 -- precompute angle trigonometry
 local sa = sin(angle)
 local ca = cos(angle)

 -- in the operations below, 0.5 offsets represent pixel "inside"
 -- we let pico-8 functions floor coordinates at the last moment for more symmetrical results

 -- precompute "target disc": where we must draw pixels of the rotated sprite (relative to (x, y))
 -- the target disc ratio is the distance between the pivot the farthest corner of the sprite rectangle
 local max_dx = max(pivot_x, sw - pivot_x) - 0.5 
 local max_dy = max(pivot_y, sh - pivot_y) - 0.5
 local max_sqr_dist = max_dx * max_dx + max_dy * max_dy
 local max_dist_minus_half = ceil(sqrt(max_sqr_dist)) - 0.5

 -- iterate over disc's bounding box, then check if pixel is really in disc
 for dx = - max_dist_minus_half, max_dist_minus_half do
  for dy = - max_dist_minus_half, max_dist_minus_half do
   if dx * dx + dy * dy <= max_sqr_dist then
    -- prepare flip factors
    local sign_x = flip_x and -1 or 1
    local sign_y = flip_y and -1 or 1

    -- if you don't use luamin (which has a bracket-related bug),
    -- you don't need those intermediate vars, you can just inline them if you want
    local rotated_dx = sign_x * ( ca * dx + sa * dy)
    local rotated_dy = sign_y * (-sa * dx + ca * dy)

    local xx = pivot_x + rotated_dx
    local yy = pivot_y + rotated_dy

    -- make sure to never draw pixels from the spritesheet
    --  that are outside the source sprite
    if xx >= 0 and xx < sw and yy >= 0 and yy < sh then
     -- get source pixel
     local c = sget(sx + xx, sy + yy)
     -- ignore if transparent color
     if c ~= transparent_color then
      -- set target pixel color to source pixel color
      pset(x + dx, y + dy, c)
     end
    end
   end
  end
 end
end

--warped sprite
--by coffeebat
function warpspr(n,x,y,w,h,warp)
local w_t=w*8
local h_t=h*8
--use:
--warpspr(sprite_number,onscreen_x,onscreen_y,width,height,warp_intensity,flip_horizontally)
	local spx=(n%16)*8
	local spy=(n\16)*8
	for i=0,w_t-1 do
			local xw=2*sin(1.3*time()-(i/h_t))*warp+x
			sspr(spx,spy+i,w_t,1,xw,y+i,w_t,1)
		end
end


-->8
--particles! :d
--[[

particle types
 1 - point
 2 - smoke
 3 - digital
 4 - aura
 5 - oversnow
]]
function add_particle(_tpe,_x,_y,_dx,_dy,_mt,_pal,_r,_under)
	local p={
		tpe=_tpe,
		x=_x, y=_y,
		dx=_dx, dy=_dy,
		cpal=_pal,
		r=_r,
		t=0, mt=_mt,
	}
	if _under then
		add(uparticle,p)
	else
		add(particle,p)
	end
end

function mega_puff(_x,_y)
	for i=1,60 do
		local pdx=rnd(12)-6
		local pdy=rnd(12)-6
		local pl=30+rnd(45)
		add_particle(2,_x,_y,pdx,pdy,pl,{2,1},8)
	end
end

function large_puff(_x,_y)
	for i=1,15 do
		local pdx=rnd(6)-3
		local pdy=rnd(6)-3
		local pl=30+rnd(15)
		add_particle(2,_x,_y,pdx,pdy,pl,{2,1},6)
	end
end

function medium_puff(_x,_y,_pal,_s,_l)
	_s = _s or 3
	_pal = _pal or {2,1}
	for i=1,5 do
		local pdx=rnd(2)-1
		local pdy=rnd(2)-1
		local pl= _l or 10+rnd(5)
		add_particle(2,_x,_y,pdx,pdy,pl,_pal,_s)
	end
end


function small_puff(_x,_y,_pal)
	for i=1,3 do
		local pdx=rnd(2)-1
		local pdy=rnd(2)-1
		local pl=10+rnd(5)
		add_particle(1,_x,_y,pdx,pdy,pl,_pal)
	end
end

function digital_puff(_x,_y)
	for i=1,3 do
		local pdx=rnd(4)-2
		local pdy=rnd(4)-2
		local pl=15+rnd(20)
		add_particle(3,_x,_y,pdx,pdy,pl,{15},6)
	end
end

function update_particle()
	local part={}
	for p in all(particle) do
		part[#part+1]=p
	end
	for up in all(uparticle) do
		part[#part+1]=up
	end
	for p in all(part) do
		p.t+=1
		
		if p.tpe==2 or p.tpe==3 then
			p.dx*=.85
			p.dy*=.85
		end
		
		p.x+=p.dx
		p.y+=p.dy
		
		if p.t>=p.mt then
--		or p.y>200 then
			del(particle,p)
			del(uparticle,p)
		end
	end
end

function draw_particle(_under)
	local part
	if _under then
		part=uparticle
	else
		part=particle
	end
	for p in all(part) do
		local c=p.cpal[#p.cpal*p.t\p.mt+1]
		if p.tpe==1 then
			pset(p.x,p.y,c)
		elseif p.tpe==2 then
			local r=p.r*(1-p.t/p.mt)
			circfill(p.x,p.y,r,c)
		elseif p.tpe==3 then
			local l=p.r*(1-p.t/p.mt)
			rect(p.x-l/2,p.y-l/2,p.x+l/2,p.y+l/2,c)
		elseif p.tpe==4 
		and p.t>4 then
			local r=p.r*(1-p.t/p.mt)
			if p.t<60 then
				fillp(▒)
			else
				fillp(░)
			end
			circfill(p.x,p.y,r,c)
			fillp()
		elseif p.tpe==5 then
			circfill(p.x,p.y,p.r,c)
		end
	end
end
-->8
--procedural generation UWU
function ground_floor()
	obj={}
	partacle={}
	floormap={}
	clear={}
	floor=0
	for i=0,2 do
		floormap[i]=i
		clear[i]=true
	end
	startrn=0
	endrn=2
	local ex,ey=get_rpos(endrn)
	add_obj(ex*128+64,ey*128+58,1)
	player=new_player()
end

function new_floor()
	if (palsel==20) devskin=true
	obj={}
	particle={}
	floormap={}
	clear={}
	floor+=1
	floormap=set_tiles(world_gen(2+floor))
	player=new_player(player.hp)
	if (floor>=2) add_obj(player.x+player.w/2+dirx[sdir]*-26,player.y+player.h/2+diry[sdir]*-26,2)
	clear[startrn]=true
	update_player(player)
	camx,camy=camtx,camty
	local ex,ey=get_rpos(endrn)
	add_obj(ex*128+64,ey*128+58,1)
	add(turret,new_turret())
	shake=20
	if floor==1 then
		startt=time()
		if dc then
			dset(0,seed)
			attempt=dget(2)
			if seed~=dget(1) then
				attempt=1
				dset(1,seed)
			else
				attempt+=1
			end
			dset(2,attempt)
		end
	end
	music(2)
	show_sash("floor: "..floor,2,0)
end

function  get_rpos(_rn)
	return _rn%24,_rn\24
end

function get_rnum(_x,_y)
	return _x+_y*24
end

function world_gen(_nr)
	srand(seed+100*floor)
	startrn=0
	endrn=0
	local f_world={}
	local t_world={}
	local t_rpos={}
	t_world[get_rnum(12,12)]=1
	add(t_rpos,get_rnum(12,12))
	for i=1,_nr do
		local rx,ry,rn
		rn=set_room(t_rpos,t_world)
	end
	
	--start and end
	startrn,sdir=set_room(t_rpos,t_world)
	endrn,edir=set_room(t_rpos,t_world)
	--lable room types
	for rn in all(t_rpos) do
		local rt=0
		if rn==startrn then
			rt=15+sdir
		elseif rn==endrn then
			rt=19+edir
		else
			local rx,ry=get_rpos(rn)
			for d=1,4 do
				local trn=get_rnum(rx+dirx[d],ry+diry[d])
				if trn==startrn then
					if (d==sdir) rt+=2^(d-1)
				elseif trn==endrn then
					if (d==edir) rt+=2^(d-1)
				elseif t_world[trn] then
					rt+=2^(d-1)
				end
			end
		end
		f_world[rn]=rt
	end
	return f_world
end
--roomtype to map

rtpe2m=split([[
8
9
10
11
12,28
13
14,23
15
16
17,29
18,24
19
20,25
21,26
22,27
6
7
30
31
2
3
4
5]],"\n")
--old_rtpe2m={
--"8",--1
--"9",--2
--"10",--3
--"11",--4
--"12,28",--5
--"13",--6
--"14,23",--7
--"15",--8
--"16",--9
--"17,29",--10
--"18,24",--11
--"19",--12
--"20,25",--13
--"21,26",--14
--"22,27",--15
--"6",--16
--"7",--17
--"30",--18
--"31",--19
--"2",--20
--"3",--21
--"4",--22
--"5"--23
--}

function set_tiles(_world)
	local t_world={}
	for rn,rtpe in pairs(_world) do
		t_world[rn]=rndt(split(rtpe2m[rtpe],",",true))
	end
	return t_world
end

function set_room(t_rpos,t_world)
	local d
	repeat
		d=ceil(rnd(4))
		local trn=t_rpos[ceil(rnd(#t_rpos))]
		rx,ry=get_rpos(trn)
		rx+=dirx[d]
		ry+=diry[d]
		rn=get_rnum(rx,ry)
	until not t_world[rn] and trn~=startrn
	t_world[rn]=1
	return add(t_rpos,rn),d
end

function rndt(_t)
	return _t[ceil(rnd(#_t))]
end
-->8
--sash
function show_sash(_t,_c,_tc)
	sash_w=0
	sash_tw=5
	sash_c=_c
	sash_t=_t
	sash_tc=_tc or 7
	sash_frames=0
	sash_vis=true
	sash_tx=-#sash_t*4
	sash_ttx=64-(#sash_t*2)
	sash_delay_w=0
	sash_delay_t=15
	if player.y%128>64 then
		sash_y=34
		sash_ty=34
		sash_down=false
	else
		sash_y=94
		sash_ty=94
		sash_down=true
	end
end

function update_sash()
	if sash_vis then
		sash_frames+=1
		--animate width
		if sash_delay_w>0 then
			sash_delay_w-=1
		else
			sash_w+=(sash_tw-sash_w)/5
			if abs(sash_w-sash_tw)<0.4 then
				sash_w=sash_tw
			end
		end
		--animate text
		if sash_delay_t>0 then
			sash_delay_t-=1
		else
			sash_tx+=(sash_ttx-sash_tx)/10
			if abs(sash_tx-sash_ttx)<0.3 then
				sash_tx=sash_ttx
			end
		end
		--animate y position
		if sash_down then
			if player.y%128>78 then
				sash_ty=34
				sash_down=false
			end
		else
			if player.y%128<50 then
				sash_ty=94
				sash_down=true
			end
		end
		sash_y+=(sash_ty-sash_y)/6
		--make sash go away
		if sash_frames==75 then
			sash_tw=0
			sash_ttx=160
			sash_delay_w=15
			sash_delay_t=0
		end
		if sash_frames>105 then
			sash_vis=false
			for x=0,127 do
				add_particle(1,x+camx,sash_y+camy,0,0,rnd(15),{sash_c})
			end
		end
	end
end

function draw_sash()
	camera(0,0)
	if sash_vis then
		rectfill(0,sash_y-sash_w,128,sash_y+sash_w,sash_c)
		local _tc=sash_tc
--		if sash_tc>15 then
--			_tc=blink_r
--		end
		print(sash_t,sash_tx,sash_y-2,_tc)
	end
	camera(camx,camy)
end
-->8
--unlock system
function unlockpal(_n)
	local u=_n+9
	if dget(u)==0 then
		dset(u,1)
		return 1
	end
	return 0
end

function resetunlocks()
	for i=1,20 do
		dset(i+9,1)
	end
end

function setunlockpal()
	palstrs=split(pallist,"\n")
	for i=1,#unlockstrs do
		local u=i+9
		if dget(u)>0 then
			add(palstrs,unlockstrs[i])
		end
	end
end

function checkunlock()
	local d=stat(92)
	local m=stat(91)
	local u=0
	if (floor>=1) u+=unlockpal(1)
	if (floor>=2) u+=unlockpal(2)
	if (floor>=3) u+=unlockpal(3)
	if (floor>=4) u+=unlockpal(4)
	if (floor>=5) u+=unlockpal(5)
	if (totalkills>=25)   u+=unlockpal(6)
	if (totalkills>=50)   u+=unlockpal(7)
	if (totalkills>=100)  u+=unlockpal(8)
	if (totalkills>=420)  u+=unlockpal(9)
	if (totalkills>=1000) u+=unlockpal(10)
	if (floor>=6) u+=unlockpal(11)
	if (kills>=100) u+=unlockpal(12)
	if (flr(hit/shot*100)==100) u+=unlockpal(13)
	if (flr(hit/shot*100)==69) u+=unlockpal(14)
	if (flr(hit/shot*100)==0) u+=unlockpal(15)
	if (m==12 and d>=20) u+=unlockpal(16)
	if (m==7) u+=unlockpal(17)
	return u
end
__gfx__
00000000b111bbbbbeeebbbb00000000000000000000000000000000000000000000000002222000000000022220000000000000000000000000000000000000
000000001000b111eeeebeee00000000000000000000000000000000000000000000000221122200000000211110000000000000000000000000000000000000
0070070010001000eeeeeeee00000000000000001110000011200000110000000000002210022200000002100000000000000000000000000000000000000000
0007700010001000eeeeeeee00000000000000000120000022222000010000000000022100022220000002000000222000022220002220000222000000022220
00077000b1011000beeeeeee00000000000000001110000011200000110000000000022000021220000022000022112200211220021220022122000002211222
00700700111b1101eeebeeee00000000000000000000000000000000000000000000011000220122000021000211002202100220210220211022000021100122
00000000111b111beeebeeeb01110000000000000000000000000000000000000000000000220022000020002200002201000222100222100022000220000022
00000000111b111beeebeeeb11111000000000000000000000000000000000000000000000220012200020002100022100002221000222000221000210000022
22222222228888222288882222222222222222222222228228222822282222280000000000210002220220022000221000002220002221000220002200000022
22888822289999822899998222888822222822822828282282822828228282220000000000200001220220022222110000002210002210000220002200000021
28999982899999988998989828989882282828222282282828228222228828220000000002100000122210022111000000002200002200002210002200000220
89989898899898988999999889999998228888288288882222888822288888820000000002000000022200022000000200022200002200002200022200000210
89999998899999988999999889999998828888822288888222888882288888880022000021000000012200022200022100022100002200002200212220002100
28888882288888822888888228888882288cec82288ccc82288cce82888cec820012222210000000002200012222211000022000022100002222101222221000
22222222222222222222222222222222288ccc82288cce82288ccc82288ccc820001111100000000001100001111100000011000011000001111000111110000
22222222222222222222222222222222228888222288882222888822228888220000000000000000000005555555500000000000000000000000000000000000
22222222222222222222222222222222222222222bb22222222222222bb222220000000000000000000055666566500000000000000000000000000000005550
22222222222222222b2222b2222222222bb2222222bb22222bb22aa222bb2aa20000000000000000000556666666500000000000000000000000000000055650
22222222222222222b2222b2b222222b22bbaaa22222aaa222bbaaea2222aaea0000000000000000000566666666500000000000000000000000000000556650
bbbaabbbbbb22bbb2bb22bb2bbbaabbb22abaaea22abaaea22aba2aa22aba2aa0000000000000000005566555666500000000000000000000000000000566650
b22aa22b22baab2222baab2222baab2222bab2aa22bab2aa22bab22222bab2220000000000000000005666545566555555555555555555555555555505566655
22222222222aa222222aa2222222222222ab222222ab222222ab222222ab22220000000000000000005666504555566665665666655666666665666555666665
22222222222222222222222222222222222a2222222a2222222a2222222a22220000000000000000005666500444566666665666655666666666666655666665
222222222222222222222222222222222222b2222222b2222222b2222222b2220000000000000000005666500000556666665566655566556665556665566655
2222222222222222222222222222222222dddd2222dddd2222dddd2222dddd220000000000000000005666500000456666555566655566556665456665566654
22222222222dddd2222dddd2222222222dccccd22dccccd22dccccd22dccccd20000000000000000005666500555056665544556665665556665056665566650
222dddd222dddddd22dddddd222dddd2dcceeccddccccccddccccccddcceeccd0000000000000000005666500565556665400456665665456665056665566650
22dddddd22dddddd22dddddd22dddddddce00ecddccceecddceecccddce00ecd0000000000000000005666555566556665000056665665056665056665566650
22dddddd22dd0d0d22dd0d0d22dddddddce00ecddcce00edde00eccddce00ecd0000000000000000005566655666556665000055666665056665056665566650
22dd0d0d22dddddd22dddddd22dd0d0ddcceeccddcce00edde00eccddcceeccd0000000000000000004566666665556665500045666655056665556665566655
22dddddd22d2dd2d22dd22dd22dddddd2dccccd22dcceed22deeccd22dccccd20000000000000000000556666665566666500005666654056666666655566665
22dd22dd222222222222222222d2dd2d22dddd2222dddd2222dddd2222dddd220000000000000000000455666655566666500005566650056665666554556665
00000000000000000000000000000000000000000555550005555500055555000000000000000000000045555554555555500004566550056665555540455555
0000000000444440000444000dddddd0000000005555555055555550555555500000000000000000000004444440444444400000566540056665444400044444
0400000000044440040440040d1111d0006666005555555055555550555555500000000000000000000000000000000000000055566500556665500000000000
0400000004444440040000000d1dd1d0006006005555555006666600066666000000000000000000000000000000000000000056666500566666500000000000
0400000004444440040004000d1dd1d0006666005555555044444440444444400000000000000000000000000000000000000056665500566666500000000000
0400000004440440040444000d1111d0004444005555555044004400440004400000000000000000000000000000000000000055555400555555500000000000
0444444004440440044444400dddddd0000000000555550044044400044444000000000000000000000000000000000000000044444000444444400000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000
00000000000000000000000000000000000000000000000000000000055555000555550000000000000000000000000000000000000000000000220000000000
0000004000444444400000000ffffff0000000000000000000060600555055505555555000000000000000000000000000000000000000000002220000000000
0040044004444444444000000f0000f0006666000000000000066600550055505555555000000000000000000000000000000000000000000022210000000000
0440000004400444444440000f0000f0006006000000000000006000555505505550555000000000000000000000000000000000000000000022100000000000
0400000004404444444444000f0000f0006666000000000000006000555550005050555000000000000000000000000000000000000000000021000000000000
4000044004444444444444000f0000f0004444000000000000000000555005505505555000000000000000000000000000000000000000000010000000000000
0000440004444444444444400ffffff0000000000000000000000000055555000505550000000000000000000000000000000000000000000000000000000000
00000000044444444404444000000000000000000000000000000000000000000000000000000000000000000000000000222000022200000222000000002222
00000000044444044444444044400666666000040000000000000000000000000000000000000000000000000000000022122002212200022221000000221112
00000000044440044444444044066555555660000000200000000000000000000000000000000000000000000000000011022021102200011220000002110002
00000000044444444444444040566666655556000000200000000000000220000000220000000000000000000000000000022210002200000220000022000001
00000000044444444444444006666666666555600003220000000000002222200032222000000000000000000000000000022200002200000220000021000000
00000000044444444400444056666666666655560002320000000000033222220323222200000000000000000000000000022100002200000220000220000000
00000000004444444444444056666662026665560022323000000000022332222323222200000000000000000000000000022000022100000210000220000000
00000000004444444444440056666660006666560022232000000000022223322322322200000000000000000000000000221000022000002200000220000000
00000000000000000000000056666662026666560222322200000000022222323222232200000000000000000000000000220000022002002200200220000020
00000000000000000000000055666666666666560222322200000000022222333222223200000000000000000000000000220000022021002202100222000210
00000000000000000000000045566666666666641223222210000000002223222322222000000000000000000000000000220000022210002221000122222100
00000000000700000000700004556666666666401113321110000000000223222332220000000000000000000000000000110000011100001110000011111000
00000000000700000000070000455566666664040011311000000000000032223223200000000000000000000000000000000000000000000000000000000000
00000000000007000000000000044555565440040001210000000000000002232222000000000000000000000000000000000000000000000000000000000000
00000070000070000700000004400444444000440000200000000000000000322220000000000000000000000000000000000000000000008088888888888888
00000700000000000070000044400000000044440000000000000000000000022200000000000000000000000000000000000000000000008880000000000008
00000000000000000000000044400000004444440000000000000000000000002000000000000000000000000000000000000000000000008088888888888888
54646464646435353535646464646454546464646464353535356464646464545464646464643535353564646464645454545454545435353535646464646454
54545464645435353535546464545454546464646464353535356464646464545464646464643535353564646464645454646464646464646464646464646454
54040404650414141424030404050654540404046504241414140565040604545404040405041414141404650604045454545454545414141424046503040654
54646404056414141414640404646454540304040405141414140445040404545402040404041414142404040404045454040404040404040204040404040454
54040405040506141404044444440454540405040404051424040404040402545404050404042414240504040404045454545454545404142404040404050454
54650404044424141414440405046554540404050404241414140445060404545404050404040414240404040405065454650404040404040404050404046554
54040406052414142404044444440454540604042404041405040404040404545465060404051414050404040405045454545454545405141404050104040454
54040404044406141404440404040354540404444444441405040445050404545404060504040454540504040404045454040604040404050404060404050454
54040524140624051405044444440454540404544444541424544444540404545404010454041424055403040404065454545454546404141424040404060454
54030504064404241405440404050454546504445454441424050545040404545404040404040564640404010404045454040504545454545454545404010454
54040414055454545454010404040364540104540404540514540406540405545404040454041414045454545404046464646464646524141405040404040454
64040404045405061401540424040464640406446464441414055454650404546404040404650414140465040404046464040404646464646464646404040464
54040424146464646464140505061435540404540404542414540504540604545404040454042414046464646404243535140504041414240404040404040454
35140405045404141424540506051435351405444444440514045454040405543514040405040114240404040404143535140405040405040504040404041435
54040514170606060706272414241435544545540104544545540404544545545405040454011525052414141424143535142414141414545454444444444454
35141424145424141404540524141435351414142405241406045454040406543514145454242415252405545424143535142414141445454545142414241435
54040404540627060606541424141435544545540504544545540401544545545404020454041626052414142406143535141405241405545454444444444454
35141414145454242454541414241435351414051414142414025454010404543514246464141416261424646414143535141405061445444445141405241435
54050405540607651706540504051435540405540406540514540404540404545404040454042414065454545404143535240504042404646464040404040454
35240414456464141464644514041435351424454545451414055454040404543514050404040514240504040404143535140104050445444445050404041435
54040406540606270606540404040554540604540404542414540404540404545406040454051414045464646404045454040404050404454504040504040454
54040445450165051465044545040454540604455454450524046464650404545404040404650414050465040604045454040404040445454545040404040454
54040204640617060607640404046554540504644444641414644444640404545404040464040514045403040406045454650404040404454504010406050454
54044545142405141414141445450454546501456464450614040444040404545404040405040454540404040404045454030404040404140504040605040354
54060604060607062706270404060454540404050404041424040404040404545465040504041424040404040504045454030405060404454504040404040454
54454524141414140524141414454554540404454545451405040444060404545406040404040464640504040504045454545465040404241405040465545454
54650504060706060607060406040554540404040406040514050404040506545404040406041414050404060404045454040404050404454504050404020454
54450404040502040405040404044554540506040404051424140444050404545404040604040514240404040404045454545405060504142404040404545454
54040404175454545454060404020454540304046504141414050465040404545404040404041414142404650406065454040417040404454504040404046554
54545406040404040404040405545454540504040405241414050444040403545403040404041414142404040404035454545404040414141414040404545454
54545454545454545454545454545454545454545454353535355454545454545454545454543535353554545454545454545454545454545454545454545454
54545454545454545454545454545454545454545454353535355454545454545454545454543535353554545454545454545454545435353535545454545454
54646464646435353535546464646454546464646464353535356464646464545464646464643535353564646464645454646464646435353535646464646454
06060606065454545454540606060606060606545464353535356454540606065464646464646464646464646464645454646464646464646464646464646454
54020404040414141424540404040454540104050444141414244404040402545404050465041414142405040406045454440404040414141414040404014554
06060606065464646464540606060606060606545404141414140554540606065404040404040404040404040405045454040604040404040404040404040454
54040605040424141405540404030454540406142444142414144424141404545406030404052414141404240404025454044401040404241404040504450454
06060606545401040405545406060606060606546404041414140464540606065404060405040404040404040404045454040504040404040404040504060454
54040404040405141465540404046554540514141444142414244414142405545404040404040506142404040404055454040644545404141405545445040454
54545454546404040404645454545454060606546501051414050465540606065404045454540404040454545404045454040454545404040404545454040454
54040401040504241404540404040654546514240444040504044405140565545454545454545454444444444444445454040454546445454545645454040554
54646464646504040404656464646454060606540504041424062404540606065404045454640404040464545406045454040454546404040404645454040454
54454545455454545454540404040464640424140454545454545405140505646464646464646464444444444444445464040464646504140504656464060464
64060404040404040404040404040464060606540405042405040104540606065404046464050514240406646404656454040464640405142404066464040454
54040404045464646464640424041435351405060564646464646404141414353514140505040404141424040404655435140405440405140602044404041435
35140405040404241405010404051435060606545404142414060454540606065404040504041525140524040405143554040604040415251405040404040454
54040506045404241414441405241435351405140401040504040404240514353514142414141414240605040504045435141414441424142414244424141435
35142414141424152514061414141435060606545404145454240454540606065404040404141626142405141414243554040404041416261424050404040554
54040404045424241405442414141435351424140504040406040405142414353514141424062414141401040404045435140524441424141414144414241435
35141414241414162624141405141435060606545404246464140454540606065404040404241424152514241424143554040404042414241525140404040454
54444444445405141406440404052435351414240454545454545404141414353514240504240504142404040406655435140404440604142405044404051435
35140501040405142404040404041435060606546404061405140464540606065404040404060514162624050404143554040404040605141626040404060454
54040404046404142404545404040454540404040664646464646404040504545454545454545454454545454545455454040454546504140504655454040454
54040404040504040404040404010454060606540404241414010406540606065404065454050414140504545404655454040454540404141405055454040454
54040404044501051424545404040554540405040404454545450406040404545464646464646464454545454545455454040564545445454545545464040454
54545454546506040404655454545454060606540104062405040404540606065404065454540404040454545404045454040454545404140504545454040454
54650605044506141405545404046554540404040404454545450404050404545417040404240405142404040404045454040445646404141404646444040354
64646464545404040504545464646464060606546504051414040565540606065404046464640404040464646404045454040464646404241404646464050454
54040404044504142405545405030454540404040504454545450404060404545404030404042414141405040604045454064504030405241404040405440454
06060606645404040401546406060606060606545404241414240454540606065404050404240404040404040604055454060404040504142405240404040454
54050404044524141414545406040454540306046504454545450465040403545405040465051424141404060405015454450405040414141414040404064454
06060606065454545454540606060606060606545405141414140454540606065404040404040404040404040404045454050404046524141414650504040454
54545454545435353535545454545454545454545454545454545454545454545454545454543535353554545454545454545454545435353535545454545454
06060606066464646464640606060606060606545454353535355454540606065454545454545454545454545454545454545454545435353535545454545454
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008800000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088800000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000888200000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000882000000000000000000000000000000
00000000000000000000088880000000000888800000000000000000000000000000000000000000000000000000000820000000000000000000000000000000
00000000000000000008822888000000008222200000000000000000000000000000000000000000000000000000000200000000000000000000000000000000
00000000000000000088200888000000082000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000882000888800000080000008880000888800088800008880000000888800008880000888000008880000000088880000000000000000000
00000000000000000880000828800000880000882288008228800828800882880000088228880882880088288000888820000008822280000000000000000000
00000000000000000220008802880000820008220088082008808208808220880000822002880220880822088000228800000082200080000000000000000000
00000000000000000000008800880000800088000088020008882008882000880008800000880000888200088000008800000880000020000000000000000000
00000000000000000000008800288000800082000882000088820008880008820008200000880000888000088000008800000820000000000000000000000000
00000000000000000000008200088808800880008820000088800088820008800088000000880000882000088000008800008800000000000000000000000000
00000000000000000000008000028808800888882200000088200088200008800088000000820000880000882000008200008800000000000000000000000000
00000000000000000000082000002888200882220000000088000088000088200088000008800008820000880000088000008800000000000000000000000000
000000000000000000000800000008880008800000080008880000880000880008880000dddddddd800000880080088008008800000800000000000000000000
00000000000000880000820000000288000888000882000882000088000088008288800dd555d55d8000008808200880820088800082000ddd00000000000000
0000000000000028888820000000008800028888822000088000088200008888202888dd5555555d800000888200088820002888882000dd5d00000000000000
0000000000000002222200000000002200002222200000022000022000002222000222d55555555d20000022200002220000022222000dd55d00000000000000
000000000000000000000000000000000000000000000000000000000000000000000dd55ddd555d00000000000000000000000000000d555d00000000000000
000000000000000000000000000000000000000000000000000000000000000000000d555d1dd55dddddddddddddddddddddddddddd0dd555dd0000000000000
000000000000000000000022002020000022002220222002200000220022202020000d555d01dddd5555d55d5555dd55555555d555ddd55555d0000000000000
000000000000000000000022002220000020202200222020200000202022002020000d555d00111d5555555d5555dd5555555555555dd55555d0000000000000
000000000000000000000020200020000020202000202020200000202020002220000d555d00000dd555555dd555ddd55dd555ddd555dd555dd0000000000000
000000000000000000000022202200000020200220202022002220220002200200000d555d000001d5555dddd555ddd55dd555d1d555dd555d10000000000000
000000000000000000000000000000000000000000000000000000000000000000000d555d00ddd0d555dd11dd555d55ddd555d0d555dd555d00000000000000
000000000000000000000000000000000000000000000000000000000000000000000d555d00d5ddd555d1001d555d55d1d555d0d555dd555d00000000000000
000000000000000000000000000000000000000000000000000000000000000000000d555dddd55dd555d0000d555d55d0d555d0d555dd555d00000000000000
000000000000000000000000000000000000000000000000000000000000000000000dd555dd555dd555d0000dd55555d0d555d0d555dd555d00000000000000
0000000000000000000000000000000000000000000000000000000000000000000001d5555555ddd555dd0001d5555dd0d555ddd555dd555dd0000000000000
0000000000000000000000000000000000000000000000000000000000000000000000dd555555dd55555d0000d5555d10d55555555ddd5555d0000000000000
00000000000000000000000000000000000000000000000000000000000000000000001dd5555ddd55555d0000dd555d00d555d555dd1dd555d0000000000000
000000000000000000000000000000000000000000000000000000000000000000000001dddddd1ddddddd00001d55dd00d555ddddd101ddddd0000000000000
0000000000000000000000000000000000000000000000000000000000000000000000001111110111111100000d55d100d555d1111000111110000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddd55d00dd555dd000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d5555d00d55555d000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d555dd00d55555d000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddddd100ddddddd000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110001111111000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000002222222222222220000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000002222222222222220000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000002222222222222220000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000002222222222222220000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000002222222222222220000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000222220000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000222220000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000222220000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000222220000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000222220000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000222220000088888000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000222220000088888000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000222220000088888000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000222220000088888000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000222220000088888000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000222220000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000222220000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000222220000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000222220000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000222220000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000002222200000222220000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000002222200000222220000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000002222200000222220000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000002222200000222220000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000002222200000222220000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000222222222222222000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000222222222222222000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000222222222222222000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000222222222222222000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000222222222222222000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000222222222222222000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000222222222222222000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000222222222222222000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000222222222222222000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000222222222222222000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000022222222222222222222000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000022222222222222222222000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000022222222222222222222000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000022222222222222222222000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000022222222222222222222000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002020220000222000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002020020000002000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002020020000222000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002220020000200000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200222020222000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001040101010000000000000000000000010801100101000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
5555555555555555555555555555555555555555555555555555555555554545454646464646464646464646464646454546464646465353535346464646464545464646464646464646464646464645454646464646464646464646464646454546464646464646464646464646464545464646464653535353464646464645
5560606060606060606060606060606060606070606060606060607160604545454040404040404040404040403040454554545440564141414256404444444545404040404440404040444040405045452040404040404040604040504040454540504040404040604040404050604545404040405641424141564040505045
5560606060606060606060606060606060606060606071726060606060604545454030405040404040404040406040454554545440405042424040304444444545401040404440401040444040404045454040604040404060404050404040454540604040404040404040404050504545404040504050414250404040504045
5560606060606060606060606060606060606060606060604545606060604545454040504040404040404050406040454554545440404041416050404444444545404040404450404060444040406045454040604020404040404040204040454540404545454040504045454540404545404045454540424150454545404045
5560606060606060606060606060606060607156454560604646606045454545454040405645454250454556404040454540404045455042414245454040404545404040564545424045455640404045454040404040564040564040404040454540404545464040404046454540404545404045454642414150464545406045
5560606060606060606060606060606070606060464660606060605646464646464040404545465353464545404040454540404046465353535346464020404545545454454545535345454554545446454040504040455353454040404040454656504646405041424060464640404545506046466050414260404646404045
5560606060606060606060606060606060605060605060605060605051525042534260504646515241304646404050454540604040535152414253404040404545404050464651524250464650604253454040404040455242454040404040455341405040405152415040404040404545404040404051524150404040404045
5560606060606060606060606060606050416041416041415152424161624141534141424153616364425350404050454540304040536163644153406050404545403040425361636442534141425053454045454040456364454040454540455341414142416162414250404040404545404040404161624142504050404045
5560606060606060606060606060606042605041604260426162414142415152536042414253417374525342404040454540504040534173745253404060404545404040405342737452534241414153454046464040457374454040464640455341426041424142515241405040404545405040404241425152414040404045
5560606060606060606060606041604241506060606050606060506050416162534150424545424161624545404010454540404050535042616253404040404545404040454550416162454542504053454050404040454161454040404040455342505040605041616240504040404545404040406050416162404040604045
5560606060606060606060605060415060416060454560605050605645454545454040404645455353454546404040454556404045455353535345454040564545545454464545535345454654545445454040404040465353464040405040454556404545504041415040454540404545404045455040414150404545404045
5560606060606060606060606060606060606056464660604545606046464545454060405646465060464656406040454540404046464260404046464040604545404040564646604246465640404045454040404050565041564040404040454540404545454040404045454540404545404045454540404040454545404045
5560606060606060606060606060606060706070606060604646606060604545454060504040404040404040404040454544444440404050404040405454544545404040404450504040444040404045456060404040424141504040404040454540404646464040604046464640404545404046464640504040464646404045
5560606060606060606060606060606060606060716060606060606060604545454040404040404060404040504040454544444440204040304040405454544545401040404440401040444060604045454040404040404142604040604040454540505040404050404040404040404545405040404040604040404040404045
5560606060606060606060606060606060606060606060606060606060604545454040104040404040404040404040454544444450404040404040405454544545604040404440404040444040404045454030405640504150424056403040454560404040406040404040404040504545404060404040404040404040504045
5555555555555555555555555555555555555555555555555555555555554545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545535353534545454545454545454545454545454545454545454545454545454545454545454545454545
4546464646464646464646464646464545464646464646464646464646464645454646464646464646464646464646454546464646464646464646464646464545464646464646464646464646464645454646464646464545464646464646454546464646464646464646464646464560606060454653535353464560606060
4550604040404040404060404040404545725040404040404040406040405045454040404040504040405440404040454540404040405454544040405640404545404056404040404050404056406045453040404040604545564040404040454540404040404044444060604040604560606060456042414241304560606060
4540404040404040404040402040404545404040104040424160404040104045454020406040404040405440605040454540401040405454544040404020404545403040404050404040404040204045454010404040404545405040204040454540204050404044444040404040404560606060454050424150404560606060
4540404010404060404040504040604545564040404041515242404040405645454040605040404010405440403040454540504040405454544010404040404545404040604040404010406040404045454040404040404545404040404040454556404040404044444010504040564560606060455640414240564560606060
4545455640404545404056454545454545404050604042616241104040404045454040404545454545454556404040454556404045454545454545454060404545504060404040404040404050404045455640605040404545404060604040454540604010404044444040405040404560606060454040416050404560606060
4546464040404646404040464646464645401040404060424140404050404045454040404545464646464640404050464640406046464646464645454050604546404040405454545454444040405046464060404040404646404040504040454640404040404044444040404040404660606045454040424140404545606060
4540405040604141506042404050415345504040404042414250404040406045454050404545444040504042605041535341425040404240405045454040404553415040504445454545444240504153534150405040444444444040404056455341404040404545454540504050415345454545464050415040404645454545
4540404040425152414250414141415345454545454554545454454545454545454040404545404441414141424141535341414141425152424045454444444553414241414445454545444142414153534141424141444142444545454545455341424150414545454541414142415345464646404041454542104046464645
4540104040416162424141424241415345464646464654545454464646464645456040404545404144504241414141535341414241506162604045454444444553414141424445454545444241424153534141416041445041444646464646455342415042414545454541424150415345724040405041464641404040404045
4540404040504241604042405060415345504040405650414242564040404045454040404545404241446050504241535341506050425042507245454040404553414250604446464646446050404153534150404545454444444040404040455341504040404646464640405060425345404040605042414142404060405045
4545454040404545404040454545454545404060404040426050404040604045455454544646506041504545406050454550404045454545454545454050404545504040504454545454545040404045454040404545454141504040405040454540404054545041415054544040404545405060424150515241504250204045
4546465640404646404056464646464545404045454040414240404545506045454040405640504241404646404056454556104046464646464646466040404545404050404040404040404040404045455454544646464142504060404040454540505454544041424054545450604545404050414241616242414140404045
4550404040404040406040504040404545405046464040425040404646404045454060404040404142504040404040454540504040405454544040604040404545404040404050404010404060404045454040425440504142604040401040454540545454404050414040545454404545406040404040401040604060404045
4540204060404040404040404030404545406040404050414140404071204045454030404050424141401040405040454540404040405454544040404040404545402040404040404040604040404045454250405440404241504050404040454554545440406041425040405454544545104056406040404040405650406045
4540504040404040404040406040504545204040406041424141404040404045455040405040414141414256404060454530604040405454544040505640604545404056406060404040404056504045455040425450414141424056404030454554543040564141414156403054544545454545454570404060454545454545
4545454545454545454545454545454545454545454553535353454545454545454545454545535353534545454545454545454545454545454545454545454545454545454545454545454545454545454545454545535353534545454545454545454545455353535345454545454546464646464545454545454646464646
__sfx__
251000000017500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105
750200001f1501f1501a1501a15016150161500010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
510400000416300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000003456524505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505
39030000161711617113161131610f1510f1510a1410a141001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
690400000a3510a3510f3510f3510a3510a3510735107351033510335103301000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001
6d040000163301b350133700a3500a320056400563003620036100360003600006000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6d0500001b1161b12624136241562e1562e1662b1462b166351563514630146301363a1363a13630126301263a1263a11630116301163a1163a11600106001060010600106001060010600106001060000600006
3d0a000016570165700f5700f57009570095700157001570015700157000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000000000000
0d0600002e5112e52533531335453a5503a5653a5003a5353a5003a5253a5003a5053a5003a505005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
8d0300001b5561d556305062255624556305061f55622556055062455627556365061d556225563050627556295561b5061b5561d5561f556225563b506275563c506295563d5063d5062b556005060050600506
870500001d65224662276721f6521b6421b642186421664216642136321362216622166221662216622136220f6220f6220f6220f6220f6220f6220a6120a6120761205612056120561205612036120361203602
451400000c0620c0620c0620c0620c002080620806208062080620f00200062000620006200062000620006200062000020000200002000020000200002000020000200002000020000200002000020000200002
0004000005450054500545005400004500045000450004000f4000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
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
cd2200000c0120c0220c0320c0320c0220c012000020c0020a0120a0220a0320a0320a0220a012000020500205012050220503205032050220501207002070020701207022070320703207022070120000200002
cd200000030120302203032030320302203012000020c002050120502205032050320502205012000020500200012000220003200032000220001207002070020001200022000320003200022000120000000000
450c00000c7720c7620c7520c7420c7320c722007020c7020a7720a7620a7520a7420a7320a722007020570205772057620575205742057320572207702077020777207762077520774207732077220070200702
450c0000037720376203752037420373203722007020c702057720576205752057420573205722007020570200772007620075200742007320072207702077020077200762007520074200732007220070000700
450c00000c0630000000000000000c0630000000000100630c0630000000000000000c0630000010063100630c0630000000000000000c0630000000000100630c0630000000000000000c063000001006310063
a11200000c0730e07300000000000c0030e00300000000000c0730e07300000000000c0030e00300000000000c0730e07300000000000c0030e00300000000000c0730e07300000000000c0030e0030000000000
__music__
01 1a1c4344
02 1b1c4344
01 18424344
02 19564344
03 1d424344

