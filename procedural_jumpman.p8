pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
--[[
============================
jumpman 0.8
arjen schumacher - 2018
----------------------------
www:      hardmoon.net
twitter:  @unity_student
facebook: /arjenschumacher
==========================]]

--[[
todo
- add enemies in procedural gen levels
- bug: player can still skip tiles
  when moving up stairs
- bug: player can diagonally
  escape from lower stairs through walls
- bug: still isolated rooms in generate_level()?
- give enemy a fire timer
  and shoot when player is
  within vicinity on y-axis
- animate opening door
- hiscore/save highscore?

]]

--[[
============================
draw routine
==========================]]
function _draw()
    cls()
    if bool_gamemode==0 then
        main_menu_routine()
    elseif bool_gamemode==1 then
        draw_map_routine()
        draw_gameinfo_routine()
        fncdrawelev()
        draw_nmy()
        elevator_stand_routine()
        draw_player_routine()
        bullet_routine()
        draw_exit_routine()
    elseif bool_gamemode==2 then
        next_level_routine()
    elseif bool_gamemode==3 then
        gameover_routine()
    end

    --rect(pl.x,pl.y+4,pl.x+7,pl.y+7,3)
    if pl.fell==true then
        camera(rnd(10)-5,rnd(10)-5)
    else
        camera(0,0)
    end
end



--[[
============================
load a new level level
@param int level
==========================]]
function load_level(level)
    crd={}
    crd.yellow=false
    crd.blue=false
    crd.green=false
    crd.red=false
    glb_colrate=0
    glb_warptime=64
    setup_map(level)
    restore_map(level)
    setup_level()
    setup_player()
    setup_player_start()
    setup_exit()
    setup_door()
    setup_elevator()
    setup_nmy()
    setup_diamonds()
    fnccntdia()
end


-- reset a level
function fncrstlvl()
    pl.fell=false
    pl.x=pl.startx*8
    pl.y=pl.starty*8
end


-- control routine
function input_routine()
    fnckey()
    walk_routine()
    fncjump()

    if pl.x > 119 then
        pl.x = 119
    end
    if pl.x < 0 then
        pl.x = 0
    end
    if pl.y > 119 then
        pl.y = 119
    end
    if pl.y < 0 then
        pl.y = 0
    end
end


--[[
============================
inputcontrol and walking
==========================]]
function walk_routine()
    -- get topcenter collision of sprite against stair
    glb_coll_stair_tl=mget(
        flr((pl.x+4)/8)+(mpr.lvl*16),
        flr((pl.y+4)/8)
    )
    -- get bottomcenter collision of sprite against stair
    glb_coll_stair_br=mget(
        flr((pl.x+4)/8)+(mpr.lvl*16),
        flr((pl.y+8)/8)
    )
    -- get ground collision
    glb_coll_stair_gr=mget(
        flr((pl.x+4)/8)+(mpr.lvl*16),
        flr((pl.y+7)/8)
    )

    local posx = pl.x

    pl.sx = 0

    if btn(⬅️) then
        pl.bl_flipped = true
        pl.sx = -pl.speed
        if pl.bl_stand then
            pl.sprt+=pl.animspeed
        end
    end

    if btn(➡️) then
        pl.bl_flipped = false
        pl.sx = pl.speed
        if pl.bl_stand then
            pl.sprt+=pl.animspeed
        end
    end

 -- player standing still
 -- or walking around
    if not btn(⬅️) and not btn(➡️) then
        pl.sprt = 1
    else
        if pl.sprt == 3 and pl.bl_stand then
            sfx(snd.stp)
        end
    end

    pl.x+=pl.sx
    if pl.sprt > 7 then
        pl.sprt = 2
    end

 -- show sprite 3 while jumping
    if not pl.bl_stand then
        pl.sprt = 3
    end

    if fget(glb_coll_stair_tl,2) or fget(glb_coll_stair_br,2) then
        pl.sy = 0
        if btn(⬆️) then
            if fget(glb_coll_stair_gr,2) then
                pl.y-=1
                pl.ladder+=pl.animspeed
            end
        elseif btn(⬇️) then
            pl.y+=1
            pl.ladder+=pl.animspeed
        end
        if pl.ladder >= 40.9 then
            pl.ladder=37
        end
    end

 collide_routine(posx)
end


--[[
============================
shoot and bullet control
==========================]]
function bullet_routine()
    if btnp(5) and pl.alive then
        -- a bullet is fired!
        sfx(snd.shoot)
        bulletcount+=1
        glb_blt[bulletcount]=add_bullet()
    end

 -- process all active glb_blt
    for i=1,bulletcount do
        if glb_blt[i].dead==false then

            -- active bullet routine
            glb_blt[i].x+=glb_blt[i].speed
            glb_blt[i].sprite+=0.2

            -- bullet animation
            if glb_blt[i].sprite >= 34.9 then
                glb_blt[i].sprite = 33
            end

            spr(flr(glb_blt[i].sprite),glb_blt[i].x,glb_blt[i].y,1,1,glb_blt[i].flipped)

            -- check wall collision
            if fget(mget(glb_blt[i].x/8+(mpr.lvl*16),glb_blt[i].y/8),0) then
                glb_blt[i].dead=true
            end

            -- bullet offscreen?
            if glb_blt[i].x < -8 or glb_blt[i].x > 128 then
                glb_blt[i].dead=true
            end

            bdist1=7
            bdist2=5
            if glb_blt[i].flipped==true then
                bdist1=0
                bdist2=2
            end

            -- check baddie hit
            for j=1,count(nmy) do
                if nmy[j].dead==false then
                    if glb_blt[i].x+bdist1 >= nmy[j].x+1 and
                    glb_blt[i].x+bdist1 <= nmy[j].x+6 and
                    glb_blt[i].y+bdist2 >= nmy[j].y and
                    glb_blt[i].y+bdist2 <= nmy[j].y+7 then
                        nmy[j].dead=true
                        score+=50
                        glb_blt[i].dead=true
                        glb_blt[i].x = nmy[j].x
                        glb_blt[i].y = nmy[j].y
                        glb_blt[i].explode=true
                        sfx(snd.nmyexpl)
                    end
                end
            end
        end


        if glb_blt[i].dead==true then
            if glb_blt[i].explode==false and
            glb_blt[i].explodecount==0 then
            end
            for k=0,glb_blt[i].partcnt-1 do
                if glb_blt[i].particles[k+1].size > 0 then
                    circfill(
                    glb_blt[i].x+4+rnd(14)-7,
                    glb_blt[i].y+4+rnd(14)-7,
                    glb_blt[i].particles[k+1].size,
                    rnd(3)+5
                    )
                    glb_blt[i].particles[k+1].size-=0.2
                end
            end
        end
    end

end


function fncbulexpl(blt)
    return blt
end


--[[
============================
jump control
==========================]]
function fncjump()

    -- detect a valid jump
    if btnp(4) and
       pl.bl_stand then
        if not fget(glb_coll_stair_tl,2) and
        not fget(glb_coll_stair_br,2) then
            pl.sy =- pl.jumpspeed
            sfx(snd.jump)
        else
            pl.sy = 0
        end
    end
    local collide_l=mget((pl.x+2)/8+(mpr.lvl*16),(pl.y+8)/8)
    local collide_r=mget((pl.x+5)/8+(mpr.lvl*16),(pl.y+8)/8)

    pl.bl_stand = false
    -- apply gravity and position
    -- not on stairs?
    if not fget(glb_coll_stair_tl,2) and
       not fget(glb_coll_stair_br,2) then
        pl.sy+=env.gravity
        pl.y+=pl.sy
    elseif pl.sy < 0 then
        -- player still jumping up!
        pl.sy+=env.gravity
        pl.y+=pl.sy
        -- check if player is jumping half through ceiling
        local wcol_l=mget((pl.x)/8+(mpr.lvl*16),(pl.y+4)/8)
        local wcol_r=mget((pl.x+7)/8+(mpr.lvl*16),(pl.y+4)/8)
        if fget(wcol_l) == 1 then
            pl.x+=1
        end
        if fget(wcol_r) > 0 then
            pl.x-=1
        end
    else
        --  pl.sy = 0
        pl.bl_stand=true
    end

    if pl.sy>=0 then
        -- player finds ground
        if fget(collide_l,0) or
        fget(collide_r,0) then
            -- player drops dead
            if pl.sy > pl.deathgravity then
                pl.alive = false
                pl.fell=true
                sfx(snd.fall)
            end

            -- player lands safely
            pl.y = flr((pl.y)/8)*8
            pl.sy = 0
            pl.bl_stand=true
        end
    end
    fnccollceiling()
end


function elevator_stand_routine()
    for i=1,elevcnt do
        if ((pl.x+2 >= elevator[i].x and
          pl.x+2 <= elevator[i].x+7) or
        (pl.x+5 >= elevator[i].x and
        pl.x+5 <= elevator[i].x+7)) and
        (flr(pl.y+8) == flr(elevator[i].y) or
         flr(pl.y+7) == flr(elevator[i].y) or
         flr(pl.y+9) == flr(elevator[i].y)) then
            pl.sy=0
            pl.y=elevator[i].y-8
            -- push player to right because running into wall on the left
            if fget(mget((pl.x/8)+mpr.lvl*16,pl.y/8),0) or
               fget(mget((pl.x/8)+mpr.lvl*16,(pl.y+7)/8),0) then
               pl.x+=1
            end
            -- push player to left because running into wall on the right
            if fget(mget(((pl.x+7)/8)+mpr.lvl*16,pl.y/8),0) or
               fget(mget(((pl.x+7)/8)+mpr.lvl*16,(pl.y+7)/8),0) then
               pl.x-=1
            end
--            pl.x=elevator[i].x
            pl.bl_stand=true
            return true
        end
    end
    return false
end

--[[
============================
next level transition
==========================]]
function next_level_routine()
    local x = 0
    local y = 0

    for j=0,7 do
        for i=0,15 do
            local col = i+glb_colrate
            if col > 15 then
                col = col-16
            end
            rect(x,y,128-x,128-y,col)
            x+=1
            y+=1
        end
    end

    glb_colrate+=1
    glb_warptime-=1

    if glb_warptime < 1 then
        music(-1)
        bool_gamemode=1
        sfx(10)
        music(10)
        if(infinitemode==false) then
            mpr.lvl+=1
        end
        load_level(mpr.lvl)
    end
end


--[[
============================
draw the map
==========================]]
function draw_map_routine()
    map(mpr.offset,0,0,0,mpr.width,mpr.height)
end

--[[
============================
player sprite handling
==========================]]
function draw_player_routine()
    if pl.alive then
        if fget(glb_coll_stair_tl,2) or
        fget(glb_coll_stair_br,2) then
            spr(flr(pl.ladder),pl.x,pl.y,1,1,pl.bl_flipped)
        else
            spr(flr(pl.sprt),pl.x,pl.y,1,1,pl.bl_flipped)
        end
    else
        spr(flr(death)+8,pl.x,pl.y,1,1)
        for k=0,pl.ptlcount-1 do
            if pl.ptl[k+1].size > 0 then
                circfill(
                pl.x+4+rnd(20)-10,
                pl.y+4+rnd(20)-10,
                pl.ptl[k+1].size,
                rnd(3)+8
                )
                pl.ptl[k+1].size-=0.2
            end
        end
        death+=0.10
        if death > 2.9 then
            death = 0
            lives-=1
            set_player_death_seq()
            pl.alive = true
            pl.fell = false
            if lives==0 then
                bool_gamemode=3
                music(20)
               -- fncmainmnu()
            end
            fncrstlvl()
        end
    end
end

--[[
=============================
game over screen
===========================]]
function gameover_routine()
    cls(2)
    fncprint("game over",40,50,7,true)
    fncprint("your score: "..score,40,60,7,false)
    if btnp(4) then
        bool_gamemode=0
        fncmainmnu()
    end
end

--[[
============================
draw exit when visible
==========================]]
function draw_exit_routine()
    if door.visible==true then
        spr(flr(door.sprite),door.x,door.y,1,1)
        door.sprite+=door.animspeed
        if door.sprite > door.animend then
            door.sprite=door.animstart
        end
    end
end


--[[
============================
draw ingame information
==========================]]
function draw_gameinfo_routine()
    fncprint("score: "..score,3,1,7,false)
    local a=""
    for i=1,lives do
        a=a.."♥"
    end
    fncprint(a,122+(4-lives*8),1,7,false)

    crds=""
    crdoff=75

    if crd.yellow==true then

        fncprint("&",crdoff,1,10,false)
        crdoff+=5
    end
    if crd.blue==true then
        fncprint("&",crdoff,1,12,false)
        crdoff+=5
    end
    if crd.red==true then
        fncprint("&",crdoff,1,8,false)
        crdoff+=5
    end
    if crd.green==true then
        fncprint("&",crdoff,1,11,false)
    end
    -- fncprint("cpu: "..(stat(1)*100).."%",50,1,7,false)
    -- fncprint(fget(mget((pl.x+4)/8+(mpr.lvl*16),(pl.y+8)/8),0),50,1,7,false)
end


function fncdrawelev()
    if elevcnt > 0 then
        for i=1,elevcnt do
            elevator[i].y+=elevator[i].speed
            if elevator[i].y<elevator[i].top or
            fget(mget(elevator[i].x/8+(mpr.lvl*16),((elevator[i].y/8)+1))) == 1 then
                elevator[i].speed=-elevator[i].speed
                elevator[i].y+=elevator[i].speed
            end
            spr(tls.elevatorsprite,elevator[i].x,elevator[i].y,1,1)
        end
    end
end


--[[
============================
draw enemies
==========================]]
function draw_nmy()
    for i=1,count(nmy) do
        if nmy[i].dead==false then
            -- move baddie
            nmy[i].x+=nmy[i].sx
            nmy[i].sprite+=0.3

            -- set next baddie sprite
            if nmy[i].sprite > 23.9 then
                nmy[i].sprite=18
            end

            -- detect tiles left and right
            collide=mget(nmy[i].x/8+(mpr.lvl*16),nmy[i].y/8)
            if fget(collide,0) then
                nmy[i].sx=-nmy[i].sx
                nmy[i].x+=nmy[i].sx
            end
            collide=mget((nmy[i].x+8)/8+(mpr.lvl*16),nmy[i].y/8)
            if fget(collide,0) then
                nmy[i].sx=-nmy[i].sx
                nmy[i].x+=nmy[i].sx
            end

            -- detect floor tiles
            collide=mget((nmy[i].x+4)/8+(mpr.lvl*16),(nmy[i].y+8)/8)
            if not fget(collide,0) then
                nmy[i].sx=-nmy[i].sx
                nmy[i].x+=nmy[i].sx
            end

            -- detect player
            if (pl.x+2 >= nmy[i].x+2 and
                pl.x+2 <= nmy[i].x+5 and
                pl.y+4 >= nmy[i].y and
                pl.y+4 <= nmy[i].y+7) or
               (pl.x+5 >= nmy[i].x+2 and
                pl.x+5 <= nmy[i].x+5 and
                pl.y+4 >= nmy[i].y and
                pl.y+4 <= nmy[i].y+7) or
               (pl.x+2 >= nmy[i].x+2 and
                pl.x+2 <= nmy[i].x+5 and
                pl.y+7 >= nmy[i].y and
                pl.y+7 <= nmy[i].y+7) or
               (pl.x+5 >= nmy[i].x+2 and
                pl.x+5 <= nmy[i].x+5 and
                pl.y+7 >= nmy[i].y and
                pl.y+7 <= nmy[i].y+7) then

                if pl.alive == true then
                    pl.alive = false
                    pl.fell=true
                    pl.sy=0
                    sfx(snd.death)
                end
            end
            -- draw sprite
            flipped=false
            if nmy[i].sx < 0 then
                flipped=true
            end
            spr(nmy[i].sprite,nmy[i].x,nmy[i].y,1,1,flipped)
        end
    end
end

-- draw shadow print @param str txt, int x, int y, int col, bool blink
function fncprint(txt,x,y,col,blink)
    local show=true

    if blink then
        glb_printcount+=1
        if glb_printcount > 25 then
            show=false
            if glb_printcount > 50 then
                show=true
                glb_printcount=0
            end
        end
    end
    if show then
        print(txt,x+1,y+1,5)
        print(txt,x,y+1,5)
        print(txt,x+1,y,5)
        print(txt,x,y,col)
    end
end


-- count diamonds in level
function fnccntdia()
    dia.total = 0

    for x=0,15 do
        for y=0,15 do
            local spos=mget(x+(mpr.lvl*16),y)
            if spos==tls.dia1 or
            spos==tls.dia2 or
            spos==tls.dia3 or
            spos==tls.dia4 then
                r=flr(rnd(4)+1)
                if (r==1) mset(x+(mpr.lvl*16),y,70)
                if (r==2) mset(x+(mpr.lvl*16),y,71)
                if (r==3) mset(x+(mpr.lvl*16),y,72)
                if (r==4) mset(x+(mpr.lvl*16),y,74)
                dia.total+=1
            end
        end
    end
end


--[[
============================
show main menu
==========================]]
function main_menu_routine()
    cls(1)
    spr(208,16,2,12,3)
    fncprint("coding, gfx and music by",18,29,7,false)
    fncprint("arjen schumacher",33,37,7,false)
    fncprint("⬅️ = left",20,50,7,false)
    fncprint("➡️ = right",20,58,7,false)
    fncprint("⬆️ = up",73,50,7,false)
    fncprint("⬇️ = down",73,58,7,false)
    fncprint(" z = jump",20,66,7,false)
    fncprint(" x = shoot",73,66,7,false)
    fncprint(" p = menu",20,74,7,false)
    fncprint("press up / ⬆️ to start",20,92,10,true)
    fncprint("www.hardmoon.net (c) 2018",14,120,7,false)
    if btn(2) then
        reset_game()
        music(-1)
        bool_gamemode=1
        sfx(10)
        music(10)
    end
end


--[[
============================
store initial mapdata
in an array
==========================]]
function map_memorize()
    local tile=0
    for x=0,127 do
        glb_map_store[x] = {}
        for y=0,63 do
            tile = mget(x,y)
            glb_map_store[x][y]=tile
        end
    end
end


--[[
============================
restore map from array
==========================]]
function restore_map(level)
    local tile=0
    for x=0,15 do
        for y=0,15 do
            mset(x+(level*16),y,glb_map_store[x+(level*16)][y])
        end
    end
    generate_level(level)
end

--[[
===========================
generate a random level
=========================]]
function generate_level(level)
    -- fill up map
    for x=0,15 do
        for y=1,15 do
            mset(x+(level*16),y,96)
        end
    end

    -- do sides
    for y=1,15 do
        mset(0+(level*16),y,101)
        mset(15+(level*16),y,102)
    end

    -- do corners
     --[[
    r=rnd(3)+98
    mset(0+(level*16),15,r)
    r=rnd(3)+98
    mset(15+(level*16),15,r)]]

    -- now dig some floors per y level
    for y=1,14 do
        validated=false
        while validated==false do
            goodsize=false
            while goodsize==false do
                x1=rnd(14)+1
                x2=rnd(14)+1
                if x1 > x2 then
                    x3=x2
                    x2=x1
                    x1=x3
                end
                if (x2-x1 > 4) then
                    goodsize=true
                end
            end
            if(y > 1) then
                for x=x1,x2 do
                    if(fget(mget(x+(level*16),y-1),0)==false) then
                        validated=true
                    end
                end
            else
                validated=true
            end
            if(validated==true) then
                for x=x1,x2 do
                    mset(x+(level*16),y,97)
                end
            end
        end
    end

    -- now dig some chasms per x column
    for x=1,14,flr(rnd(5))+1 do
        validated=false
        while validated==false do
            goodsize=false
            while goodsize == false do
                y1=rnd(14)+1
                y2=rnd(14)+1
                if y1 > y2 then
                    y3=y2
                    y2=y1
                    y1=y3
                end
                if (y2-y1 > 2) then
                    goodsize=true
                end
            end
            if(x > 1) then
                for y=y1,y2 do
                    if(fget(mget(x+(level*16)-1,y),0)==false) then
                        validated=true
                    end
                end
            else
                validated=true
            end

            if validated==true then
                for y=y1,y2 do
                    mset(x+(level*16),y,97)
                end
            end
        end
    end

    -- check for deep chasms ( >= 3 high) and place stair or elevator
    for x=1,14 do
        counter=0
        done=false
        for y=1,14 do
            if mget(x+(level*16),y) == 97 then
                if done==false then
                    counter+=1
                    if counter >= 4 then
                        for by=y-counter,y do
                            if(mget(x-1+(level*16),by) == 96 or mget(x+1+(level*16),by) == 96) and (mget(x-1+(level*16),by-1) == 97 or mget(x+1+(level*16),by-1) == 97) and mget(x+(level*16),by-1) == 97 and done == false then
                                if(flr(rnd(3)) == 1) then
                                    -- elevator
                                    mset(x+(level*16),by,67)
                                else
                                    -- stairs
                                    stairdone=false
                                    for cy=by,14 do
                                        if fget(mget(x+(level*16),cy),0) == false and stairdone == false then
                                            mset(x+(level*16),cy,103)
                                        else
                                            stairdone=true
                                        end
                                    end
                                end
                                done=true

                            end
                        end
                    end
                end
            else
                counter=0
            end
        end
    end

    -- smooth out stones
    for x=0,15 do
        for y=1,15 do
            if fget(mget(x+(level*16),y),0) == true then
                -- left/right/up/down flag-0 statuses
                tu=fget(mget(x+(level*16),y-1),0)
                tl=fget(mget(x-1+(level*16),y),0)
                td=fget(mget(x+(level*16),y+1),0)
                tr=fget(mget(x+1+(level*16),y),0)

                -- |_|
                if not tl and
                   not td and
                   not tr and
                   tu then
                       mset(x+(level*16),y,68)
                end
                -- |``
                if not tu and
                    not tl and
                    tr then
                        mset(x+(level*16),y,109)
                end

                -- ``|
                if not tu and
                    tl and
                    not tr then
                        mset(x+(level*16),y,108)
                end


                -- |``|
                if not tu and
                    not tl and
                    td and
                    not tr then
                        mset(x+(level*16),y,87)
                end
                -- |  |
                if tu and not tl and td and not tr then
                        mset(x+(level*16),y,84)
                end
                -- ___
                if tu and
                    tl and
                    not td and
                    tr then
                        mset(x+(level*16),y,105)
                end
                -- |--
                if tu and
                    not tl and
                    td and
                    tr then
                        mset(x+(level*16),y,102)
                end
                -- --|
                if tu and
                    tl and
                    td and
                    not tr then
                        mset(x+(level*16),y,101)
                end
                -- |``|
                --  ``
                if not tu and
                    not tl and
                    not td and
                    not tr then
                        mset(x+(level*16),y,88)
                end
                --  _|
                if tu and
                    tl and
                    not td and
                    not tr then
                        mset(x+(level*16),y,106)
                end
                --  |_
                if tu and
                    not tl and
                    not td and
                    tr then
                        mset(x+(level*16),y,107)
                end
                --  |_|
                if tu and
                    not tl and
                    not td and
                    not tr then
                        mset(x+(level*16),y,68)
                end
            end
        end
    end

    -- place some enemies
    for y=1,15 do
        for x=1,14 do
            ta=fget(mget(x+(level*16)-1,y),0)
            tb=fget(mget(x+(level*16),y),0)
            tc=fget(mget(x+(level*16)+1,y),0)
            ba=fget(mget(x+(level*16)-1,y+1),0)
            bb=fget(mget(x+(level*16),y+1),0)
            bc=fget(mget(x+(level*16)+1,y+1),0)
            clad=fget(mget(x+(level*16),y),2)
            if ta == false and tb == false and tc == false and ba==true and bb==true and bc==true and clad==false then
                if(flr(rnd(3)) == 1) then
                    mset(x+(level*16),y,73)
                end
            end
        end
    end


    -- replace enclosed stones
    tilepos={}
    counter=0
    for x=0,15 do
        for y=1,15 do
            -- place some diamonds
            if fget(mget(x+(level*16),y),0) == false and
               fget(mget(x+(level*16),y),2) == false and
               fget(mget(x+(level*16),y+1),0) == true then
               if(flr(rnd(3))==1) then
                   mset(x+(level*16),y,74)
               end
            end
            if fget(mget(x+(level*16),y),0) == true then
                if fget(mget(x+(level*16),y-1),0) == true and
                    fget(mget(x-1+(level*16),y),0) == true and
                    fget(mget(x+(level*16),y+1),0) == true and
                    fget(mget(x+1+(level*16),y),0) == true then
                        counter+=1
                        tilepos[counter]={px=x,py=y}
                end
            end
        end
    end
    for t=1,counter do
        pos=tilepos[t]
        r=flr(rnd(4))
        if r== 3 then
            mset(pos["px"]+(level*16),pos["py"],flr(rnd(2)+116))
        else
            mset(pos["px"]+(level*16),pos["py"],119)
        end
    end


    -- replace enclosed stones
    tilepos={}
    counter=0
    for x=0,15 do
        for y=1,15 do
            -- place some diamonds
            if fget(mget(x+(level*16),y),0) == false and
               fget(mget(x+(level*16),y),2) == false and
               fget(mget(x+(level*16),y+1),0) == true then
                   counter+=1
                   tilepos[counter]={px=x,py=y}
            end
        end
    end
    pos=tilepos[flr(rnd(counter)+1)]
    mset(pos["px"]+(level*16),pos["py"],89)


    -- random backdrop stones
    tilepos={}
    counter=0
    for x=1,14 do
        for y=1,14 do
            if(mget(x+(level*16),y) == 97) then
                counter+=1
                tilepos[counter]={px=x,py=y}
            end
        end
    end
    for t=5,rnd(10)+10 do
        t=flr(rnd(counter))+1
        pos=tilepos[t]
        mset(pos["px"]+(level*16),pos["py"],flr(rnd(3)+98))
    end

    -- determine start position
    tilepos={}
    setpos={}
    counter=0
    for x=1,14 do
        for y=1,14 do
            if(mget(x+(level*16),y) == 97 and mget(x+(level*16),y+1) == 96) then
                counter+=1
                tilepos[counter]={px=x,py=y}
            end

            if(mget(x+(level*16),y) == 96 and flr(rnd(3)) == 1) then
                mset(x+(level*16),y,104)
                if(fget(mget(x+(level*16),y-1),0) == false and fget(mget(x+(level*16),y-1),2) == false) then
                    if(flr(rnd(2))==1) then
                        t=flr(rnd(3))
                        if t==0 then
                            mset(x+(level*16),y-1,113)
                        elseif t==1 then
                            mset(x+(level*16),y-1,114)
                        elseif t==2 then
                            mset(x+(level*16),y-1,118)
                        end
                    end
                end
            end
        end
    end
    t=flr(rnd(counter))+1
    setpos=tilepos[t]
    mset(setpos["px"]+(level*16),setpos["py"],90)
end


function reset_game()
    score=0
    lives=3
end

--[[
============================
setup global variables
==========================]]
function setup_environment()
end

--[[
============================
setup the map data
==========================]]
function setup_map(level)
    mpr = {}
    mpr.lvl=level
    mpr.offset=level*16
    mpr.width=16
    mpr.height=16
end

-- reset the level
function setup_level()
    death=0
end

-- setup the player data
function setup_player()
    -- player sprite
    pl = {}
    pl.fell=false
    pl.sprt = 1
    pl.ladder=37
    pl.startx = 0
    pl.starty = 0
    pl.x = 0
    pl.y = 0
    pl.sx = 0
    pl.sy = 0
    pl.bl_flipped = false
    pl.speed = 1
    pl.bl_stand = true
    pl.jumpspeed = 2.2
    pl.alive = true
    pl.animspeed=0.5
    pl.deathgravity=3
    pl.ptlcount=rnd(7)+3
    pl.ptl={}
    for k=1,pl.ptlcount do
        pl.ptl[k]={}
        pl.ptl[k].size=rnd(3)+3
        pl.ptl[k].col=rnd(3)+4
        pl.ptl[k].starttime=(k-1)*10
    end
    set_player_death_seq()
end

function set_player_death_seq()
    pl.ptlcount=rnd(9)+7
    pl.ptl={}
    for k=1,pl.ptlcount do
        pl.ptl[k]={}
        pl.ptl[k].size=rnd(2)+2
        pl.ptl[k].col=rnd(3)+4
        pl.ptl[k].starttime=(k-1)*10
    end
end

-- setup the diamond data
function setup_diamonds()
    dia = {}
    dia.sprite = 16
    dia.total = 0
    dia.collected = 0
end

-- setup the exit door data
function setup_exit()
    door = {}
    door.x = 0
    door.y = 0
    door.animstart = 11
    door.animend = 14
    door.visible = false
    door.sprite=11
    door.animspeed=0.5
end

function fncsetupgam()
    tls={}
    tls.bullet=33
    tls.dia1=74
    tls.dia2=70
    tls.dia3=71
    tls.dia4=72
    tls.door=89
    tls.blank=97
    tls.nmy=73
    tls.elevator=67
    tls.elevatorsprite=16
    tls.bullet=64
    tls.bull_item=78
    tls.key_red=80
    tls.key_green=81
    tls.key_blue=82
    tls.key_yellow=83
    tls.door_red=91
    tls.door_blue=93
    tls.door_yellow=94
    tls.door_green=92
    snd = {}
    snd.stp = 0
    snd.jump = 1
    snd.pickup = 2
    snd.death=3
    snd.fall=12
    snd.door=4
    snd.ready=10
    snd.shoot=11
    snd.nmy=13
    snd.nmyexpl=14
    snd.nobullet=15
    snd.pickupbullet=16
    snd.pickupkey=17
    snd.opendoor=18
    env = {}
    env.gravity = 0.13
end

-- setup the exit door
function setup_door()
    for x=0,15 do
        for y=0,15 do
            local spos=mget(x+(mpr.lvl*16),y)
            -- doorplacement tile found?
            if spos==tls.door then
                mset(x+(mpr.lvl*16),y,tls.blank)
                door.x=x*8
                door.y=y*8
                door.visible = false
            end
        end
    end
end



function setup_elevator()
    elevator={}
    elevcnt=0
    for x=0,15 do
        for y=0,15 do
            local spos=mget(x+(mpr.lvl*16),y)
            -- elevator replacement tile?
            if spos==tls.elevator then
                mset(x+(mpr.lvl*16),y,tls.blank)
                elevcnt+=1
                elevator[elevcnt]=add_elevator(x*8,y*8)
            end
        end
    end
end


-- setup the tile labels
function setup_tiles()
end


-- setup the enemy data
function setup_nmy()
    nmy={}
    local count=0
    for x=0,15 do
        for y=0,15 do
            local spos=mget(x+(mpr.lvl*16),y)
            -- baddie tile found?
            if spos==tls.nmy then
                count+=1
                nmy[count]={}
                nmy[count].x = x*8
                nmy[count].y = y*8
                nmy[count].sprite=rnd(6)+18
                nmy[count].sx=(rnd(4)+3)/10
                nmy[count].sy=0
                nmy[count].dead=false
                mset(x+(mpr.lvl*16),y,tls.blank)
                nmy[count].deathseq={}
            end
        end
    end
end


-- setup player start position
function setup_player_start()
    for x=0,15 do
        for y=0,15 do
            local spos=mget(x+(mpr.lvl*16),y)
            if spos==90 then
                mset(x+(mpr.lvl*16),y,65)
                pl.x=x*8
                pl.y=y*8
                pl.startx=x
                pl.starty=y
            end
        end
    end
end


-- add an elevator to map
function add_elevator(x,y)
    local elev={}
    elev.x=x
    elev.y=y
    elev.top=y
    elev.speed=0.2+((rnd(5)+1)/25)
    return elev
end

-- add a newly shot bullet
function add_bullet()
    local b={}
    b.x=pl.x
    b.y=pl.y
    b.explode=false
    b.dead=false
    b.sprite=tls.bullet
    b.flipped=pl.bl_flipped

    b.partcnt=rnd(7)+3
    b.particles={}
    for k=1,b.partcnt do
        b.particles[k]={}
        b.particles[k].size=rnd(3)+3
        b.particles[k].col=rnd(3)+4
        b.particles[k].starttime=(k-1)*10
    end

    if b.flipped == true then
        b.speed = -glb_bltpeed
    else
        b.speed = glb_bltpeed
    end
    return b
end



-- setup the main menu
function fncmainmnu()
    bool_gamemode=0
    setup_player()
    music(0)
    restore_map(0)
    load_level(6)
end

-- collision handling
function collide_routine(posx)

    --wall collisions?
    local xoffset=0
    if pl.sx>0 then
        xoffset=7
    end

    local collide=mget((pl.x+xoffset)/8+(mpr.lvl*16),(pl.y+7)/8)
    if fget(collide,0) then
        pl.x=posx
    end

    --collide with dias?
    collide=mget(pl.x/8+(mpr.lvl*16),pl.y/8)
    collide2=mget((pl.x+7)/8+(mpr.lvl*16),(pl.y+7)/8)
    if fget(collide,1) or fget(collide2,1) then
        if fget(collide,1) then
            mset(pl.x/8+(mpr.lvl*16),pl.y/8,tls.blank)
        else
            mset((pl.x+7)/8+(mpr.lvl*16),(pl.y+7)/8,tls.blank)
        end
        sfx(snd.pickup)
        score+=10
        dia.collected+=1
        if dia.collected==dia.total then
            door.visible=true
            sfx(snd.door)
        end
    end

 -- check for door collide
    collide_exit_routine()
end

-- exit door collision handling
function collide_exit_routine()
    if door.visible == true and
    bool_gamemode == 1 then
        if(pl.x <= door.x and
        pl.y <= door.y and
        pl.x+8 >= door.x and
        pl.y+8 >= door.y) or
        (pl.x <= door.x+8 and
        pl.y <= door.y and
        pl.x+8 >= door.x+8 and
        pl.y+8 >= door.y) or
        (pl.x <= door.x and
        pl.y <= door.y+8 and
        pl.x+8 >= door.x and
        pl.y+8 >= door.y+8) or
        pl.x+8 >= door.x+8 and
        (pl.x <= door.x+8 and
        pl.y <= door.y+8 and
        pl.y+8 >= door.y+8) then
            bool_gamemode = 2
            music(8)
        end
    end
end

function fnckey()
    collide_tr=mget(flr((pl.x)/8)+(mpr.lvl*16),flr((pl.y+4)/8))
    collide_br=mget(flr((pl.x+7)/8)+(mpr.lvl*16),flr((pl.y+7)/8))

    if collide_tr == tls.key_red and crd.red == false then
        crd.red = true
        mset(flr((pl.x+2)/8)+(mpr.lvl*16),flr((pl.y+4)/8),tls.blank)
        sfx(snd.pickupkey)
    elseif collide_tr == tls.key_green and crd.green == false then
        crd.green = true
        mset(flr((pl.x+2)/8)+(mpr.lvl*16),flr((pl.y+4)/8),tls.blank)
        sfx(snd.pickupkey)
    elseif collide_tr == tls.key_blue and crd.blue == false then
        crd.blue = true
        mset(flr((pl.x+2)/8)+(mpr.lvl*16),flr((pl.y+4)/8),tls.blank)
        sfx(snd.pickupkey)
    elseif collide_tr == tls.key_yellow and crd.yellow == false then
        crd.yellow = true
        mset(flr((pl.x+2)/8)+(mpr.lvl*16),flr((pl.y+4)/8),tls.blank)
        sfx(snd.pickupkey)
    end

    if collide_br == tls.key_red and crd.red == false then
        crd.red = true
        mset(flr((pl.x+5)/8)+(mpr.lvl*16),flr((pl.y+7)/8),tls.blank)
        sfx(snd.pickupkey)
    elseif collide_br == tls.key_green and crd.green == false then
        crd.green = true
        mset(flr((pl.x+5)/8)+(mpr.lvl*16),flr((pl.y+7)/8),tls.blank)
        sfx(snd.pickupkey)
    elseif collide_br == tls.key_blue and crd.blue == false then
        crd.blue = true
        mset(flr((pl.x+5)/8)+(mpr.lvl*16),flr((pl.y+7)/8),tls.blank)
        sfx(snd.pickupkey)
    elseif collide_br == tls.key_yellow and crd.yellow == false then
        crd.yellow = true
        mset(flr((pl.x+5)/8)+(mpr.lvl*16),flr((pl.y+7)/8),tls.blank)
        sfx(snd.pickupkey)
    end

    collide_tr=mget(flr((pl.x-1)/8)+(mpr.lvl*16),flr((pl.y+4)/8))
    collide_br=mget(flr((pl.x+8)/8)+(mpr.lvl*16),flr((pl.y+7)/8))

  if collide_tr == tls.door_yellow and crd.yellow == true then
    crd.yellow=false
    sfx(snd.opendoor)
    mset(flr((pl.x-1)/8)+(mpr.lvl*16),flr((pl.y+4)/8),tls.blank)
  elseif collide_tr == tls.door_blue and crd.blue == true then
    crd.blue=false
    sfx(snd.opendoor)
    mset(flr((pl.x-1)/8)+(mpr.lvl*16),flr((pl.y+4)/8),tls.blank)
  elseif collide_tr == tls.door_green and crd.green == true then
    crd.green=false
    sfx(snd.opendoor)
    mset(flr((pl.x-1)/8)+(mpr.lvl*16),flr((pl.y+4)/8),tls.blank)
  elseif collide_tr == tls.door_red and crd.red == true then
    crd.red=false
    sfx(snd.opendoor)
    mset(flr((pl.x-1)/8)+(mpr.lvl*16),flr((pl.y+4)/8),tls.blank)
  end

  if collide_br == tls.door_blue and crd.blue == true then
    crd.blue=false
    sfx(snd.opendoor)
    mset(flr((pl.x+8)/8)+(mpr.lvl*16),flr((pl.y+7)/8),tls.blank)
  elseif collide_br == tls.door_red and crd.red == true then
    crd.red=false
    sfx(snd.opendoor)
    mset(flr((pl.x+8)/8)+(mpr.lvl*16),flr((pl.y+7)/8),tls.blank)
  elseif collide_br == tls.door_yellow and crd.yellow == true then
    crd.yellow=false
    sfx(snd.opendoor)
    mset(flr((pl.x+8)/8)+(mpr.lvl*16),flr((pl.y+7)/8),tls.blank)
  elseif collide_br == tls.door_green and crd.green == true then
    crd.green=false
    sfx(snd.opendoor)
    mset(flr((pl.x+8)/8)+(mpr.lvl*16),flr((pl.y+7)/8),tls.blank)
  end
end

-- ceiling collision handling
function fnccollceiling()
 collide=mget((pl.x+4)/8+(mpr.lvl*16),(pl.y)/8)
 if pl.sy<=0 then
   if fget(collide,0) then
     pl.y = flr((pl.y+8)/8)*8
     pl.sy = 0
   end
 end
end


-->8
-- main routines
-- initialize
function _init()
    infinitemode=true
    glb_coll_stair_tl=false
    glb_coll_stair_br=false
    glb_blt={}
    bulletcount=0
    glb_bltpeed=2
    glb_printcount=0

 -- 0=menu, 1=game, 2=next map
    bool_gamemode=0

 -- store map in array
    glb_map_store={}
    map_memorize()

    fncsetupgam()
    fncmainmnu()
end


-- main loop
function _update60()
    if btnp(5,1) then
        load_level(6)
    end
    if pl.sy < 0 and
        not btn(4) then
        pl.sy+=.8
    end

    if bool_gamemode == 1 then
        if pl.alive then
            input_routine()
        end

    elseif bool_gamemode == 2 then
     -- nextlevel routine??
    end
end


-->8
-- procedural levelgeneration

__gfx__
000000000028e0000028e0000028e0000028e0000000000000000000000000000000000000000000000800008888888877777777aaaaaaaa9999999900000000
00000000002888e0002888e0002888e0002888e00028e0000028e0000028e0000000000000000000080000808999999878888887a777777a9aaaaaa900000000
0070070000f1f10000f5f50000f5f50000f5f500002888e0002888e0002888e000000000008008000000000089aaaa9878999987a788887a9a7777a900000000
0007700000ffff0000ffff0000ffff0000ffff0000f5f50000f5f50000f5f50000000000000808008000000889a77a98789aa987a789987a9a7887a900000000
0007700000288e000f288e0000288e0000288e0000ffff0000ffff0000ffff0000088000008880800000000089a77a98789aa987a789987a9a7887a900000000
0070070000f88e0000288ef000f88e00002f8e000028fe00002f8e0000f88e0000888800088888088000000089aaaa9878999987a788887a9a7777a900000000
0000000000288e0009288e9000288e0000288e0000288e0000288e0000288e000088880080000800000000088999999878888887a777777a9aaaaaa900000000
00000000009009000000000009000090009009000009900000900900090000900008800000000080000000008888888877777777aaaaaaaa9999999900000000
25dd7767000000000000000000000000000000000000000000000000000000000007770000070070077000000700000000000000000000000000000000000000
02555670000000000000000000000000000000000088880000888800008888000007770000700700000000770000000700000000000000000000000000000000
0000000000888800008888000088880000888800088a8a80088a8a80088a8a800007770000070070077000000700000000000000000000000000000000000000
00000000088a8a80088a8a80088a8a80088a8a800888888008888880088888800007770000700700000000770000000700000000000000000000000000000000
00000000088888800888888008888880088888800888888008888880088888800007770000070070077000000700000000000000000000000000000000000000
00000000088222809882228908822280088222800882228008822280088222800007770000700700000000770000000700000000000000000000000000000000
00000000088888809888888998888889088888800888888008888880988888890007770000070070077000000700000000000000000000000000000000000000
00000000099000990000000009000090099009900090090009900990090000900007770000700700000000770000000700000000000000000000000000000000
00000000000000000000000000000000000000000028880000288800002888000028880000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000028880000288800002888000028880000000000000000000000000000000000000000000000000000000000
00000000000000002080899000000000000000000044440000444400004444000044440000000000000000000000000000000000000000000000000000000000
00000000020809900909aa79020809900000000000f44f0000f44f0000f44f0000f44f0000000000000000000000000000000000000000000000000000000000
000000009090aa79208089909090aa792080899000288ef000288e000f288e0000288e0000000000000000000000000000000000000000000000000000000000
000000000208099000000000020809900909aa7900288e000f288ef000288e000f288ef000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000208089900f288e0000288e0000288ef000288e0000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000090000000900900000009000090090000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000055666c675111111d000000000000000000000000000000000000000000000000aaaaaaaa7aaaaaaaaaaaaaa90000000000000000
0770000000000055000000000555555041111d5d00000000000000000000000000000000077000000000000099999999a9999999999999940000000000000000
070707070000550000000000000000004d52152d00000000000000000000000000000000070700700000000099999999a9999999999999940088800000000000
077007070000000000000000000000005522111400000000000000000000000000000000077007070000000099999999a999999999999994089a980000000000
0707070700000000000000000000000051111d54000000000023b7000089a7000028e70007070777002dc70099999999a99999999999999408a7a80000000000
077000770055000000000000000000005d52152d00000000023bb770089aa770028ee7700770070702dcc77099999999a999999999999994089a980000000000
000000005500000000000000000000005522111d000000000023bb000089aa000028ee0000000000002dcc0099999999a9999999999999940088800000000000
0000000000000000000000000000000015554451000000000002b0000008a0000002e000000000000002c0004444444494444444444444420000000000000000
000000000000000000000000000000005d52111d0000000099999998dddd44d51d44ddd1000000000000000000058d000005bd000005cd0000059d0000000000
0008800000033000000cc0000009900051111d5d00000000888888855555555d5555555d000000550070705500058d000005bd000005cd0000059d0000000000
00008000000030000000c000000090005d52152400000000588555555d52555d5d52555d004444000700770000058d000005bd000005cd0000059d0000000000
0008800000033000000cc000000990005522111400dd6000185211115522111d4522111d045445400070700000058d000005bd000005cd0000059d0000000000
00008000000030000000c0000000900041111d5d0dddd6001111188551111d5d51111d54045445400700070000058d000005bd000005cd0000059d0000000000
00288e0000233b0000dcc60000499a004d52152d00d00600188518525d52152d5d521524045445400055000000058d000005bd000005cd0000059d0000000000
002888000023330000dccc00004999005522111d0dddd600185211115522111d5522111d545445405500000000058d000005bd000005cd0000059d0000000000
0002800000023000000dc000000490005111111d000dd000111111115111111d15555451000000000000000000058d000005bd000005cd0000059d0000000000
ddd44dd5000000000000000000000000000000001111111d5111111104444500bbbbbbb3111111111111111d51111111ddd44dd5d44dddd50000000000000000
5555555500000000000110001101110100011000111d521d5111112100500500333333355211111d111d521d515111115555555d555555550000000000000000
5d525555000000000001101011011101000110101115221d51d521110044440053355555221111151115221d411112115d52555d5d5255550000000000000000
152211110000000000000000000000000000000011111114415221110050050013521111111111111111111d411111111522111d552211110000000000000000
11111d520000000001101110111011100110111011111514411111110054444011111335d521d5211d52151451d521511111151d51111d510000000000000000
1d521522000000000110111011101110011011101111121d51d5151100500500133513525221522115221214515221211d5212111d5215210000000000000000
15221111000000000000000000000000000000001111111d515211110044440013521111111111111111111d511111111522111d552211110000000000000000
11111111000000000000010000000000010000001111111d51111111005005001111111155445555555445555555445511111511111111110000000000000000
000000000000000000000000d4dd44d5111111111111111100000000111111110000000000000000000000000000000000000000000000000000000000000000
00027000000000000000000055555555d551d5511111111100000300111111110000000000000000000000000000000000000000000000000000000000000000
0025dd0000000000000000005d525555555155511111111100030300111111110000000000000000000000000000000000000000000000000000000000000000
0026ddd0000000000000000015221111111111111111111100030330111111110000000000000000000000000000000000000000000000000000000000000000
0256dddd000000000000000011111d52111d5511111d551100030030111111110000000000000000000000000000000000000000000000000000000000000000
0256dddd00000300030000001d521522111555111115551103030330111111110000000000000000000000000000000000000000000000000000000000000000
02556ddd000033000330030015221111111111111111111103030300111111110000000000000000000000000000000000000000000000000000000000000000
022555d0003030000030300011111111111111111111111100330300111111110000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000088888888808888880000000000000000000000000000000000000000000000000888000000000000000000000000000000000000000000000
0000000000000008aaaa8aa888aaaa888888008888888888888888880088888000000000888880008a8000000000000000000000000000000000000000000000
00000000000000088aaa8aaa888aa88aaaa8808aaa88aaaaa88aaaa8808aaa80008888888aaa88008a8000000000000000000000000000000000000000000000
00000000000000008aaa8aa8808aa88aaaaa808aaa88aaaaaa8aaaaa808aaa80008aaaa88aaaa8808a8000000000000000000000000000000000000000000000
00000000000000008aaa8aa8008aa88aaaaa888aaa88aa88aa8aaaaa888aaa80088aaaa88aaaaa808a8000000000000000000000000000000000000000000000
00000000000000008aaa8aa8008aa88aaaaa88aaaa88aa88aa8aaaaa88aaaa8008aa8aa88aaaaa888a8000000000000000000000000000000000000000000000
00000000000000008aaa8aa8008aa88aa8aaa8aaaa88aa88aa8aa8aaa8aaaa8008aa8aa88aaaaaa88a8000000000000000000000000000000000000000000000
00000000000000008aaa8aa8008aa88aa8aaaaa8aa88aa88aa8aa8aaaaa8aa8088aaaaa888a8aaaaaa8000000000000000000000000000000000000000000000
00000000000000008aaa8aa8008aa88aa8aaaaa8aa88aaaaa88aa8aaaaa8aa808aaaaaa808a88aaaaa8000000000000000000000000000000000000000000000
00000000000000008aaa8aa8008aa88aa88aaaa8aa88aaa8888aa88aaaa8aa808aaaaaa888a88aaaaa8000000000000000000000000000000000000000000000
00000000000088888aaa8aa8088aa88aa88aaa88aa88aa88008aa88aaa88aa808aaaaaaa8aa888aaaa8000000000000000000000000000000000000000000000
0000000000008aa88aa888a888aa888aa88aaa88aa88aa80008aa88aaa88aa808aa88aaa8aa808aaaa8000000000000000000000000000000000000000000000
00000000000088a88aa8088aaaa8808aa8888888aa88aa88008aa8888888aa888aa888aa8aa8088aaa8800000000000000000000000000000000000000000080
00000000000008aaaaa800888888008aa8000008aa88aaa8008aa8000008aa88aa8808aa8aa8008aaaa800000000000000000000000000000000000000000091
00000000000008aaa88800000000008aa8000008aa88aaa8008aa8000008aa88aa8008aa8aa80088aaa8000000000000000000000000000000000000000000a2
0000000000000888880000000000008888000008888888880088880000088888888008888aa800088888000000000000000000000000000000000000000000b3
000000000000000000000000000000000000000000000000000000000000000000000000888800000000000000000000000000000000000000000000000000c4
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d5
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e6
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f7
__label__
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111118888888881888888111111111111111111111111111111111111111111111111188811111111111111111111111111111
11111111111111111111111111111118aaaa8aa888aaaa888888118888888888888888881188888111111111888881118a811111111111111111111111111111
111111111111111111111111111111188aaa8aaa888aa88aaaa8818aaa88aaaaa88aaaa8818aaa81118888888aaa88118a811111111111111111111111111111
111111111111111111111111111111118aaa8aa8818aa88aaaaa818aaa88aaaaaa8aaaaa818aaa81118aaaa88aaaa8818a811111111111111111111111111111
111111111111111111111111111111118aaa8aa8118aa88aaaaa888aaa88aa88aa8aaaaa888aaa81188aaaa88aaaaa818a811111111111111111111111111111
111111111111111111111111111111118aaa8aa8118aa88aaaaa88aaaa88aa88aa8aaaaa88aaaa8118aa8aa88aaaaa888a811111111111111111111111111111
111111111111111111111111111111118aaa8aa8118aa88aa8aaa8aaaa88aa88aa8aa8aaa8aaaa8118aa8aa88aaaaaa88a811111111111111111111111111111
111111111111111111111111111111118aaa8aa8118aa88aa8aaaaa8aa88aa88aa8aa8aaaaa8aa8188aaaaa888a8aaaaaa811111111111111111111111111111
111111111111111111111111111111118aaa8aa8118aa88aa8aaaaa8aa88aaaaa88aa8aaaaa8aa818aaaaaa818a88aaaaa811111111111111111111111111111
111111111111111111111111111111118aaa8aa8118aa88aa88aaaa8aa88aaa8888aa88aaaa8aa818aaaaaa888a88aaaaa811111111111111111111111111111
111111111111111111111111111188888aaa8aa8188aa88aa88aaa88aa88aa88118aa88aaa88aa818aaaaaaa8aa888aaaa811111111111111111111111111111
11111111111111111111111111118aa88aa888a888aa888aa88aaa88aa88aa81118aa88aaa88aa818aa88aaa8aa818aaaa811111111111111111111111111111
111111111111111111111111111188a88aa8188aaaa8818aa8888888aa88aa88118aa8888888aa888aa888aa8aa8188aaa881111111111111111111111111111
111111111111111111111111111118aaaaa811888888118aa8111118aa88aaa8118aa8111118aa88aa8818aa8aa8118aaaa81111111111111111111111111111
111111111111111111111111111118aaa88811111111118aa8111118aa88aaa8118aa8111118aa88aa8118aa8aa81188aaa81111111111111111111111111111
11111111111111111111111111111888881111111111118888111118888888881188881111188888888118888aa8111888881111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111118888111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111117751775775177757751177511111111177577757575111177757751775111117775757517757775177511117775757511111111111111
11111111111111111175557575757557557575755511111111755575557575111175757575757511117775757575555755755511117575757511111111111111
11111111111111111175117575757517517575751111111111751177515755111177757575757511117575757577751751751111117755777511111111111111
11111111111111111175117575757517517575757517511111757575517575111175757575757511117575757555751751751111117575557511111111111111
11111111111111111157757755777577757575777575511111777575117575111175757575777511117575577577557775577511117775777511111111111111
11111111111111111115555551555555555555555555111111555555115555111155555555555511115555155555515555155511115555555511111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111177757775777577757751111117751775757575757775777517757575777577751111111111111111111111111111111
11111111111111111111111111111111175757575575575557575111175557555757575757775757575557575755575751111111111111111111111111111111
11111111111111111111111111111111177757755175177517575111177757511777575757575777575117775775177551111111111111111111111111111111
11111111111111111111111111111111175757575175175517575111155757511757575757575757575117575755175751111111111111111111111111111111
11111111111111111111111111111111175757575775177757575111177555775757557757575757557757575777575751111111111111111111111111111111
11111111111111111111111111111111155555555555155555555111155511555555515555555555515555555555555551111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111177777511111111111117511777577757775111111111111111111777775111111111111175757775111111111111111111111111111
11111111111111111111777557751111777511117511755575555755111111111111111117775777511117775111175757575111111111111111111111111111
11111111111111111111775517751111555511117511775177511751111111111111111117755577511115555111175757775111111111111111111111111111
11111111111111111111777517751111777511117511755175511751111111111111111117751177511117775111175757555111111111111111111111111111
11111111111111111111577777551111555511117775777575111751111111111111111115777775511115555111157757511111111111111111111111111111
11111111111111111111155555511111111111115555555555111551111111111111111111555555111111111111115555511111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111177777511111111111117775777517757575777511111111111111777775111111111111177511775757577511111111111111111111
11111111111111111111775577751111777511117575575575557575575511111111111117755577511117775111175757575757575751111111111111111111
11111111111111111111775157751111555511117755175175117775175111111111111117751177511115555111175757575757575751111111111111111111
11111111111111111111775177751111777511117575175175757575175111111111111117775777511117775111175757575777575751111111111111111111
11111111111111111111577777551111555511117575777577757575175111111111111115777775511115555111177757755777575751111111111111111111
11111111111111111111155555511111111111115555555555555555155111111111111111555555111111111111155555551555555551111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111177751111111111117775757577757775111111111111111111111757511111111111117757575177517757775111111111111111
11111111111111111111111155751111777511115755757577757575111111111111111111111757511117775111175557575757575755755111111111111111
11111111111111111111111117551111555511111751757575757775111111111111111111111575511115555111177757775757575751751111111111111111
11111111111111111111111175511111777511111751757575757555111111111111111111111757511117775111155757575757575751751111111111111111
11111111111111111111111177751111555511117751577575757511111111111111111111111757511115555111177557575775577551751111111111111111
11111111111111111111111155551111111111115551155555555511111111111111111111111555511111111111155515555555155511551111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111177751111111111117775777577517575111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111175751111777511117775755575757575111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111177751111555511117575775175757575111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111175551111777511117575755175757575111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111175111111555511117575777575755775111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111155111111111111115555555555551555111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111aaa5aaa5aaa51aa51aa51111a5a5aaa5111111a511111aaaaa511111aaa51aa511111aa5aaa5aaa5aaa5aaa511111111111111111111
11111111111111111111a5a5a5a5a555a555a5551111a5a5a5a511111a551111aaa5aaa511115a55a5a51111a5555a55a5a5a5a55a5511111111111111111111
11111111111111111111aaa5aa55aa51aaa5aaa51111a5a5aaa511111a511111aa555aa511111a51a5a51111aaa51a51aaa5aa551a5111111111111111111111
11111111111111111111a555a5a5a55155a555a51111a5a5a55511111a511111aa511aa511111a51a5a5111155a51a51a5a5a5a51a5111111111111111111111
11111111111111111111a511a5a5aaa5aa55aa5511115aa5a5111111a55111115aaaaa5511111a51aa551111aa551a51a5a5a5a51a5111111111111111111111
11111111111111111111551155555555555155511111155555111111551111111555555111111551555111115551155155555555155111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111757575757575111175757775777577517775177517757751111177517775777511111751177517511111777577757751777511111111111111
11111111111111757575757575111175757575757575757775757575757575111175757555575511117551755515751111557575755751757511111111111111
11111111111111757575757575111177757775775575757575757575757575111175757751175111117511751111751111777575751751777511111111111111
11111111111111777577757775111175757575757575757575757575757575111175757551175111117511751111751111755575751751757511111111111111
11111111111111777577757775175175757575757577757575775577557575175175757775175111115751577517551111777577757775777511111111111111
11111111111111555555555555155155555555555555555555555155515555155155555555155111111551155515511111555555555555555511111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

__gff__
0000000000000000000000000000000008000000000000000101010100000000000000000000000000000000000000000000000000000000000000000000000001000008010002020200020101011000000000000100010101000001010101000100000000010104010101010101000001000001010100010000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4c4b4b4b4b4b4b4b4b4b4b4b4b4b4b4d4c4b4b4b4b4b4b4b4b4b4b4b4b4b4b4d4c4b4b4b4b4b4b4b4b4b4b4b4b4b4b4d4c4b4b4b4b4b4b4b4b4b4b4b4b4b4b4d4c4b4b4b4b4b4b4b4b4b4b4b4b4b4b4d4c4b4b4b4b4b4b4b4b4b4b4b4b4b4b4d4c4b4b4b4b4b4b4b4b4b4b4b4b4b4b4d00000000000000000000000000000000
65624461616161616161616161616166655a6161616161616154636261616166636c52616161617563636261616d6964656969696275626169696a616161616665636261746161626161616161615966655a4a66657461616161616164636166657551624a4a494a4a6166616161616600000000000000000000000000000000
65595c4a61494761714a496146616166746c616161616161614461616161616664696c4a616161616161614a6d6a7566656161616b697565616161616161616665746161616161616161614a494a6d62636c676665614a497161616161616166656158436d6060606c6166616161616600000000000000000000000000000000
6460606067606060606060606c67616665744a61616161614a5e4a714a494a666559666c616161616161436d6a7561666561494a61536663606c616161616166656161614a6161496161616d606062746564676b6a676d606c49724a70616166654a61616b6469696a6166616161616600000000000000000000000000000000
6561616167616161616161746167616665615843616161436d606060606060646561446175614a494a616161616161666567606060606664696a626461616166656158675861616d6c616161616161666549674a4a676161666068686c614a66646c61616154615d5e6466616161616600000000000000000000000000000000
6561614767614a61764861614667646665616161616161616174616161616166654a5c4a61756d736c61614a714a49666567616162616665505e4a49616161666561616761616161616161616161616664606060606868676663646161616d64656161586154756d606062616161616600000000000000000000000000000000
6561676d606060606060606060606064656461616263616161614a494a614a666460736c616161746161616d68686074656763724a6166636068606c436164666561616761616161616161614a61616665746161616161676665616161617466656152616154615c5b6161616161616600000000000000000000000000000000
65616761614961616161616161616166656153616161616161616d6060606064626969696c61616161616d6969696964656868686c676b696969616561617466656161676161614a4a61616d6c616166654a61616161496766656149724a616665615843616b6060606161616161616600000000000000000000000000000000
6561674a6d6060606c4a61614761616662606c6161614a4a61616161616461666561616174614a614a617561616161666561616165676161617566654a61616665614a676161616d6c61616174616166646c4a61616d68604165616d686c43666561616161616161616161616161616600000000000000000000000000000000
6460606763746161626060606c67616665617461616d60606c4361616261616665494a616161575a574361614a614a66654a61616567616174616b62606c676665616d6c614a616161614a616161616663696c4a616b6969696a6161617461666561616161616161616161616161616600000000000000000000000000000000
656161677461616161616161616761666561616161616161616161616161616664606c7561616b606a6161616d736074646c436161606c6161616166696a67666561616161576161616157614a7161666559696c4a76556149616161616161666561615861616161616161616161616600000000000000000000000000000000
6561616761614861614a61494867646665616161616161616161494a614a6466657461614a61617461614a61546174666561616261616161494a6174714a67666561616161654a615a4a66616d6c61666561616b6068686068434a4a4a4a61666561536161616161616161616161616600000000000000000000000000000000
6561676d6060606060606060606060646561616161616161676d5656605660626561616d6c61616161616d696a61616665616161616263636868676868686064654a6161616460606060616161614a66654a61616161616161616d60606c61666561584361616161616161616161616600000000000000000000000000000000
65616761616161616161617461616166656161616161616167746161616161666561616174616161616162615d616166656164616161616161616761616b6962626c6161616263746174616161616d62636c61616161616161616161616161666561616160606160606061616161616600000000000000000000000000000000
6572674761614a62634651614a5a616665644a494a6161616776624972615966654a576449614a724a71496157514a66655a614a61617261614a6761645b596665616149614a617271614a644961616665614a4a494a4a574a494a614a614a6665616161615a6161616161616161616600000000000000000000000000000000
7460606060606060606060606060607462606060606060606060606060606074626874606873606868686073646868626160606060686868606060606060606162606060606060606060606060606062646060606060607460606060606060646460606068686060606060606060606200000000000000000000000000000000
__sfx__
000100000762008640026100060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
0001000012100141101613017140181401b1501d15020150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300003052002100355403553035520355103551000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000029b5027b5027b5028b5025b5025b5024b5022b5021b5020b501fd501bb5019d5017b5016d5015b5016d5015d5010b5010d500ed500cd500ab500bd5008d5008d500000006b500000005b500000001b50
00020000042500425004250052500525005260052600526005260062600626007260072600727008270082700827009270092700a2700a2700b2700c27003200012000e2000f2000f20010200102001120011200
0010002018050000001805000000000001b05000000180501b050000001b05000000000001a050000001b0501d050000002005000000000001f05000000200501f050000001d050000001b050000001a05000000
001000201f05000000000001f05000000000001f0500000024050000000000024050000000000024050220502005000000000001d05000000000001a05000000230501f050200501d0501f0501a0501f05000000
001000000c0550c1550c2560c0550c1550c2550c0560c1550f2550f0550f1560f2550f0550f1550f2560f0551115511255110561115511255110551115611255130550e1550e256140551715513255170560e155
001000000c053000000c05301000186530c05300000000000c053000000c0530000018653000000c053000000c053000040c05300000186530c05300000000000c053000000c0530000018653000000c0530c053
0002001221f301ff301cf3017f5012f500df600af7006f7005f7006f7008f600bf600df5012f4018f401df4020f4022f4021d5016d501ad501dd501ed5020d502685026850268502585025850248502485023d50
000700000c450000000c4500000010450000001345000000184501845018450184501845000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200003f6402e6401c64017640126400d6300b63009630076300562003620026200161001610000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200003d6703967036670326702e6702a6702766026660226601f6601d6501c6401b640196401864016630156301363012630116301163011620116201162011620106101061010610106100f6100f6100f600
000100002d260074502b2400b430292300f430272301345025260174602427019470212701f4702027020250202402a43031420394100120002200012000d2000b20009200072000620005200032000120018200
000200003e6700e3703c6700e3703a6700d360396600d360376500c350366500b350346500a350326500935031650093402f640073402e640073302c630073302a630063302a630053202a620053102961028600
000300000127011240022003f60002600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002f0302b030280302403023030260502f050153000b200142001c20024200342002230025300273002a3002e3002f30000000000000000000000000000000000000000000000000000000000000000000
000100003c0502d0501d050120500e100220002515025140251302513025130261202711028110250002500025000250000500004000040000400004000040000400001000020000400001000140001500015000
000100001d4511945117451154511345112451104510f4510d4510c4570b4570b4570b4570b4570c4570d4570d4570e4570e4570e4570f457104571025711257102570e2570b2570725703254012500000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000c050000000000013050000001505013050000000c0500000000000130500000015050130500000011050000000000018050000001a050180500000011050000000000018050000001a0501c05000000
001000001c144000051c14200004181421f14521141211441f142000051c142000041a1451c1421f1441f1421d145000021c1441d145000021c14418142000051a14418142000051c1421d1441f1422114500002
001000001305000000000001a05000000130501a050000001305000000000001a05000000130501a0500000011050000000000018050000001105018050000001105000000000001805000000110501805000000
0010000023142001051f14400102211451f144001022114523144001021f1452114423142001041f14500102211441f1451d142001051c1441d1441f1451d1421c1441814515142111441314515142181441a145
001000001105000000000001805000000150501105000000110500000000000150500000013050110500000010050000000000017050000001005017050000001005000000000001305000000150501305000000
001000000c53518535005050c53518535005050c535004050c53518535005050c53518535005050c53500505115351d53500505115351d535005051153500505115351d53500505115351d535005051153500505
00100000135351f53500505135351f535005051353500505135351f53500505135351f535005051353500505115351d53500505115351d535005051153500505115351d53500505115351d535005051153500505
00100000181421a145001041d1421f144001051d1421f14121144001021f14521144001051f1441d145001041c142001051f1442114123145001042114500105231441f14500102211441d145001021c14400105
00100000115351d53500505115351d535005051153500505115351d53500505115351d535005051153500505105351c53500505105351c535005051053500505105351c53500505105351c535005051053500505
001000001f14200105211441f14500102211441f1451c1411a144001051c1421d144001051c144181421a14518144001021d1451f14400102211451d144001021f14521144001021f1451d141001051c1421f144
00100000186350000000000186350000018635000001863518635000000000018635000001863500000186351863500000000001863500000186350000018635186350000500000186251865518625000001d635
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d00000000000000000000000018050180501a0501a050000000000018050180501b0521b0521b0521b0521b0521b0521b0521b052190511805117051160511505114051000000000000000000000000000000
000d00000000000000000000000013050130501305013050000000000013050130501605216052160521605216052160521605216052150511405113051120511105110051000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000183551c3551c035183551735515355003051735513355003051335500305153551335500305173551835518355003051835517355133550030515355133551335500305173551a3551f355003051a355
001000000c51610526135460c52610516135260c54610526175160e52613546175260e51613526175460e52610516135260c54610526135160c5261054613526175160e52613546175260e51613526175460e526
00100000000500c050000500c050000500c050000500c0500705013050070501305007050130500705013050000500c050000500c050000500c050000500c0500705013050070501305007050130500705013050
001000000c0730000000000000000c0730000000000000000c0730000000000000000c0730000000000000000c0730000000000000000c0730000000000000000c0730000000000000000c073000000000000000
__music__
00 05064344
00 05064047
00 05060748
00 05060744
00 05060708
00 05060708
00 05060708
02 05060708
03 09424344
00 0a4b4344
01 14424344
00 14424344
01 1415195e
00 141d195e
00 16171a5e
02 181b1c5e
00 41424344
00 41424344
00 41424344
00 41424344
01 28294344
00 41424344
03 2d2e2f30

