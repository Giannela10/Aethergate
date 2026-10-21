// Make the new aisle shelving readable from both directions without new materials.
const fs=require('fs'),file='Main.tscn';
const source=fs.readFileSync(file,'utf8');
if(source.includes('name="LibrosReverso')){console.log('Double-sided shelves already applied.');process.exit(0);}
const blocks=source.split(/(?=^\[)/m),added=[];
const root='Piso2/Biblioteca/PasillosEstanterias';
for(let i=0;i<blocks.length;i++){
 const b=blocks[i];if(!b.startsWith('[node '))continue;
 const parent=b.match(/parent="([^"]+)"/)?.[1];if(!parent?.startsWith(root))continue;
 const name=b.match(/name="([^"]+)"/)[1];
 const original=b.match(/transform = Transform3D\(([^)]+)\)/)?.[1].split(',').map(Number);
 if(!original)continue;
 if(name.startsWith('Repisa')||name==='CostadoI'||name==='CostadoD'){
  const size=b.match(/size = Vector3\(([^)]+)\)/)?.[1].split(',').map(Number);
  if(size){size[2]=1.3;const t=[...original];t[11]=-.25;
   blocks[i]=b.replace(/size = Vector3\([^)]+\)/,'size = Vector3('+size.join(', ')+')').replace(/transform = Transform3D\([^)]+\)/,'transform = Transform3D('+t.join(', ')+')');
  }
 }
 if(name.startsWith('Libros')){
  const t=[...original];t[11]=-.63;
  added.push(b.replace('name="'+name+'"','name="LibrosReverso'+name.slice(6)+'"').replace(/ unique_id=\d+/,'').replace(/transform = Transform3D\([^)]+\)/,'transform = Transform3D('+t.join(', ')+')'));
 }
 if(name.startsWith('EtiquetaLomo')){
  const t=[...original];t[11]=-.851;
  added.push(b.replace('name="'+name+'"','name="EtiquetaReverso'+name.slice(12)+'"').replace(/ unique_id=\d+/,'').replace(/transform = Transform3D\([^)]+\)/,'transform = Transform3D('+t.join(', ')+')'));
 }
 if(name==='Categoria'){
  const t=[-1,0,0,0,1,0,0,0,-1,original[9],original[10],-.96];
  added.push(b.replace('name="Categoria"','name="CategoriaReverso"').replace(/ unique_id=\d+/,'').replace(/transform = Transform3D\([^)]+\)/,'transform = Transform3D('+t.join(', ')+')'));
 }
}
let result=blocks.join('');const c=result.indexOf('[connection ');
result=c<0?result+added.join(''):result.slice(0,c)+added.join('')+result.slice(c);
fs.writeFileSync(file,result.trimEnd()+'\n');
console.log('LIBRARY_DOUBLE_SIDED_OK new rows and flanking shelves have books, shelves and labels on both sides');
