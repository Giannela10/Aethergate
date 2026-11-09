// Restore only verified editor serialization noise. Preserve every version first.
const fs=require('fs'),cp=require('child_process');
const original=fs.readFileSync('recovery/main_character_6_2/Juego/Main.tscn'),current=fs.readFileSync('Juego/Main.tscn');
if(original.equals(current)){console.log('Main already byte-identical to checkpoint');process.exit(0);}
cp.execFileSync(process.execPath,['Juego/tests/audit_main_serialization_6_2.cjs'],{stdio:'ignore'});
const audit=JSON.parse(fs.readFileSync('Juego/reports/main_character_6_2/main_serialization_audit.json'));
if(audit.changed_blocks.length)throw Error('Semantic Main changes detected; refusing to overwrite');
if(!current.equals(fs.readFileSync('Juego/Main.tscn')))throw Error('Main changed during audit; refusing to overwrite');
fs.writeFileSync('recovery/main_character_6_2/Main_editor_serialized_'+Date.now()+'.tscn',current,{flag:'wx'});
fs.writeFileSync('Juego/Main.tscn',original);
console.log('Main restored; editor serialization version preserved');
