const fs=require('fs');let s=fs.readFileSync('.codex/check_auditorium.gd','utf8');const a=s.indexOf('\tfor z in [-118.5'),b=s.indexOf('\t\t\tif reverse:',a);s=s.slice(0,a)+`\tfor y in [0.0,12.058385849,23.967668533,35.674415588]:
\t\tfor x in [-25.5564,25.7464]:
\t\t\tfor reverse in [false,true]:
\t\t\t\tvar z := y
\t\t\t\tvar points := [Vector3(x,y+0.08,-121),Vector3(x,y+0.08,-99)]
`+s.slice(b).split('\n').map(l=>l.startsWith('\t\t\t')?'\t'+l:l).join('\n');s=s.replace('AUDITORIUM_WALK','CORRIDOR_WALK');fs.writeFileSync('.codex/check_uniform_corridors.gd',s);
