// Independent format conversion of CC0 data. No upstream program code is used.
const fs=require('fs'),path=require('path');
const source='recovery/main_character_6_2/asset_review',dest='Juego/assets/characters/main_6_2/source';
for(const file of fs.readdirSync(source).filter(f=>f.endsWith('.glb'))){
 const raw=fs.readFileSync(path.join(source,file)),jsonSize=raw.readUInt32LE(12);
 const j=JSON.parse(raw.subarray(20,20+jsonSize));
 const binStart=20+jsonSize+8, original=raw.subarray(binStart);
 let chunks=[original],length=original.length;
 const keep=new Set(['gender_male','face_jaw_width_decr','face_jaw_width_incr','face_chin_incr','face_cheekbones_incr','blink_left','blink_right']);
 for(const m of j.meshes){const names=m.extras?.targetNames||[],indices=names.map((n,i)=>keep.has(n)?i:-1).filter(i=>i>=0);for(const p of m.primitives)if(p.targets)p.targets=indices.map(i=>p.targets[i]);if(m.weights)m.weights=indices.map(()=>0);if(m.extras?.targetNames)m.extras.targetNames=indices.map(i=>names[i]);}
 const targets=new Set(j.meshes.flatMap(m=>m.primitives.flatMap(p=>(p.targets||[]).flatMap(t=>Object.values(t)))));
 const sizes={5120:1,5121:1,5122:2,5123:2,5125:4,5126:4},components={SCALAR:1,VEC2:2,VEC3:3,VEC4:4,MAT4:16};
 const read=(b,p,t)=>t===5120?b.readInt8(p):t===5121?b.readUInt8(p):t===5122?b.readInt16LE(p):t===5123?b.readUInt16LE(p):t===5125?b.readUInt32LE(p):b.readFloatLE(p);
 for(const id of targets){const a=j.accessors[id];if(a.componentType===5126)continue;
  const n=components[a.type],size=sizes[a.componentType],values=new Float32Array(a.count*n);
  const normalize=v=>!a.normalized?v:a.componentType===5120?Math.max(v/127,-1):a.componentType===5122?Math.max(v/32767,-1):a.componentType===5121?v/255:v/65535;
  if(a.bufferView!==undefined){const v=j.bufferViews[a.bufferView],start=(v.byteOffset||0)+(a.byteOffset||0),stride=v.byteStride||size*n;for(let i=0;i<a.count;i++)for(let k=0;k<n;k++)values[i*n+k]=normalize(read(original,start+i*stride+k*size,a.componentType));}
  if(a.sparse){const s=a.sparse,iv=j.bufferViews[s.indices.bufferView],vv=j.bufferViews[s.values.bufferView];for(let i=0;i<s.count;i++){const vertex=read(original,(iv.byteOffset||0)+(s.indices.byteOffset||0)+i*sizes[s.indices.componentType],s.indices.componentType);for(let k=0;k<n;k++)values[vertex*n+k]=normalize(read(original,(vv.byteOffset||0)+(s.values.byteOffset||0)+(i*n+k)*size,a.componentType));}}
  const pad=(4-length%4)%4;if(pad){chunks.push(Buffer.alloc(pad));length+=pad;}
  const bytes=Buffer.from(values.buffer);j.bufferViews.push({buffer:0,byteOffset:length,byteLength:bytes.length});
  a.bufferView=j.bufferViews.length-1;a.byteOffset=0;a.componentType=5126;delete a.normalized;delete a.sparse;delete a.min;delete a.max;
  chunks.push(bytes);length+=bytes.length;
 }
 for(const m of j.meshes){if(m.weights)m.weights=m.weights.map(()=>0);}
 for(const key of ['extensionsRequired','extensionsUsed']){j[key]=(j[key]||[]).filter(x=>x!=='KHR_mesh_quantization');if(!j[key].length)delete j[key];}
 j.buffers=[{byteLength:length}];
 const text=Buffer.from(JSON.stringify(j)),pad=(4-text.length%4)%4,json=Buffer.concat([text,Buffer.alloc(pad,32)]),bin=Buffer.concat(chunks),header=Buffer.alloc(20);
 header.write('glTF');header.writeUInt32LE(2,4);header.writeUInt32LE(20+json.length+8+bin.length,8);header.writeUInt32LE(json.length,12);header.writeUInt32LE(0x4e4f534a,16);
 const bh=Buffer.alloc(8);bh.writeUInt32LE(bin.length);bh.writeUInt32LE(0x004e4942,4);
 fs.writeFileSync(path.join(dest,file),Buffer.concat([header,json,bh,bin]));
 console.log(file+' dequantized: '+raw.length+' -> '+(20+json.length+8+bin.length));
}
