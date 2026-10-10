extends state_machine

# Called when the node enters the scene tree for the first time.
func _ready():
	states_map = {
			"idle": $idle,
			"walk": $walk,
			"run": $run,
			"jump": $jump,
			"fall": $fall,
			"dash": $dash,
			"damage": $damage,
			"climb":$climb,
			"wall_slide":$wall_slide,
			"wall_jump": $wall_jump,
			"die": $die,
			"hold": $hold
		}
	return super._ready()

func _change_state(state_name):
	if not _active: 
		return
	if state_name in ["run", "attack", "jump"]: ##Check behaviour and return if necessary.
		states_stack.push_front(states_map[state_name])
		
	if state_name == "run":
		if current_state == $walk:
			$run.Initialize($walk.Velocity)
		if current_state == $idle:
			$run.Initialize($idle.Velocity)
		if current_state == $jump:
			$run.Initialize($jump.Velocity)
		if current_state == $fall:
			$run.Initialize($fall.Velocity)

	if state_name == "walk":
		if current_state == $idle:
			$walk.Initialize($idle.Velocity)
		if current_state == $run:
			$walk.Initialize($run.Velocity)
		if current_state == $jump:
			$walk.Initialize($jump.Velocity)
		if current_state == $fall:
			$walk.Initialize($fall.Velocity)
			
	if state_name == "idle":
		if current_state == $walk:
			$idle.Initialize($walk.Velocity)
		if current_state == $run:
			$idle.Initialize($run.Velocity)
		if current_state == $jump:
			$idle.Initialize($jump.Velocity)
			
	if state_name == "jump":
		if current_state == $walk or current_state == $idle or current_state == $run or current_state == $fall:
			$jump.Initialize(current_state.Velocity, current_state.Speed)
		if current_state == $dash:
			var new_speed = current_state.Speed/2
			$jump.Initialize(current_state.Velocity, new_speed)

	if state_name == "fall":
		if current_state == $walk or current_state == $idle or current_state == $run or current_state == $jump or current_state == $dash or current_state == $wall_jump:
			$fall.Initialize(current_state.Velocity,current_state.Speed, current_state.Dashed) 

	if state_name == "dash":
		if current_state == $walk:
			$dash.Initialize($walk.Velocity,$walk.Speed,$walk.Dashed)
		if current_state == $idle:
			$dash.Initialize($idle.Velocity,$idle.Speed,$idle.Dashed)
		if current_state == $run:
			$dash.Initialize($run.Velocity,$run.Speed,$run.Dashed)
		if current_state == $jump:
			$dash.Initialize($jump.Velocity, $jump.Speed,$jump.Dashed)
		if current_state == $fall:
			$dash.Initialize($fall.Velocity, $fall.Speed,$fall.Dashed)
		if current_state == $wall_jump:
			$dash.Initialize($wall_jump.Velocity, $wall_jump.Speed,$wall_jump.Dashed)
			
	if state_name == "wall_jump":
		if current_state == $wall_slide:
			$wall_jump.Initialize($wall_slide.Direction)
			
	if state_name == "wall_slide":
		if current_state == $wall_jump:
			$wall_slide.Initialize($wall_jump.Velocity,$wall_jump.Direction)
	return super._change_state(state_name)


func _input(event):
#	Here we only handle input that can interrupt states, attacking in this case
	#otherwise we let the state node handle it#
	current_state.handle_input(event)
