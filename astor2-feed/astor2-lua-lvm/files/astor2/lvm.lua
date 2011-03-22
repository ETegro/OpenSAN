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

M.physical_volume = {}

M.physical_volume.remove = function( disk )
	assert( is_disk( disk ) )
	common.system_succeed( "pvremove " .. disk )
end

M.physical_volume.rescan = function()
	common.system_succeed( "pvscan" )
end

M.volume_group = {}
M.physical_volume.remove = function( disk )
	assert( is_disk( disk ) )
	common.system_succeed( "vgremove " .. disk )
end

return M
