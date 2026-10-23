"""Assemble original image briefs from the completed visual models."""
from pathlib import Path
import json
root=Path(__file__).resolve().parents[1]
characters=[]
for f in ('first-recruits.json','late-recruits.json'):
    characters+=json.loads((root/'data'/f).read_text())['characters']
by_id={c['id']:c for c in characters}
common='''Create ORIGINAL pixel-art visual preproduction for BELDE: THE WRONG COMMANDER, a warm dark-fairytale tower-defense game. Rich, masterful pixel clusters; navy and charcoal shadows, warm parchment, worn copper, muted moss, luminous teal and amber accents. Clear three-quarter top-down RPG battle sprites; hard pixel edges; single upper-left light; readable silhouettes, no photographic rendering, no glossy 3D, no existing game characters. This is a polished reference contact sheet, NOT a screenshot of code. Keep all characters in their specified exact row; preserve their individual silhouette, clothing, face, weapon, species, color and prop consistency across their row. Every combatant is an adult. Use a wide landscape canvas with sufficient breathing room. Background dark slate with subtle warm grid lines. Avoid decorative clutter and excessive tiny lettering. '''
groups=[('01-bar','The Wayfarer Bar', ['BAR%02d'%i for i in range(1,7)]),('02-kingdom-a','Kingdom · Oathkeepers',['KIN%02d'%i for i in range(1,6)]),('03-kingdom-b','Kingdom · Watch & Ward',['KIN%02d'%i for i in range(6,11)]),('04-kingdom-c','Kingdom · Last Banner',['KIN%02d'%i for i in range(11,16)]),('05-village-a','Village · Hearthfolk',['VIL%02d'%i for i in range(1,6)]),('06-village-b','Village · Field & Forge',['VIL%02d'%i for i in range(6,11)]),('07-capital-a','Royal Capital · Silver Contracts',['CAP%02d'%i for i in range(1,6)]),('08-capital-b','Royal Capital · Free Companies',['CAP%02d'%i for i in range(6,11)]),('09-prison-a','Prison · The Unbroken',['PRI%02d'%i for i in range(1,7)]),('10-prison-b','Prison · Beyond the Bars',['PRI%02d'%i for i in range(7,13)]),('11-generals','The Five Monster Generals',['GEN%02d'%i for i in range(1,6)])]
# Accommodate the initial-roster ID prefix while preserving the canonical IDs.
for c in characters:
    if c['id'].startswith('KNG'): by_id['KIN'+c['id'][3:]]=c
briefs=[]
for slug,title,ids in groups:
    rows=[]
    for i,cid in enumerate(ids,1):
        if cid not in by_id: raise KeyError(f'Missing roster ID {cid}; reconcile the model IDs before generation')
        c=by_id[cid]
        rows.append(f"ROW {i} — {c['id']} {c['name']} — {c['class']} age {c.get('age','adult')}. Appearance: {json.dumps(c.get('appearance'),ensure_ascii=False)}. Silhouette: {c.get('silhouette','see appearance')}. Weapon: {c.get('weapon','see appearance')}. Accent palette: {c.get('palette','see appearance')}. Portrait: {json.dumps(c.get('portrait'),ensure_ascii=False)}. Two abilities and their graphics: {json.dumps(c['abilities'],ensure_ascii=False)}.")
    prompt=common+f'''Title: {title.upper()}. Exactly {len(ids)} HORIZONTAL CHARACTER ROWS and EIGHT COLUMNS. One row per named character. Columns, in strict order: 1 PORTRAIT close-up square face; 2 IDLE full body relaxed stance; 3 WALK full body heel-strike pose; 4 RUN full body long passing stride; 5 ATTACK full body active contact with personal weapon/attack arc; 6 ABILITY I full body with first signature visual effect; 7 ABILITY II full body with second different signature visual effect; 8 DOWNED full body resting wounded, non-graphic and recoverable. All sprites should show entire bodies and no cropping. Portrait ONLY in column1. Walking and running must visibly differ. Each ability effect must express the particular brief, not generic explosions. Downed figures retain equipment and colors. Header labels can be short. Put canonical ID and name at each row's left edge; identity is more important than extra prose. Keep exact species including nonhuman general features.\n'''+ '\n'.join(rows)
    briefs.append({'id':slug,'title':title,'ids':[by_id[x]['id'] for x in ids],'file':'art/'+slug+'.png','description':f"{len(ids)} character models: portrait, idle, walk, run, basic attack, two abilities and downed key poses. Reference artwork; complete animation frames remain to be authored.",'prompt':prompt})
(root/'art/image-briefs.json').write_text(json.dumps(briefs,indent=2,ensure_ascii=False))
print(f'Prepared {len(briefs)} sheets covering {sum(len(b["ids"]) for b in briefs)} models')
