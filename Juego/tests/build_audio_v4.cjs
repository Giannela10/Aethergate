// Original synthesized audio. No third-party samples or copyrighted melodies.
const fs=require('node:fs'),path=require('node:path');
const dest=path.join(__dirname,'../assets/audio/v4');fs.mkdirSync(dest,{recursive:true});
let seed=41024;function noise(){seed=(1664525*seed+1013904223)>>>0;return seed/4294967296*2-1}
function wav(name,duration,sample){const rate=22050,n=Math.floor(rate*duration),data=Buffer.alloc(44+n*2);data.write('RIFF');data.writeUInt32LE(36+n*2,4);data.write('WAVEfmt ',8);data.writeUInt32LE(16,16);data.writeUInt16LE(1,20);data.writeUInt16LE(1,22);data.writeUInt32LE(rate,24);data.writeUInt32LE(rate*2,28);data.writeUInt16LE(2,32);data.writeUInt16LE(16,34);data.write('data',36);data.writeUInt32LE(n*2,40);for(let i=0;i<n;i++){const t=i/rate;const fade=Math.min(1,t/.03,(duration-t)/.04);data.writeInt16LE(Math.round(Math.max(-1,Math.min(1,sample(t)*fade))*32767),44+i*2)}fs.writeFileSync(path.join(dest,name+'.wav'),data)}
const sine=(f,t)=>Math.sin(2*Math.PI*f*t);
wav('menu',8,t=>[130.81,164.81,196].reduce((sum,f)=>sum+sine(f,t),0)*.025);
for(const [name,f]of [['hall',80],['library',100],['casino',120],['laboratory',60],['workshop',40],['elevator',90]])wav(name,4,t=>(sine(f,t)*.012+noise()*.006)*(0.7+0.3*sine(.25,t)));
wav('interact',.16,t=>sine(660,t)*.1);
wav('impact',.12,t=>noise()*.2*Math.exp(-35*t));
wav('reward',.6,t=>sine([523.25,659.25,783.99][Math.min(2,Math.floor(t*5))],t)*.12);
wav('victory',1.2,t=>sine([392,523.25,659.25,783.99][Math.min(3,Math.floor(t/0.3))],t)*.1);
wav('defeat',.9,t=>sine(330-t*180,t)*.08);
wav('simulation',.6,t=>sine(180+500*t,t)*.08);
fs.writeFileSync(path.join(dest,'LICENSE.md'),'# Audio original DuocGames 4.0\n\nTonos y ambientes sintetizados por tests/build_audio_v4.cjs. Sin muestras externas ni voces. Se permite su uso, modificación y distribución con el proyecto (CC0-1.0). No representan grabaciones reales del campus.\n');
console.log(JSON.stringify({generated:fs.readdirSync(dest).filter(n=>n.endsWith('.wav')).length,license:'CC0-1.0'}));
