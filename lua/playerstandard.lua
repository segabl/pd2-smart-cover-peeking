local fdw_ray_from = Vector3()
local fwd_ray_to = Vector3()
local up_ray_from = Vector3()
local head_stance_translation = Vector3()

Hooks:PostHook(PlayerStandard, "init", "init_scp", function (self)
	self._peek_active = false
	self._peek_slotmask = managers.slot:get_mask("statics")
	self._peek_head_stance = {
		translation = Vector3(),
		rotation = Rotation()
	}
end)

Hooks:PostHook(PlayerStandard, "inventory_clbk_listener", "inventory_clbk_listener_scp", function (self)
	local weapon = self._ext_inventory:equipped_unit()
	self._weapon_is_saw = alive(weapon) and weapon:base():is_category("saw")
end)

function PlayerStandard:_chk_stop_peek()
	if not self._peek_active then
		return
	end

	self._peek_active = false

	self:_stance_entered()

	if self._state_data.ducking then
		self._ext_network:send("action_change_pose", 2, self._unit:position())
	end
end

Hooks:PostHook(PlayerStandard, "update", "update_scp", function (self)
	local started_steelsight = not self._was_steelsight and self._state_data.in_steelsight
	self._was_steelsight = self._state_data.in_steelsight

	if self._weapon_is_saw or not self._peek_head_stance or not self._state_data.ducking or not self._state_data.in_steelsight then
		return self:_chk_stop_peek()
	end

	local stance_standard = tweak_data.player.stances.default[managers.player:current_state()] or tweak_data.player.stances.default.standard
	local crouched_head_stance = tweak_data.player.stances.default.crouched.head
	local m_pos = self._unit:movement():m_pos()
	local peek_distance = SmartCoverPeeking.settings.trigger_distance + (self._peek_active and SmartCoverPeeking.settings.sticky_distance or 0)
	local step, step_size = 0, 0.1

	mvector3.set(up_ray_from, m_pos)
	mvector3.set_z(up_ray_from, m_pos.z + 25)

	while true do
		mvector3.lerp(head_stance_translation, crouched_head_stance.translation, stance_standard.head.translation, step)
		mvector3.set(fdw_ray_from, head_stance_translation)
		mvector3.add(fdw_ray_from, m_pos)

		if World:raycast("ray", up_ray_from, fdw_ray_from, "slot_mask", self._slotmask_gnd_ray, "sphere_cast_radius", 20, "report") then
			if self._peek_active then
				if not SmartCoverPeeking.settings.continuous_trigger and head_stance_translation.z < self._peek_head_stance.translation.z then
					return self:_chk_stop_peek()
				else
					break
				end
			else
				return
			end
		end

		mvector3.set(fwd_ray_to, self._cam_fwd)
		mvector3.set_z(fwd_ray_to, 0)
		mvector3.set_length(fwd_ray_to, peek_distance)
		mvector3.add(fwd_ray_to, fdw_ray_from)

		if not World:raycast("ray", fdw_ray_from, fwd_ray_to, "slot_mask", self._peek_slotmask, "sphere_cast_radius", 5, "report") then
			break
		elseif step < 1 then
			step = step + step_size
		else
			return
		end
	end

	if self._peek_active then
		if not SmartCoverPeeking.settings.continuous_trigger or self._peek_head_stance.translation == head_stance_translation then
			return
		end
	elseif step == 0 or not SmartCoverPeeking.settings.continuous_trigger and not started_steelsight then
		return
	end

	mvector3.set(self._peek_head_stance.translation, head_stance_translation)

	self._camera_unit:base():clbk_stance_entered(nil, self._peek_head_stance, nil, nil, nil, nil, 1, 1, 1, 0.2)

	if not self._peek_active then
		self._ext_network:send("action_change_pose", 1, self._unit:position())
		self._peek_active = true
	end
end)
