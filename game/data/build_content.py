"""Compile authored Belde gameplay data; no prose is parsed by the game at runtime."""
from pathlib import Path
import copy, json
ROOT=Path(__file__).resolve().parents[2]
SRC=ROOT/'preproduction'
OUT=ROOT/'game/data'
def effect(kind,target='enemy',amount=0,**kw):
 d={'kind':kind,'target':target,'amount':amount,'range':3.0,'radius':3.0,'duration':0.0,'max_targets':1};d.update(kw);return d
def dmg(n,count=1,**kw):return effect('damage',amount=n,max_targets=count,**kw)
def heal(n,count=1,**kw):return effect('heal','ally',n,max_targets=count,**kw)
def shield(n,count=1,**kw):return effect('shield',kw.pop('target','ally'),n,max_targets=count,duration=kw.pop('duration',5),**kw)
def buff(stat,multiplier,duration,target='self',count=1,**kw):return effect('buff',target,stat=stat,multiplier=multiplier,duration=duration,max_targets=count,**kw)
def taunt(count=4,duration=3,**kw):return effect('taunt',duration=duration,max_targets=count,radius=kw.pop('radius',2),boss_immune=True,**kw)
def trap(n,slow=0,root=0,count=1,life=12,**kw):return effect('trap',damage=n,slow=slow,root=root,max_targets=count,duration=life,radius=kw.pop('radius',1),range=3,trigger_once=(count==1),ticks=1,max_active_instances=kw.pop('max_active_instances',1),**kw)
def zone(target='enemy',count=3,duration=5,radius=2,**kw):return effect('zone',target,duration=duration,radius=radius,max_targets=count,max_active_instances=1,locked_targets=True,**kw)
def dash(distance=1,**kw):return effect('dash','self',distance=distance,toward=kw.pop('toward',False),**kw)
def cleanse(target='ally',count=1,**kw):return effect('cleanse',target,max_targets=count,**kw)
def decoy(hp=30,count=3,**kw):return effect('decoy','enemy',hp=hp,duration=kw.pop('duration',4),max_targets=count,radius=3,boss_immune=True,max_active_instances=1,**kw)
A={
'BAR01':[[dmg(28,3,shape='line',range=4,radius=4)],[buff('attack_speed',1.25,5)]],
'BAR02':[[heal(32)],[zone('ally',2,5,2,heal=4,interval=1,ticks=5)]],
'BAR03':[[shield(38,target='self')],[taunt(),buff('damage_reduction',.8,3)]],
'BAR04':[[trap(18,root=1.5)],[zone(count=3,duration=4,slow=.35,boss_immune=True)]],
'BAR05':[[dmg(18,hits=3,interval=.3)],[dash(2),buff('damage',1.15,4)]],
'BAR06':[[effect('intercept','ally',.30,duration=5,radius=1.6,damage_cap=40)],[dmg(16,3,radius=2,knockback=1,boss_slow=.2,boss_slow_duration=2)]],
'KIN01':[[heal(32),cleanse()],[shield(20,2,radius=2)]],
'KIN02':[[dmg(34,2,amounts=[34,17],shape='line',range=4,radius=4)],[effect('buff','self',4,stat='flat_damage',duration=5)]],
'KIN03':[[shield(36,target='self',knockback_resist=True)],[taunt(3),buff('move_speed',1.15,3,'ally',radius=1.6)]],
'KIN04':[[trap(16,slow=.4,slow_duration=4)],[zone('ally',3,6,3,move_speed=1.15,buff_duration=4)]],
'KIN05':[[dmg(48,windup=.45)],[buff('attack_speed',1.2,5,slow_immune=True)]],
'KIN06':[[buff('damage_reduction',.75,5)],[shield(16,2,radius=2)]],
'KIN07':[[heal(26),heal(6,ticks=1,interval=2,delay=2,duration=2,lock_target=True)],[heal(20,2,radius=2),cleanse(count=2,radius=2,cleanse_kind='dot')]],
'KIN08':[[trap(14,root=1.5,radius=2)],[zone(count=3,duration=5,radius=3,accuracy=.8,minimum_accuracy=.65)]],
'KIN09':[[dmg(42),buff('armor',.9,4,'enemy')],[buff('move_speed',1.2,4),buff('damage',1.15,4)]],
'KIN10':[[shield(34,target='self'),effect('buff','self',8,stat='flat_damage',duration=5,next_attack_only=True)],[taunt(4,2.5),buff('damage_reduction',.9,3,'ally',2,radius=1.6)]],
'KIN11':[[heal(30),buff('damage_reduction',.9,2,'ally')],[heal(7,ticks=5,interval=1,duration=5,channel=True,lock_target=True)]],
'KIN12':[[dmg(26,3,radius=2,shape='cone')],[dmg(28,interrupt=True,boss_immune_interrupt=True)]],
'KIN13':[[shield(36,target='self',blocks_mobs=True)],[shield(18,2,radius=2)]],
'KIN14':[[trap(12,slow=.45,slow_duration=4)],[buff('attack_speed',1/.7,4,'ally')]],
'KIN15':[[heal(30)],[zone('ally',2,5,2,heal=4,interval=1,ticks=5)]],
'VIL01':[[shield(38,target='self'),buff('move_speed',.8,5)],[dmg(14,3,radius=2,knockback=1,boss_slow=.2,boss_slow_duration=2)]],
'VIL02':[[heal(26),heal(3,ticks=2,interval=1,duration=2,lock_target=True)],[shield(18,2,radius=2)]],
'VIL03':[[dmg(38),effect('reveal',duration=4)],[buff('damage',1.2,5,break_on_redeploy=True)]],
'VIL04':[[trap(16,root=1.5)],[zone('ally',3,5,3,move_speed=1.2,buff_duration=3)]],
'VIL05':[[dmg(40)],[dmg(22,3,radius=3,shape='cone')]],
'VIL06':[[heal(30),cleanse(cleanse_kind='dot')],[shield(32,heal_on_expire=6)]],
'VIL07':[[shield(36,target='self')],[shield(16,2,radius=1.6)]],
'VIL08':[[trap(20,slow=.3,slow_duration=4)],[buff('damage_taken',1.1,4,'enemy',3,radius=2,basic_only=True)]],
'VIL09':[[heal(32)],[heal(7,ticks=5,interval=1,duration=5,channel=True,lock_target=True)]],
'VIL10':[[dmg(24,hits=2,interval=.15)],[dmg(24,3,radius=3,shape='cone')]],
'CAP01':[[dmg(44,shape='line')],[dmg(20,3,radius=2),dash(1)]],
'CAP02':[[trap(24,slow=.3,slow_duration=3,life=8)],[zone('ally',3,5,3,move_speed=1.2,buff_duration=5)]],
'CAP03':[[shield(38,radius=1.6)],[taunt(),buff('damage_reduction',.8,3)]],
'CAP04':[[heal(36),heal(12,radius=1.6,exclude_previous=True)],[zone('ally',3,4,2,heal=6,ticks=4,interval=1)]],
'CAP05':[[dmg(50,shape='line',range=5,radius=5)],[dmg(18,3,radius=3,shape='cone')]],
'CAP06':[[decoy(30)],[trap(18,root=.4,count=2,life=8,radius=2)]],
'CAP07':[[shield(48,target='self')],[dmg(12,3,radius=2,knockback=1,large_immune_knockback=True)]],
'CAP08':[[heal(30),cleanse()],[shield(24,heal_if_intact=16)]],
'CAP09':[[dmg(42),effect('reveal',duration=5)],[dmg(20,root=1.2,boss_slow=.2,boss_slow_duration=2)]],
'CAP10':[[shield(24,2,include_self=True,radius=1.6)],[buff('damage_reduction',.7,4),effect('root','self',duration=4)]],
'PRI01':[[trap(20,slow=.35,slow_duration=3,life=8)],[buff('move_speed',1.2,4,'ally',2,radius=2)]],
'PRI02':[[heal(17,ticks=2,interval=1,duration=2,lock_target=True)],[heal(18,3,radius=1.6,windup=.8,channel=True)]],
'PRI03':[[dmg(20,hits=2,interval=.6,interruptible=True)],[dmg(18,3,radius=1.6),buff('move_speed',1.15,2)]],
'PRI04':[[shield(40,duration=4,radius=1.6)],[effect('root','self',duration=3),effect('intercept','ally',.35,duration=3,radius=1.6,damage_cap=45)]],
'PRI05':[[zone(count=4,duration=5,radius=2,damage=6,slow=.2,interval=1,ticks=5)],[decoy(32,explosion_damage=16,explosion_targets=3,explosion_radius=1.6)]],
'PRI06':[[dmg(46,range=2,radius=2)],[dmg(24),cleanse('self'),dash(1)]],
'PRI07':[[heal(28),shield(12,duration=3)],[heal(5,3,ticks=4,interval=1,duration=4,channel=True,lock_target=True)]],
'PRI08':[[shield(46,target='self',slow_resist=.15)],[dmg(10,3,radius=2,root=.7,boss_immune_root=True)]],
'PRI09':[[dmg(30),dmg(4,ticks=4,interval=1,duration=4,dot=True,stack=False)],[dmg(24,2,radius=1.6),shield(10,target='self',duration=3,condition='both_targets_survive')]],
'PRI10':[[trap(20,root=1,life=8,boss_slow=.2,boss_slow_duration=2)],[zone('ally',3,5,3,move_speed=1.2,buff_duration=5)]],
'PRI11':[[heal(32),buff('damage_reduction',.9,2,'ally')],[zone('ally',3,4,2,heal=5,ticks=4,interval=1,cleanse=True)]],
'PRI12':[[taunt(),buff('damage_reduction',.82,3)],[shield(36,radius=1.6),shield(12,target='self')]],
'GEN01':[[heal(18,3,radius=2)],[shield(36),cleanse()]],
'GEN02':[[shield(50,target='self')],[shield(22,2,radius=1.6)]],
'GEN03':[[dmg(20,3,radius=1.6)],[dmg(48,windup=.6,cancel_out_of_range=True)]],
'GEN04':[[decoy(32)],[zone(count=4,duration=5,radius=2,damage=6,slow=.2,interval=1,ticks=5)]],
'GEN05':[[zone(count=6,duration=5,radius=2,slow=.3)],[trap(20,count=4,life=6,radius=3,reveal=3)]],
}
# Gameplay effects for the nine enemy models, relative to each enemy caster's team.
EA={
'MOB01':[[dash(2,toward=True),dmg(6,range=1.2,radius=1.2)],[buff('damage_reduction',.65,2),effect('root','self',duration=2)]],
'MOB02':[[dash(1.5,toward=True),buff('evasion',1.0,.3,one_projectile=True)],[buff('evasion',.1,2,'ally',3,radius=2)]],
'MOB03':[[buff('damage_reduction',.6,3,front_only=True,back_multiplier=1.1)],[zone('enemy',6,4,1,slow=.2,slow_duration=2,affects_both_sides=True)]],
'MOB04':[[dmg(7,3,radius=3,shape='cone')],[buff('range',3.8/2.8,1.5,next_attack_only=True),effect('root','self',duration=1.5,landed=True)]],
'MOB05':[[heal(12,3,radius=3)],[effect('summon','self',enemy_id='MOB01',count=1,max_summons=2,max_targets=1)]],
'MOB06':[[dmg(14,4,radius=2,root=.5,shape='area')],[effect('intercept','ally',.25,duration=3,radius=2,damage_cap=50)]],
'MOB07':[[trap(4,slow=.3,slow_duration=1.5,life=6,arm_delay=1,max_active_instances=2)],[effect('disable_trap',duration=3,radius=3)]],
'MOB08':[[dmg(8,3,radius=.65,windup=.5,shape='area')],[dash(1),decoy(1,1,duration=2,blocks_projectile=True)]],
'BOSS01':[[dmg(18,6,radius=4,shape='roots',windup=1.4,segment_interval=.5,safe_lane=True)],[effect('anchors','self',count=2,hp=60,duration=6,shield_amount=120,exposed_duration=3,max_targets=2)]],
}

def build():
 chars=[]
 for file in ['first-recruits.json','late-recruits.json']:
  chars+=json.loads((SRC/'data'/file).read_text())['characters']
 boards=json.loads((SRC/'art/manifest.json').read_text())
 portraits={}
 for b in boards:
  if 'portrait_layout' not in b:continue
  layout=b['portrait_layout']
  for row,cid in enumerate(b['ids']):
   portraits[cid]={'file':'res://assets/portraits/'+Path(b['file']).name,'region':[layout['x'],layout['y']+row*layout['step'],layout['w'],layout['h']]}
 abilities={}
 outchars=[]
 for raw in chars:
  cid=raw['id'];assert cid in A
  st=copy.deepcopy(raw['stats'])
  st['basic_attack']=copy.deepcopy(st.get('basic_attack',{}))
  st['basic_attack'].setdefault('damage',st.get('basic_attack_damage',8))
  st['basic_attack'].setdefault('interval_seconds',st.get('basic_attack_interval_seconds',1))
  st['basic_attack'].setdefault('range_tiles',st.get('basic_attack_range_tiles',3))
  st['basic_attack'].setdefault('delivery','projectile' if raw['class'] in ['Healer','Strategist'] else 'melee')
  if 'melee' in st['basic_attack']['delivery']:
   st['basic_attack']['delivery']='melee'
   st['basic_attack']['range_tiles']=min(st['basic_attack']['range_tiles'],1.35)
  else:st['basic_attack']['delivery']='projectile'
  st['baseline_heal_hp_per_second']=float(st.get('baseline_heal_hp_per_second',st.get('base_healing_hp_per_second',12 if raw['class']=='Healer' else 0)))
  st['support_priority']='lowest_health_percentage_then_Tanker_then_DPS'
  st['balance_status']='implemented starting budget; scenario-tested, not statistically playtested'
  model={k:copy.deepcopy(raw.get(k,'')) for k in ['id','name','origin','age','pronouns','class','appearance','silhouette','palette','weapon','intro','story_hook','elevated_tower_variant']}
  model['stats']=st;model['portrait']=portraits[cid];model['art_id']=cid
  model['tower_eligible']=bool(raw.get('elevated_tower_variant',{}).get('available',raw.get('animations',{}).get('tower_variant',{}).get('eligible',False)))
  model['abilities']=[]
  for slot,a in enumerate(raw['abilities']):
   entry={'id':cid+':'+str(slot),'character_id':cid,'slot':slot,'name':a['name'],'cooldown_seconds':float(a['cooldown_seconds']),'description':a.get('effect_target',a.get('effect','')),'vfx':a.get('vfx',a.get('visual','')),'effects':A[cid][slot],'target_mode':'self' if all(x['target']=='self' for x in A[cid][slot]) else 'line' if any(x.get('shape')=='line' for x in A[cid][slot]) else 'area','windup':.25,'color':{'Healer':'#83d7b4','DPS':'#efad68','Tanker':'#78b6e8','Strategist':'#d5b36f'}[raw['class']]}
   entry['windup']=max([float(x.get('windup',.25)) for x in entry['effects']])
   entry['short_description']=entry['description'].split(';')[0]
   abilities[entry['id']]=entry;model['abilities'].append(entry)
  outchars.append(model)
 world=copy.deepcopy(json.loads((SRC/'data/world.json').read_text()))
 world['scope']='Playable prototype runtime data derived from the original preproduction design. Combat and recruitment are implemented; balance remains provisional. Animation contracts below retain the original production targets; actual runtime pose coverage is documented in docs/ART-REVIEW.md.'
 world['runtime_version']=1
 for m in world['maps']:
  idx=int(m['id'][-2:])-1
  m.update(wave_count=4,gate_hp=100,starting_coins=300,stage_index=idx,target_minutes=[4,5,6,4,5,5][idx],enemy_roster=[['MOB01','MOB02'],['MOB01','MOB02','MOB03','MOB04'],['MOB01','MOB03','MOB05','MOB06'],['MOB01','MOB07','MOB08'],['MOB02','MOB04','MOB06','MOB07','MOB08'],['MOB01','MOB03','MOB05','BOSS01']][idx])
 for e in world['enemies']:
  cid=e['id'];st=e['draft_stats'];e['stats']={'hp':st['hp'],'damage':st['basic_damage'],'interval':st['attack_interval_s'],'move_speed':st['movement_tiles_s'],'range':2.8 if cid in ['MOB02','MOB04','MOB05','MOB08'] else 1.15,'delivery':'projectile' if cid in ['MOB02','MOB04','MOB05','MOB08'] else 'melee'}
  e['runtime_abilities']=[]
  for slot,a in enumerate(e['abilities']):
   e['runtime_abilities'].append({'id':cid+':'+str(slot),'name':a['name'],'cooldown_seconds':a['cooldown_s'],'description':a['draft_effect'],'vfx':a['vfx'],'effects':EA[cid][slot],'windup':a.get('windup_s',.6),'target_mode':'area','color':'#df7c72'})
 tower_values=[(55,100,0,0),(45,100,0,0),(65,100,0,0),(80,100,18,2)]
 for t,(cost,hp,damage,interval) in zip(world['towers'],tower_values):
  t.update(cost=cost,hp=hp,damage=damage,interval=interval,range=4,upgrade_costs=[65,95],max_level=3)
 for t,cost,damage,slow in zip(world['traps'],[12,16,14],[4,12,0],[.25,0,0]):
  t.update(cost=cost,damage=damage,slow=slow,duration=2 if slow else 1.5,max_targets=1 if t['id']=='TRAP01' else 4 if t['id']=='TRAP02' else 3)
 OUT.mkdir(parents=True,exist_ok=True)
 for filename,data in [('characters.json',{'version':1,'characters':outchars}),('abilities.json',abilities),('world.json',world)]:
  (OUT/filename).write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n')
 assert len(outchars)==58 and len(abilities)==116
 assert len({a['name'] for a in abilities.values()})==116
 assert all(a['effects'] and a['cooldown_seconds']>=10 for a in abilities.values())
 print(f'Compiled{len(outchars)}characters/{len(abilities)}abilities/{len(world["enemies"])}enemy models')
if __name__=='__main__':build()
