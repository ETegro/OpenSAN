--[[
  aStor2 -- storage area network configurable via Web-interface
  Copyright (C) 2009-2011 ETegro Technologies, PLC
                          Sergey Matveev <stargrave@stargrave.org>
  
  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as
  published by the Free Software Foundation, either version 3 of the
  License, or (at your option) any later version.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.
  
  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

local M = {}

local common = require( "astor2.common" )

local function is_disk( disk )
	assert( disk and common.is_string( disk ) )
	local dev_exists = string.match( disk, "^/dev/[^/]+$" )
	if not dev_exists then return false end
	return true
end

M.prepare_disk = function( disk )
	assert( is_disk( disk ) )
	common.system_succeed( "dd if=/dev/zero of=" .. disk .. " bs=512 count=1" )
	common.system_succeed( "pvcreate " .. disk )
end

--------------------------------------------------------------------------
-- PhysicalVolume
--------------------------------------------------------------------------
M.PhysicalVolume = {}

M.PhysicalVolume.remove = function( disk )
	assert( is_disk( disk ) )
	common.system_succeed( "pvremove " .. disk )
end

M.PhysicalVolume.rescan = function()
	common.system_succeed( "pvscan" )
end

M.PhysicalVolume.list = function()
	local lines = common.system_succeed( "pvdisplay -c" )
	local physical_volumes = {}
	for _, line in ipairs( lines ) do
		if string.match( line, ":.*:.*:.*:" ) then
		--   /dev/sda5:build:485822464:-1:8:8:-1:4096:59304:0:59304:Ph8MnV-X6m3-h3Na-XI3L-H2N5-dVc7-ZU20Sy
		local device, capacity, volumes, extent, total, free, allocated = string.match( line, "^%s+([/%w]+):%w+:(%d+):[\-%d]+:%d+:%d+:([\-%d]+):(%d+):(%d+):(%d+):(%d+):[\-%w]+$" )
		extent = tonumber( extent )
		if extent == 0 then extent = 4096 end
		capacity = tonumber( capacity ) * 0.5
		total = tonumber( total ) * extent / 1024
		free = tonumber( free ) * extent / 1024
		allocated = tonumber( allocated ) * extent / 1024
		volumes = tonumber( volumes )
		capacity = capacity / 1024
		unusable = capacity % extent / 1024

		assert( common.is_number( total ) )
		assert( common.is_number( free ) )
		assert( common.is_number( allocated ) )
		assert( common.is_number( volumes ) )
		assert( common.is_number( capacity ) )
		assert( common.is_number( unusable ) )
		assert( common.is_number( extent ) )
		assert( is_disk( device ) )

		physical_volumes[ #physical_volumes + 1 ] = {
			total = total,
			free = free,
			allocated = allocated,
			volumes = volumes,
			capacity = capacity,
			unusable = unusable,
			extent = extent,
			device = device
		}
		end
	end
	return physical_volumes
end

--------------------------------------------------------------------------
-- VolumeGroup
--------------------------------------------------------------------------
M.VolumeGroup = {}

M.VolumeGroup.remove = function( disk )
	assert( is_disk( disk ) )
	common.system_succeed( "vgremove " .. disk )
end

--------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------
M.DM_MODULES = { "dm_mod", "dm_log", "dm_mirror", "dm_snapshot" }

local function load_modules()
	for _, dm_module in ipairs( M.DM_MODULES ) do
		common.system_succeed( "modprobe " .. dm_module )
	end
end

M.is_running = function()
	-- TODO: replace with sysfs
	for _, line in ipairs( common.system_succeed( "lsmod" ) ) do
		if string.match( line, "dm_mod" ) then
			return true
		end
	end
	return false
end

local function restore_lvm()
	common.system_succeed( "pvscan" )
	common.system_succeed( "vgscan --mknodes" )
	common.system_succeed( "vgchange -a y" )
	common.system_succeed( "lvscan" )
end

M.start = function()
	if M.is_running() then return end
	local succeeded, result = pcall( load_modules )
	if not succeeded then error( "lvm:start() failed" ) end
	restore_lvm()
end

return M
