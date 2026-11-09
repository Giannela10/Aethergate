const fs=require('fs'),path=require('path'),cp=require('child_process');
const jobs=[{tool:'script_edit',arguments:{file_path:'res://scripts/juego/character_footwear_6_3.gd',old_string:'var key=source.get_instance_id()',new_string:'var key=source.resource_path\n\tif key.is_empty():\n\t\tvar names=[]\n\t\tfor shape in source.get_blend_shape_count(): names.append(source.get_blend_shape_name(shape))\n\t\tkey=str(hash([source.surface_get_arrays(0)[Mesh.ARRAY_VERTEX],names]))'}}];
const file=path.join(__dirname,'share_body_cache_jobs63.json');fs.writeFileSync(file,JSON.stringify(jobs));
cp.execFileSync(process.execPath,[path.join(__dirname,'visual_mcp_5.cjs'),'run',file],{stdio:'inherit'});
