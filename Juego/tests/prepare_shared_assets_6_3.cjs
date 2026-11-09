const fs=require('fs'),path=require('path'),crypto=require('crypto');
const dest='Juego/assets/characters/shared_6_3';fs.mkdirSync(dest+'/source',{recursive:true});fs.mkdirSync(dest+'/native',{recursive:true});fs.writeFileSync(dest+'/source/.gdignore','');
const catalog=JSON.parse(fs.readFileSync('recovery/main_character_6_2/remote_output_catalog.json'));
const rows=[];
for(const root of ['recovery/main_character_6_2/asset_review','recovery/characters_6_3/asset_review'])for(const file of fs.readdirSync(root).filter(f=>f.endsWith('.glb'))){
 const raw=fs.readFileSync(path.join(root,file)),entry=catalog.find(x=>x.name===file);const sha=crypto.createHash('sha1').update(Buffer.concat([Buffer.from('blob '+raw.length+'\0'),raw])).digest('hex');if(entry&&sha!==entry.sha)throw Error('Asset differs from audited source '+file);rows.push({file,source:entry?.html_url,git_blob:sha,sha256:crypto.createHash('sha256').update(raw).digest('hex'),license:'CC0-1.0'});
}
fs.writeFileSync(dest+'/provenance.json',JSON.stringify(rows,null,2));
let code=fs.readFileSync('Juego/tests/prepare_human_assets_6_2.cjs','utf8');
code=code.replace("const source='recovery/main_character_6_2/asset_review',dest='Juego/assets/characters/main_6_2/source';","const source='recovery/characters_6_3/asset_review',dest='Juego/assets/characters/shared_6_3/source';");
code=code.replace(/const keep=new Set\(\[.*?\]\);/,"const keep=new Set(['gender_male','gender_female','age_old','weight_min','weight_max','muscle_min','muscle_max','blink_left','blink_right',...(j.meshes[0].extras?.targetNames||[]).filter(n=>n.startsWith('face_'))]);");
fs.writeFileSync('Juego/tests/prepare_human_assets_6_3.cjs',code);
for(const file of ['base_body_anim','clothing_tshirt','clothing_hoodie','clothing_jeans','clothing_shoes','hair_short02','hair_short04','hair_long01'])fs.copyFileSync('recovery/main_character_6_2/asset_review/'+file+'.glb','recovery/characters_6_3/asset_review/'+file+'.glb');
