const fs=require('fs'),path=require('path'),cp=require('child_process');
const file='Juego/scripts/campaign/interaction_controller.gd';let code=fs.readFileSync(file,'utf8').replaceAll('\r\n','\n');
code=code.replace('not player._can_reach(node.interaction_target() if node.has_method("interaction_target") else node)','not can_reach_target(node)');
code+=`
func can_reach_target(node: Node3D) -> bool:
	var player=campaign.player
	var target: Node3D=node.interaction_target() if node.has_method("interaction_target") else node
	if player._can_reach(target): return true
	# A mentor and its simulation collider are separate actors. Only ignore the
	# paired simulation body; walls and other scene colliders still block sight.
	if not target.is_in_group("educational_mentor"): return false
	var actor=node.get("actor")
	if not actor is CollisionObject3D: return false
	var query=PhysicsRayQueryParameters3D.create(player.global_position+Vector3.UP*1.2,target.global_position+Vector3.UP*1.2)
	query.exclude=[player.get_rid(),actor.get_rid()]
	var hit=player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty(): return true
	var collider=hit.get("collider") as Node
	return collider==target or collider!=null and target.is_ancestor_of(collider)
`;
const job=path.join(__dirname,'fix_capstone_interaction.json');fs.writeFileSync(job,JSON.stringify({file_path:'res://scripts/campaign/interaction_controller.gd',content:code}));
cp.execFileSync(process.execPath,[path.join(__dirname,'visual_mcp_5.cjs'),'script_write','@'+job],{stdio:'inherit'});
