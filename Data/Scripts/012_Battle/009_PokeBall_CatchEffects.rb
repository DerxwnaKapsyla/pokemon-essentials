$BallTypes = {
  0  => :POKEBALL,
  1  => :GREATBALL,
  2  => :SAFARIBALL,
  3  => :ULTRABALL,
  4  => :MASTERBALL,
  5  => :NETBALL,
  6  => :DIVEBALL,
  7  => :NESTBALL,
  8  => :REPEATBALL,
  9  => :TIMERBALL,
  10 => :LUXURYBALL,
  11 => :PREMIERBALL,
  12 => :DUSKBALL,
  13 => :HEALBALL,
  14 => :QUICKBALL,
  15 => :CHERISHBALL,
  16 => :FASTBALL,
  17 => :LEVELBALL,
  18 => :LUREBALL,
  19 => :HEAVYBALL,
  20 => :LOVEBALL,
  21 => :FRIENDBALL,
  22 => :MOONBALL,
  23 => :SPORTBALL,
  24 => :DREAMBALL,
  25 => :BEASTBALL,
  # ------ Derx: Added in the core Puppet Orbs
  26=>:CHERISHORB,
  27=>:PUPPETORB,
  28=>:GREATORB,
  29=>:ULTRAORB,
  30=>:MASTERORB,
  31=>:PUPPETORB2, # Derx: The Festival of Chaos addition
  32=>:GREATORB2,  # Derx: The Festival of Chaos addition
  33=>:INVERSEORB,  # Derx: The Festival of Chaos addition
  34=>:EMPTY # Derx: Festival of Curses addition
  # ------ Derx: End of Puppet Orb additions
}

def pbBallTypeToItem(balltype)
  if $BallTypes[balltype]
    ret = getID(PBItems,$BallTypes[balltype])
    return ret if ret!=0
  end
  if $BallTypes[0]
    ret = getID(PBItems,$BallTypes[0])
    return ret if ret!=0
  end
  return getID(PBItems,:POKEBALL)
end

def pbGetBallType(ball)
  ball = getID(PBItems,ball)
  $BallTypes.keys.each do |key|
    return key if isConst?(ball,PBItems,$BallTypes[key])
  end
  return 0
end



#===============================================================================
#
#===============================================================================
module BallHandlers
  IsUnconditional = ItemHandlerHash.new
  ModifyCatchRate = ItemHandlerHash.new
  OnCatch         = ItemHandlerHash.new
  OnFailCatch     = ItemHandlerHash.new

  def self.isUnconditional?(ball,battle,battler)
    ret = IsUnconditional.trigger(ball,battle,battler)
    return (ret!=nil) ? ret : false
  end

  def self.modifyCatchRate(ball,catchRate,battle,battler,ultraBeast)
    ret = ModifyCatchRate.trigger(ball,catchRate,battle,battler,ultraBeast)
    return (ret!=nil) ? ret : catchRate
  end

  def self.onCatch(ball,battle,pkmn)
    OnCatch.trigger(ball,battle,pkmn)
  end

  def self.onFailCatch(ball,battle,battler)
    OnFailCatch.trigger(ball,battle,battler)
  end
end



#===============================================================================
# IsUnconditional
#===============================================================================
BallHandlers::IsUnconditional.add(:MASTERBALL,proc { |ball,battle,battler|
  next true
})

#===============================================================================
# ModifyCatchRate
# NOTE: This code is not called if the battler is an Ultra Beast (except if the
#       Ball is a Beast Ball). In this case, all Balls' catch rates are set
#       elsewhere to 0.1x.
#===============================================================================
BallHandlers::ModifyCatchRate.add(:GREATBALL,proc { |ball,catchRate,battle,battler,ultraBeast|
  next catchRate*1.5
})

BallHandlers::ModifyCatchRate.add(:ULTRABALL,proc { |ball,catchRate,battle,battler,ultraBeast|
  next catchRate*2
})

BallHandlers::ModifyCatchRate.add(:SAFARIBALL,proc { |ball,catchRate,battle,battler,ultraBeast|
  next catchRate*1.5
})

BallHandlers::ModifyCatchRate.add(:NETBALL,proc { |ball,catchRate,battle,battler,ultraBeast|
  multiplier = (NEWEST_BATTLE_MECHANICS) ? 3.5 : 3
  catchRate *= multiplier if battler.pbHasType?(:BUG) || 
							 battler.pbHasType?(:WATER) || 
							 # Derx: Addition of Touhoumon Water and Beast
							 battler.pbHasType?(:WATER18) || 
							 battler.pbHasType?(:BEAST18) # Derx: This might have been Dream but, fuck it. Beast works better.
							 # Derx: End of type additions
  next catchRate
})

BallHandlers::ModifyCatchRate.add(:DIVEBALL,proc { |ball,catchRate,battle,battler,ultraBeast|
  catchRate *= 3.5 if battle.environment==PBEnvironment::Underwater
  next catchRate
})

BallHandlers::ModifyCatchRate.add(:NESTBALL,proc { |ball,catchRate,battle,battler,ultraBeast|
  if battler.level<=((NEWEST_BATTLE_MECHANICS) ? 29 : 30)
    catchRate *= [(41-battler.level)/10.0,1].max
  end
  next catchRate
})

BallHandlers::ModifyCatchRate.add(:REPEATBALL,proc { |ball,catchRate,battle,battler,ultraBeast|
  multiplier = (NEWEST_BATTLE_MECHANICS) ? 3.5 : 3
  catchRate *= multiplier if battle.pbPlayer.owned[battler.species]
  next catchRate
})

BallHandlers::ModifyCatchRate.add(:TIMERBALL,proc { |ball,catchRate,battle,battler,ultraBeast|
  multiplier = [1+(0.3*battle.turnCount),4].min
  catchRate *= multiplier
  next catchRate
})

BallHandlers::ModifyCatchRate.add(:DUSKBALL,proc { |ball,catchRate,battle,battler,ultraBeast|
  multiplier = (NEWEST_BATTLE_MECHANICS) ? 3 : 3.5
  catchRate *= multiplier if battle.time==2
  next catchRate
})

BallHandlers::ModifyCatchRate.add(:QUICKBALL,proc { |ball,catchRate,battle,battler,ultraBeast|
  multiplier = (NEWEST_BATTLE_MECHANICS) ? 4 : 5
  catchRate *= multiplier if battle.turnCount==0
  next catchRate
})

BallHandlers::ModifyCatchRate.add(:FASTBALL,proc { |ball,catchRate,battle,battler,ultraBeast|
  baseStats = pbGetSpeciesData(battler.species,battler.form,SpeciesBaseStats)
  baseSpeed = baseStats[PBStats::SPEED]
  catchRate *= 4 if baseSpeed>=100
  next [catchRate,255].min
})

BallHandlers::ModifyCatchRate.add(:LEVELBALL,proc { |ball,catchRate,battle,battler,ultraBeast|
  maxlevel = 0
  battle.eachSameSideBattler do |b|
    maxlevel = b.level if b.level>maxlevel
  end
  if maxlevel>=battler.level*4;    catchRate *= 8
  elsif maxlevel>=battler.level*2; catchRate *= 4
  elsif maxlevel>battler.level;    catchRate *= 2
  end
  next [catchRate,255].min
})

BallHandlers::ModifyCatchRate.add(:LUREBALL,proc { |ball,catchRate,battle,battler,ultraBeast|
  multiplier = (NEWEST_BATTLE_MECHANICS) ? 5 : 3
  catchRate *= multiplier if $PokemonTemp.encounterType==EncounterTypes::OldRod ||
                             $PokemonTemp.encounterType==EncounterTypes::GoodRod ||
                             $PokemonTemp.encounterType==EncounterTypes::SuperRod
  next [catchRate,255].min
})

BallHandlers::ModifyCatchRate.add(:HEAVYBALL,proc { |ball,catchRate,battle,battler,ultraBeast|
  next 0 if catchRate==0
  weight = battler.pbWeight
  if NEWEST_BATTLE_MECHANICS
    if weight>=3000;    catchRate += 30
    elsif weight>=2000; catchRate += 20
    elsif weight<1000;  catchRate -= 20
    end
  else
    if weight>=4096;    catchRate += 40
    elsif weight>=3072; catchRate += 30
    elsif weight>=2048; catchRate += 20
    else;               catchRate -= 20
    end
  end
  catchRate = [catchRate,1].max
  next [catchRate,255].min
})

BallHandlers::ModifyCatchRate.add(:LOVEBALL,proc { |ball,catchRate,battle,battler,ultraBeast|
  battle.eachSameSideBattler do |b|
    next if b.species!=battler.species
    next if b.gender==battler.gender || b.gender==2 || battler.gender==2
    catchRate *= 8
    break
  end
  next [catchRate,255].min
})

BallHandlers::ModifyCatchRate.add(:MOONBALL,proc { |ball,catchRate,battle,battler,ultraBeast|
  # NOTE: Moon Ball cares about whether any species in the target's evolutionary
  #       family can evolve with the Moon Stone, not whether the target itself
  #       can immediately evolve with the Moon Stone.
  if hasConst?(PBItems,:MOONSTONE) &&
     pbCheckEvolutionFamilyForItemMethodItem(battler.species,getConst(PBItems,:MOONSTONE))
    catchRate *= 4
  end
  next [catchRate,255].min
})

BallHandlers::ModifyCatchRate.add(:SPORTBALL,proc { |ball,catchRate,battle,battler,ultraBeast|
  next catchRate*1.5
})

BallHandlers::ModifyCatchRate.add(:DREAMBALL,proc { |ball,catchRate,battle,battler,ultraBeast|
  catchRate *= 4 if battler.status==PBStatuses::SLEEP
  next catchRate
})

BallHandlers::ModifyCatchRate.add(:BEASTBALL,proc { |ball,catchRate,battle,battler,ultraBeast|
  if ultraBeast
    catchRate *= 5
  else
    catchRate /= 10
  end
  next catchRate
})

# ------ Derx: Functionality for the Puppet Orbs
BallHandlers::ModifyCatchRate.add(:GREATORB,proc { |ball,catchRate,battle,battler,ultraBeast|
  next catchRate*1.5
})

BallHandlers::ModifyCatchRate.add(:ULTRAORB,proc { |ball,catchRate,battle,battler,ultraBeast|
  next catchRate*2
})

BallHandlers::ModifyCatchRate.add(:SAFARIORB,proc { |ball,catchRate,battle,battler,ultraBeast|
  next catchRate*1.5
})
BallHandlers::IsUnconditional.add(:MASTERORB,proc { |ball,battle,battler|
  next true
})
# ------ Derx: End of functionality for the Puppet Orbs

# ------ Derx: Addition of Seija's Great Orb from The Festival of Curses
BallHandlers::ModifyCatchRate.add(:GREATORB2,proc { |ball,catchRate,battle,battler,ultraBeast|
  next catchRate*1.5
})

BallHandlers::ModifyCatchRate.add(:INVERSEORB,proc { |ball,catchRate,battle,battler,ultraBeast|
  next catchRate*1.5
})
# ------ Derx: End of Seija's Great Orb addition

#===============================================================================
# OnCatch
#===============================================================================
BallHandlers::OnCatch.add(:HEALBALL,proc { |ball,battle,pkmn|
  pkmn.heal
})

BallHandlers::OnCatch.add(:FRIENDBALL,proc { |ball,battle,pkmn|
  pkmn.happiness = 200
})

# ------ Derx: Addition of The Festival of Curses' Unique Pokeballs
BallHandlers::OnCatch.add(:PUPPETORB2,proc { |ball,battle,pkmn|
  pkmn.happiness = 0
})

BallHandlers::OnCatch.add(:GREATORB2,proc { |ball,battle,pkmn|
  iv1 = iv2 = rand(6)
  iv2 = rand(6) while iv2 == iv1
  pkmn.iv[iv1] = 0
  pkmn.iv[iv2] = 31
})

BallHandlers::OnCatch.add(:INVERSEORB,proc { |ball,battle,pkmn|
  if rand(100) > 85
	pkmn.makeShiny
  end
})