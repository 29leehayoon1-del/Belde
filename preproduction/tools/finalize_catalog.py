"""Inventory the visual references; never transform generated images."""
import csv,hashlib,itertools,json,pathlib
from PIL import Image
ROOT=pathlib.Path(__file__).resolve().parents[1]
briefs=[]
for f in ['image-briefs.json','world-image-briefs.json']:
    briefs.extend(json.loads((ROOT/'art'/f).read_text()))
# Display windows into the original boards, used only by the HTML artbook.
# The raster sources are unchanged. Portrait windows are reference crops.
layouts=[(140,100,146,120,116),(182,111,174,125,127),(142,112,175,125,125),(193,147,161,115,119),(143,119,174,127,125),(198,119,174,113,119),(181,111,177,122,123),(148,119,173,119,121),(142,116,145,117,114),(185,123,144,120,113),(167,115,174,111,121)]
manifest=[];missing=[]
for idx,b in enumerate(briefs):
    p=ROOT/b['file']
    if not p.exists():missing.append(b['file']);continue
    with Image.open(p) as im:
        im.verify()
    with Image.open(p) as im:w,h=im.size
    item={k:v for k,v in b.items() if k!='prompt'}
    item.update(width=w,height=h,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),status='generated concept / reference key poses')
    if idx<11:
        x,y,step,pw,ph=layouts[idx]
        item['portrait_layout']={'x':x,'y':y,'step':step,'w':pw,'h':ph}
    manifest.append(item)
(ROOT/'art/manifest.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False))
w=json.loads((ROOT/'data/world.json').read_text());t=w['titles']
rows=[]
for n,(epithet,deed,legacy,verse) in enumerate(itertools.product(t['epithets'],t['deeds'],t['legacies'],t['ending_verses']),1):
    rows.append([f'TITLE{n:04}',f'The {epithet} {deed} {legacy}',verse,'Editorial candidate; selection rules and copy review pending'])
with (ROOT/'data/title-candidates.csv').open('w',newline='') as f:
    writer=csv.writer(f);writer.writerow(['id','title','ending_verse','status']);writer.writerows(rows)
chars=[]
for f in ['first-recruits.json','late-recruits.json']:chars+=json.loads((ROOT/'data'/f).read_text())['characters']
seen=[cid for p in manifest for cid in p.get('ids',[])]
report={'scope':'Visual preproduction, not game implementation','recruitable_models':len(chars),'recruit_abilities':sum(len(c['abilities']) for c in chars),'enemy_models':len(w['enemies']),'enemy_abilities':sum(len(e['abilities']) for e in w['enemies']),'maps':len(w['maps']),'recruitment_locations':len(w['recruitment_locations']),'tower_families':len(w['towers']),'trap_families':len(w['traps']),'concept_boards_expected':len(briefs),'concept_boards_present':len(manifest),'missing_boards':missing,'character_ids_in_boards':len(seen),'missing_character_boards':[c['id'] for c in chars if c['id'] not in seen],'title_card_candidates':len(rows),'production_core_body_frames_remaining':sum(w['animation_contract']['animations'][a]['frames'] for a in ['idle','walk','run','basic_attack','ability_a','ability_b','hit','downed'])*8*len(chars),'production_status':'Concept key poses and full written specifications. Final frame sequences, directional sprites, cleanup, atlases and implementation are not delivered.'}
(ROOT/'data/coverage.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
