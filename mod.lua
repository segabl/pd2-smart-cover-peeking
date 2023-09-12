local fdw_ray_from = Vector3()
local fwd_ray_to = Vector3()
local head_stance_translation = Vector3()

Hooks:PostHook(PlayerStandard, "init", "init_scp", function (self)
	self._peek_active = false
	self._peek_slotmask = managers.slot:get_mask("statics")
	self._peek_head_stance = {
		translation = Vector3(),
		rotation = Rotation()
	}
end)

Hooks:PostHook(PlayerStandard, "update", "update_scp", function (self)
	if not self._state_data.ducking or not self._peek_head_stance then
		self._peek_active = false
		return
	elseif not self._state_data.in_steelsight then
		if self._peek_active then
			self._ext_network:send("action_change_pose", 2, self._unit:position())
			self._peek_active = false
		end
		return
	end

	local stance_standard = tweak_data.player.stances.default[managers.player:current_state()] or tweak_data.player.stances.default.standard
	local crouched_head_stance = tweak_data.player.stances.default.crouched.head
	local m_pos = self._unit:movement():m_pos()
	local peek_distance = self._peek_active and 125 or 75

	mvector3.set(fdw_ray_from, crouched_head_stance.translation)
	mvector3.add(fdw_ray_from, m_pos)

	mvector3.set(fwd_ray_to, self._cam_fwd)
	mvector3.set_z(fwd_ray_to, 0)
	mvector3.set_length(fwd_ray_to, peek_distance)
	mvector3.add(fwd_ray_to, fdw_ray_from)

	local fwd_ray = World:raycast("ray", fdw_ray_from, fwd_ray_to, "slot_mask", self._peek_slotmask, "sphere_cast_radius", 5)
	if not fwd_ray then
		if self._peek_active then
			self:_stance_entered()
			self._ext_network:send("action_change_pose", 2, self._unit:position())
			self._peek_active = false
		end
		return
	end

	local peek_free_distance = peek_distance + 50
	local max_step = mvector3.distance(crouched_head_stance.translation, stance_standard.head.translation)
	local step = 10

	while true do
		mvector3.step(head_stance_translation, crouched_head_stance.translation, stance_standard.head.translation, step)
		mvector3.set(fdw_ray_from, head_stance_translation)
		mvector3.add(fdw_ray_from, m_pos)

		mvector3.set(fwd_ray_to, self._cam_fwd)
		mvector3.set_z(fwd_ray_to, 0)
		mvector3.set_length(fwd_ray_to, peek_free_distance)
		mvector3.add(fwd_ray_to, fdw_ray_from)

		fwd_ray = World:raycast("ray", fdw_ray_from, fwd_ray_to, "slot_mask", self._peek_slotmask, "sphere_cast_radius", 5)
		if not fwd_ray then
			break
		elseif step >= max_step then
			return
		else
			step = math.min(step + 15, max_step)
		end
	end

	if self._peek_active and self._peek_head_stance.translation == head_stance_translation then
		return
	end

	mvector3.set(self._peek_head_stance.translation, head_stance_translation)

	self._camera_unit:base():clbk_stance_entered(nil, self._peek_head_stance, nil, nil, nil, nil, 1, 0.2)

	if not self._peek_active then
		self._ext_network:send("action_change_pose", 1, self._unit:position())
		self._peek_active = true
	end
end)
