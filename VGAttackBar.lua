VGAB_extraAttacks	= 0;
VGAB_MH_start		= 0.000;
VGAB_MH_landsAt		= 0.000;
VGAB_OH_start		= 0.000;
VGAB_OH_landsAt		= 0.000;
VGAB_MH_speed		= nil;
VGAB_OH_speed		= nil;
VGAB_enemy_MH_speed	= 0.000
VGAB_enemy_OH_speed	= 0.000
VGAB_Standing		= true;

VGRL_PATTERN_INCOMING_MELEE_PARRY = ".* attacks. You parry.";
VGRL_PATTERN_INCOMING_SPECIALATTACK_PARRY = "(.*)'s (.*) [wai]+s parried.";

-- cast spell by name hook
preVGAB_csbn = CastSpellByName
function VGAB_csbn(pass, onSelf)
	preVGAB_csbn(pass, onSelf)
	VGAB_spelldir(pass)
end
CastSpellByName = VGAB_csbn

--use action hook
preVGAB_useact = UseAction
function VGAB_useact(p1,p2,p3)
	preVGAB_useact(p1,p2,p3)
    local a,b = IsUsableAction(p1)
    if a then
    	if UnitCanAttack("player","target" )then
    		if IsActionInRange(p1) == 1 then
				VGAB_Tooltip:ClearLines()
				VGAB_Tooltip:SetAction(p1)
		    	local spellname = VGAB_TooltipTextLeft1:GetText()
		    	if spellname then VGAB_spelldir(spellname) end
	    	end
    	end
    end
end
UseAction = VGAB_useact

--castspell hook
preVGAB_cassple = CastSpell
function VGAB_casspl(p1,p2)
	preVGAB_cassple(p1,p2)
	local spell = GetSpellName(p1,p2)
	VGAB_spelldir(spell)
end
CastSpell = VGAB_casspl

function VGAB_loaded()
	SlashCmdList["VGAB"] = VGAB_chat;
	SLASH_VGAB1 = "/vgab";
	if (VGAB == nil) then VGAB={} end
	if VGAB.range == nil then
		VGAB.range=true
	end
	if VGAB.playerBars == nil then
		VGAB.playerBars=true
	end
	if VGAB.timer == nil then
		VGAB.timer=true
	end
	VGAB_Mhr:SetPoint("LEFT",VGAB_Frame,"TOPLEFT",6,-13)
	VGAB_MhrText:SetJustifyH("Left")
	VGEnemyAB_VL()
end

function VGAB_chat(msg)
	msg = strlower(msg)
	if msg == "fix" then
		VGAB_reset()
	elseif msg=="lock" then
		VGAB_Frame:Hide()
		VGEnemyAB_Frame:Hide()
	elseif msg=="unlock" then
		VGAB_Frame:Show()
		VGEnemyAB_Frame:Show()
	elseif msg=="range" then
		VGAB.range= not(VGAB.range)
		DEFAULT_CHAT_FRAME:AddMessage('range is'.. VGAB_Boo(VGAB.range));
	elseif msg=="playerBars" then
		VGAB.playerBars = not(VGAB.playerBars)
		DEFAULT_CHAT_FRAME:AddMessage('playerBars is'.. VGAB_Boo(VGAB.playerBars));
	elseif msg=="timer" then
		VGAB.timer = not(VGAB.timer)
		DEFAULT_CHAT_FRAME:AddMessage('timer is'.. VGAB_Boo(VGAB.timer));
	elseif msg=="pvp" then
		VGAB.pvp = not(VGAB.pvp)
		DEFAULT_CHAT_FRAME:AddMessage('pvp is'.. VGAB_Boo(VGAB.pvp));
	elseif msg=="mob" then
		VGAB.mob = not(VGAB.mob)
		DEFAULT_CHAT_FRAME:AddMessage('mobs are'.. VGAB_Boo(VGAB.mob));
	else
		DEFAULT_CHAT_FRAME:AddMessage('use any of these to control VGAB:');
		DEFAULT_CHAT_FRAME:AddMessage('Lock- to lock and hide the anchor');
		DEFAULT_CHAT_FRAME:AddMessage('unlock- to unlock and show the anchor');
		DEFAULT_CHAT_FRAME:AddMessage('fix- to reset the values should they go awry, wait 5 sec after attacking to use this command');
		DEFAULT_CHAT_FRAME:AddMessage('playerBars- to turn on and off the player\'s melee bar(s)');
		DEFAULT_CHAT_FRAME:AddMessage('range- to turn on and off the ranged bar');
		DEFAULT_CHAT_FRAME:AddMessage('pvp- to turn on and off the enemy player bar(s)');
		DEFAULT_CHAT_FRAME:AddMessage('mob- to turn on and off the enemy mob bar(s)');
	end
end

function VGAB_reset()
	onid=0
	offid=0
	VGAB_MH_landsAt = 0.0
	VGAB_OH_landsAt = 0.0
	VGAB_MH_start = 0.0
	VGAB_OH_start = 0.0
	VGAB_extraAttacks = 0
end

function VGAB_event(event)
	if (event == "CHAT_MSG_SPELL_SELF_BUFF" or event == "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS") and VGAB.playerBars == true then
		if ( string.find( arg1, "You gain 1 extra attack" ) ) then
			VGAB_extraAttacks = 1;
		elseif ( string.find( arg1, "Fury of Forgewright" ) ) then
			VGAB_extraAttacks = 2;
		end
		-- In case we GAINED a speed-affecting aura
		if (oldMHSpeed == nil) then return end
		local oldMHSpeed = VGAB_MH_speed
		local oldOHSpeed = VGAB_OH_speed
		VGAB_MH_speed, VGAB_OH_speed = UnitAttackSpeed("player");
		if (oldMHSpeed ~= VGAB_MH_speed) then
			VGAB_currentTime = GetTime();
			local timeLeftMH = (VGAB_MH_landsAt - VGAB_currentTime) / (oldMHSpeed / VGAB_MH_speed)
			VGAB_MH_landsAt = VGAB_currentTime + timeLeftMH;
			VGAB_UpdateMHSwingBar(VGAB_currentTime,"Main-hand",0,0,1);
			if (VGAB_OH_speed ~= nil) then
				local timeLeftOH = (VGAB_OH_landsAt - VGAB_currentTime) / (oldOHSpeed / VGAB_OH_speed)
				VGAB_OH_landsAt = VGAB_currentTime + timeLeftOH;
			end
		end
	elseif (event == "CHAT_MSG_SPELL_AURA_GONE_SELF" or event == "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE") and VGAB.playerBars == true then
		-- In case we lost a speed-affecting aura or gained a speed-affecting debuff
		if (oldMHSpeed == nil) then return end
		local oldMHSpeed = VGAB_MH_speed
		local oldOHSpeed = VGAB_OH_speed
		VGAB_MH_speed, VGAB_OH_speed = UnitAttackSpeed("player");
		if (oldMHSpeed ~= VGAB_MH_speed) then
			VGAB_currentTime = GetTime();
			local timeLeftMH = (VGAB_MH_landsAt - VGAB_currentTime) / (oldMHSpeed / VGAB_MH_speed)
			VGAB_MH_landsAt = VGAB_currentTime + timeLeftMH;
			VGAB_UpdateMHSwingBar(VGAB_currentTime,"Main-hand",0,0,1);
			if (VGAB_OH_speed ~= nil) then
				local timeLeftOH = (VGAB_OH_landsAt - VGAB_currentTime) / (oldOHSpeed / VGAB_OH_speed)
				VGAB_OH_landsAt = VGAB_currentTime + timeLeftOH;
			end
		end
	elseif (event == "CHAT_MSG_COMBAT_SELF_MISSES" or event == "CHAT_MSG_COMBAT_SELF_HITS") and VGAB.playerBars == true then
		VGAB_currentTime = GetTime();
		VGAB_MH_speed, VGAB_OH_speed = UnitAttackSpeed("player");
		if (VGAB_currentTime >= VGAB_MH_landsAt + 0.3) then VGAB_MH_landsAt = 0 end
		if (VGAB_currentTime >= VGAB_OH_landsAt + 0.3) then VGAB_OH_landsAt = 0 end
		if (VGAB_MH_landsAt == 0) then VGAB_MH_landsAt = VGAB_currentTime; end
		if (VGAB_OH_landsAt == 0) then VGAB_OH_landsAt = VGAB_currentTime; end
		if (VGAB_OH_speed == nil) then VGAB_OH_landsAt = VGAB_currentTime + 1000000; end
		if (VGAB_extraAttacks > 0 or VGAB_MH_landsAt <= VGAB_OH_landsAt) then	-- This attack is a main-hand attack
			-- Print("MH "..VGAB_currentTime.." ("..VGAB_MH_landsAt.." | "..VGAB_OH_landsAt..")");
			if (VGAB_extraAttacks > 0) then VGAB_extraAttacks = VGAB_extraAttacks - 1; end
			VGAB_MH_start = VGAB_currentTime;
			VGAB_MH_landsAt = VGAB_MH_start + VGAB_MH_speed;
			if (VGAB_OH_landsAt < VGAB_currentTime + 0.2) then
				VGAB_OH_landsAt = VGAB_currentTime + 0.2;
			end
			VGAB_UpdateMHSwingBar(VGAB_currentTime,"Main-hand",0,0,1)
		else	-- This attack is an off-hand attack
			-- Print("OH "..VGAB_currentTime.." ("..VGAB_MH_landsAt.." | "..VGAB_OH_landsAt..")");
			VGAB_OH_start = VGAB_currentTime;
			VGAB_OH_landsAt = VGAB_OH_start + VGAB_OH_speed;
			if (VGAB_MH_landsAt < VGAB_currentTime + 0.2) then
				VGAB_MH_landsAt = VGAB_currentTime + 0.2;
			end
		end
	elseif (event == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES" or event == "CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE") then
		VGAB_Standing = true;
		if ( string.find( arg1, VGRL_PATTERN_INCOMING_MELEE_PARRY ) or string.find( arg1, VGRL_PATTERN_INCOMING_SPECIALATTACK_PARRY ) ) then	-- Player parried an attack or a special attack
			VGAB_currentTime = GetTime();
			-- VGAB_MH_speed, VGAB_OH_speed = UnitAttackSpeed("player");
			VGAB_MH_swingTimeLeft = VGAB_MH_landsAt - VGAB_currentTime;
			VGAB_OH_swingTimeLeft = VGAB_OH_landsAt - VGAB_currentTime;
			if (VGAB_MH_swingTimeLeft <= VGAB_OH_swingTimeLeft) then
				if (VGAB_MH_swingTimeLeft / (VGAB_MH_landsAt - VGAB_MH_start) > 0.6) then
					VGAB_MH_landsAt = VGAB_MH_landsAt - (VGAB_MH_landsAt - VGAB_MH_start) * 0.4;
				elseif (VGAB_MH_swingTimeLeft / (VGAB_MH_landsAt - VGAB_MH_start) >= 0.2) then
					VGAB_MH_landsAt = (VGAB_MH_landsAt - VGAB_MH_start) * 0.2;
				end
			else
				if (VGAB_OH_swingTimeLeft / (VGAB_OH_landsAt - VGAB_OH_start) > 0.6) then
					VGAB_OH_landsAt = VGAB_OH_landsAt - (VGAB_OH_landsAt - VGAB_OH_start) * 0.4;
				elseif (VGAB_OH_swingTimeLeft / (VGAB_OH_landsAt - VGAB_OH_start) >= 0.2) then
					VGAB_OH_landsAt = (VGAB_OH_landsAt - VGAB_OH_start) * 0.2;
				end
			end
			VGAB_UpdateMHSwingBar(VGAB_currentTime,"Main-hand",0,0,1)
		end
	elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
		VGAB_spellhit(arg1)
	elseif event == "PLAYER_LEAVE_COMBAT" then
		VGAB_reset()
	elseif event == "VARIABLES_LOADED" then
		VGAB_loaded()
	end
end

function VGAB_spellhit(arg1)
	a,b,spell=string.find (arg1, "Your (.+) hits")
	if not spell then 	a,b,spell=string.find (arg1, "Your (.+) crits") end
	if not spell then 	a,b,spell=string.find (arg1, "Your (.+) is") end
	if not spell then	a,b,spell=string.find (arg1, "Your (.+) misses") end
		
	rs,rhd,rld = UnitRangedDamage("player");
	rhd,rld = rhd-math.mod(rhd,1),rld-math.mod(rld,1)
	if spell == "Auto Shot" and VGAB.range == true then
		trs=rs
		rs = rs-math.mod(rs,0.01)
		VGAB_MH_start = GetTime()
		VGAB_MH_landsAt = GetTime() + trs
		VGAB_UpdateMHSwingBar(VGAB_MH_start,"Auto Shot["..rs.."s]("..rhd.."-"..rld..")",0,1,0)
	elseif spell == "Shoot" and VGAB.range==true then
		trs=rs
		rs = rs-math.mod(rs,0.01)
		VGAB_MH_start = GetTime()
		VGAB_MH_landsAt = GetTime() + trs
		VGAB_UpdateMHSwingBar(VGAB_MH_start,"Wand",.7,.1,1)
	elseif (spell == "Raptor Strike" or spell == "Heroic Strike" or	spell == "Maul" or spell == "Cleave" or spell == "Slam") and VGAB.playerBars==true then
		hd,ld,ohd,lhd = UnitDamage("player")
		hd,ld= hd-math.mod(hd,1),ld-math.mod(ld,1)
		VGAB_currentTime = GetTime()
		VGAB_MH_speed, VGAB_OH_speed = UnitAttackSpeed("player");
		if (VGAB_currentTime >= VGAB_MH_landsAt + 0.3) then VGAB_MH_landsAt = 0 end
		if (VGAB_currentTime >= VGAB_OH_landsAt + 0.3) then VGAB_OH_landsAt = 0 end
		if (VGAB_MH_landsAt == 0) then VGAB_MH_landsAt = VGAB_currentTime; end
		if (VGAB_OH_landsAt == 0) then VGAB_OH_landsAt = VGAB_currentTime; end
		if (VGAB_OH_speed == nil) then VGAB_OH_landsAt = VGAB_currentTime + 1000000; end
		VGAB_MH_start = VGAB_currentTime;
		VGAB_MH_landsAt = VGAB_MH_start + VGAB_MH_speed;
		if (VGAB_OH_landsAt < VGAB_currentTime + 0.2) then
			VGAB_OH_landsAt = VGAB_currentTime + 0.2;
		end
		-- Print(VGAB_currentTime.." | "..VGAB_MH_landsAt.." | "..VGAB_OH_landsAt)
		VGAB_UpdateMHSwingBar(VGAB_currentTime,"Main-hand",0,0,1);
	end
end

function VGAB_spelldir(spellname)
	if VGAB.range then
		local a,b,sparse = string.find (spellname, "(.+)%(")
		if sparse then spellname = sparse end
		rs,rhd,rld = UnitRangedDamage("player");
		rhd,rld = rhd-math.mod(rhd,1),rld-math.mod(rld,1);
		if spellname == "Throw" then
			trs=rs
			rs = rs-math.mod(rs,0.01)
			VGAB_MH_start = GetTime() - 1
			VGAB_MH_landsAt = GetTime() + trs
			VGAB_UpdateMHSwingBar(VGAB_MH_start,"Thrown["..(rs).."s]("..rhd.."-"..rld..")",1,.5,0)
		elseif spellname == "Shoot" then
			rs =UnitRangedDamage("player")
			trs=rs
			rs = rs-math.mod(rs,0.01)
			VGAB_MH_start = GetTime() - 1
			VGAB_MH_landsAt = GetTime() + trs
			VGAB_UpdateMHSwingBar(VGAB_MH_start,"Wand["..(rs).."s]("..rhd.."-"..rld..")",.5,0,1)
		elseif spellname == "Shoot Bow" then
			trs = rs
			rs = rs-math.mod(rs,0.01)
			VGAB_MH_start = GetTime() - 1
			VGAB_MH_landsAt = GetTime() + trs
			VGAB_UpdateMHSwingBar(VGAB_MH_start,"Bow["..(rs).."s]("..rhd.."-"..rld..")",1,.5,0)
		elseif spellname == "Shoot Gun" then
			trs = rs
			rs = rs-math.mod(rs,0.01)
			VGAB_MH_start = GetTime() - 1
			VGAB_MH_landsAt = GetTime() + trs
			VGAB_UpdateMHSwingBar(VGAB_MH_start,"Gun["..(rs).."s]("..rhd.."-"..rld..")",1,.5,0)
		elseif spellname == "Shoot Crossbow" then
			trs=rs
			rs = rs-math.mod(rs,0.01)
			VGAB_MH_start = GetTime() - 1
			VGAB_MH_landsAt = GetTime() + trs
			VGAB_UpdateMHSwingBar(VGAB_MH_start,"X-Bow["..(rs).."s]("..rhd.."-"..rld..")",1,.5,0)
		elseif spellname == "Aimed Shot" then
			trs=rs
			rs = rs-math.mod(rs,0.01)
			VGAB_MH_start = GetTime() - 1
			VGAB_MH_landsAt = GetTime() + trs
			VGAB_UpdateMHSwingBar(VGAB_MH_start,"Aiming["..(3).."s]",1,.1,.1) 
		end
	end
end

function VGAB_UpdateBar()
	local ttime = GetTime()
	local left = 0.00
	tSpark=getglobal(this:GetName().. "Spark")
	tText=getglobal(this:GetName().. "Tmr")
	if VGAB.timer==true then
		left = (this.et-GetTime()) - (math.mod((this.et-GetTime()),.01))
		local text = left
		if (this.spd ~= nil) then text = text.." / "..(math.floor(this.spd*100)/100.0) end
		tText:SetText("{"..text.."}")
		tText:Show()
	else
		tText:Hide()
	end
	this:SetValue(ttime)
	tSpark:SetPoint("CENTER", this, "LEFT", (ttime-this.st)/(this.et-this.st)*195, 2);
	if ttime>=this.et then 
		this:Hide() 
		tSpark:SetPoint("CENTER", this, "LEFT",195, 2);
	end
end

function VGAB_UpdateMHSwingBar(currentTime,text,r,g,b)
	VGAB_Mhr:Hide()
	VGAB_Mhr.txt = text
	VGAB_Mhr.st = VGAB_MH_start
	VGAB_Mhr.et = VGAB_MH_landsAt
	VGAB_Mhr:SetStatusBarColor(r,g,b)
	VGAB_MhrText:SetText(text)
	VGAB_Mhr:SetMinMaxValues(VGAB_Mhr.st,VGAB_Mhr.et)
	VGAB_Mhr:SetValue(currentTime)
	VGAB_Mhr:Show()
end

function VGAB_Boo(inpt)
	if inpt == true then return " ON" else return " OFF" end
end

--------------------
-- ENEMY BAR CODE --
--------------------

function VGEnemyAB_VL()
	if not VGAB.pvp then VGAB.pvp = true end
	if not VGAB.mob then VGAB.mob = true end
	VGEnemyAB_mh:SetPoint("LEFT",VGEnemyAB_Frame,"TOPLEFT",6,-13)
	VGEnemyAB_oh:SetPoint("LEFT",VGEnemyAB_Frame,"TOPLEFT",6,-35)
	VGEnemyAB_mhText:SetJustifyH("Left")
	VGEnemyAB_ohText:SetJustifyH("Left")
end

function VGEnemyAB_event(event)
	if event=="VARIABLES_LOADED" then
		VGEnemyAB_VL()
	end
	if (event == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS" or event == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES") and VGAB.mob == true then
		VGAB_Standing = true;
		VGEnemyAB_start(arg1)
	elseif (event=="CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS" or event=="CHAT_MSG_COMBAT_HOSTILEPLAYER_MISSES") and VGAB.pvp then
		VGAB_Standing = true;
		VGEnemyAB_start(arg1)
	elseif (event=="CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_HITS" or event=="CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_MISSES" or event=="CHAT_MSG_COMBAT_CREATURE_VS_PARTY_HITS" or event=="CHAT_MSG_COMBAT_CREATURE_VS_PARTY_MISSES") then
		VGEnemyAB_start(arg1)
	end
end

function VGEnemyAB_start(arg1)
	local a
	local b
	hitter = nil
	a,b, hitter = string.find (arg1, "(.+) hits you")
	if not hitter then a,b, hitter = string.find (arg1, "(.+) crits you") end
	if not hitter then a,b, hitter = string.find (arg1, "(.+) misses you") end
	if not hitter then a,b, hitter = string.find (arg1, "(.+) attacks. You ") end
	if hitter == UnitName("target") then VGEnemyAB_set(hitter) end

	if not hitter then a,b, hitter, targetHit = string.find (arg1, "(.+) hits (.+) for") end
	if not hitter then a,b, hitter, targetHit = string.find (arg1, "(.+) crits (.+) for") end
	if not hitter then a,b, hitter, targetHit = string.find (arg1, "(.+) misses (.+).") end
	if not hitter then a,b, hitter, targetHit = string.find (arg1, "(.+) attacks. (.+) dodges.") end
	if not hitter then a,b, hitter, targetHit = string.find (arg1, "(.+) attacks. (.+) parries.") end
	if not hitter then a,b, hitter, targetHit = string.find (arg1, "(.+) attacks. (.+) blocks.") end
	if not hitter then a,b, hitter, targetHit = string.find (arg1, "(.+) attacks. (.+) absorbs all the damage.") end
	if (hitter == UnitName("target") and targetHit == UnitName("targettarget") and UnitIsPlayer("targettarget")) then VGEnemyAB_set(hitter) end
	if (hitter == UnitName("targettarget") and targetHit == UnitName("target") and UnitIsPlayer("target")) then VGEnemyAB_set(hitter) end
end

function VGEnemyAB_set(targ)
	VGAB_enemy_MH_speed, VGAB_enemy_OH_speed = UnitAttackSpeed("target")
	local ogSpeed = VGAB_enemy_MH_speed
	VGAB_enemy_MH_speed = VGAB_enemy_MH_speed - math.mod(VGAB_enemy_MH_speed,0.01)
	VGEnemyAB_UpdateMHSwingBar(VGAB_enemy_MH_speed,ogSpeed,targ,1,.1,.1)
end

function VGEnemyAB_UpdateMHSwingBar(bartime,ogSpeed,text,r,g,b)
	VGEnemyAB_mh:Hide()
	VGEnemyAB_mh.txt = text
	VGEnemyAB_mh.st = GetTime()
	VGEnemyAB_mh.et = GetTime() + bartime
	VGEnemyAB_mh.spd = ogSpeed
	VGEnemyAB_mh:SetStatusBarColor(r,g,b)
	VGEnemyAB_mhText:SetText(text)
	VGEnemyAB_mh:SetMinMaxValues(VGEnemyAB_mh.st,VGEnemyAB_mh.et)
	VGEnemyAB_mh:SetValue(VGEnemyAB_mh.st)
	VGEnemyAB_mh:Show()
end