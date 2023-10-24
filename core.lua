--[[
MIT License

Copyright (c) 2023 Graham Ranson of Glitch Games Ltd

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]

--- Class creation.
local Utils = {}

--- Required libraries
local json = require( "json" )
local lfs = require( "lfs" )

-- Localised functions.
local pathForFile = system.pathForFile
local open = io.open
local close = io.close
local remove = os.remove
local encode = json.encode
local decode = json.decode
local getInfo = system.getInfo
local attributes = lfs.attributes
local gsub = string.gsub
local dir = lfs.dir
local upper = string.upper
local lower = string.lower
local format = string.format
local tRemove = table.remove
local floor = math.floor
local abs = math.abs
local sort = table.sort
local cachedRequire = require

function dirtree(dir)
	assert(dir and dir ~= "", "Please pass directory parameter")
	if string.sub(dir, -1) == "/" then
		dir=string.sub(dir, 1, -2)
	end

	local function yieldtree(dir)
		for entry in lfs.dir(dir) do
			if entry ~= "." and entry ~= ".." then
				entry=dir.."/"..entry
				local attr=lfs.attributes(entry)
				coroutine.yield(entry,attr)
				if attr.mode == "directory" then
					yieldtree(entry)
				end
			end
		end
	end

	return coroutine.wrap(function() yieldtree(dir) end)
end

-- Localised values
local ResourceDirectory = system.ResourceDirectory
local DocumentsDirectory = system.DocumentsDirectory
local dirSeperator = package.config:sub( 1, 1 )

function Utils:new( params )
	
	return self
	
end

--- Reads in a file from disk.
-- @param path The path to the file.
-- @param baseDir The directory that the file resides in. Optional, defaults to system.ResourceDirectory.
-- @return The contents of the file, or an empty string if the read failed.
function Utils:readInFile( path, baseDir )

	local path = pathForFile( path, baseDir or ResourceDirectory )

	if path then

		local file = open( path, "r" )
		local contents

		if file then

			contents = file:read( "*a" ) or ""

			close( file )

		end

		file = nil

		return contents

	end

end

--- Writes out a string to a file.
-- @param contents The string to write.
-- @param path The path to the file.
-- @param baseDir The directory that the file resides in. Optional, defaults to system.DocumentsDirectory.
-- @return True if the write succeeded, false otherwise.
function Utils:writeOutFile( contents, path, baseDir )

	-- Try to get the full path
	local fullPath = pathForFile( path, baseDir or DocumentsDirectory )

	-- Do we not have one?
	if not fullPath then

		-- Then create the base path and append our file to it
		fullPath = pathForFile( "", baseDir or DocumentsDirectory ) .. path

	end

	-- Do we definitely have a full path?
	if fullPath then

		-- Try to open the file
		local file, error = open( fullPath, "w" )

		-- Do we have one?
		if file then

			-- Write to it
			file:write( contents )

			-- Close it
			close( file )

			-- Nil it
			file = nil

			-- Return successful
			return true

		end

	end

	-- Oh dear
	return false

end

--- Deletes a file from disk.
-- @param path The path to the file.
-- @param baseDir The directory that the file resides in. Optional, defaults to system.DocumentsDirectory.
-- @return True if the file was deleted, false and a reason why otherwise.
function Utils:deleteFile( path, baseDir )
	return remove( pathForFile( path, baseDir or DocumentsDirectory ) )
end

--- Checks if a file exists.
-- @param path The path to the file.
-- @param baseDir The directory that the file should reside in. Optional, defaults to system.DocumentsDirectory.
-- @return True if it does, false otherwise.
function Utils:fileExists( path, baseDir )

	local path = pathForFile( path, baseDir or DocumentsDirectory )

	if not path then
		return false
	end

	if string.lower( getInfo( "platform" ) ) == "android" and path then

		local handle = open( path, "r" )

		if handle then

			close( handle )

			handle = nil

			return true

		end

		handle = nil

	end

	return attributes( path, "mode" ) == "file"

end

--- Decodes the contents of a file that has been encoded as json.
-- @param path The path to the file.
-- @param baseDir The directory that the file resides in. Optional, defaults to system.DocumentsDirectory.
-- @return The decoded file as a table.
function Utils:decodeJsonFile( path, baseDir )
	return self:jsonDecode( self:readInFile( path, baseDir ) )
end

--- Decodes a table into json and saves it out.
-- @param table The table to encode.
-- @param path The path to the file.
-- @param baseDir The directory that the file resides in. Optional, defaults to system.DocumentsDirectory.
function Utils:jsonEncodeFile( table, path, baseDir )
	self:writeOutFile( self:jsonEncode( table ), path, baseDir )
end

--- Encodes a table into a Json string.
-- @param table The table to encode.
-- @return The encoded string.
function Utils:jsonEncode( table )
	return encode( table )
end

--- Decodes a Json string into a table.
-- @param string The string to decode.
-- @return The decoded table.
function Utils:jsonDecode( string )
	return decode( string or "" )
end

--- Counts the number of words in a string.
-- @param string The string to check.
-- @return The count.
function Utils:countWords( string )
	local _, n = string:gsub( "%S+", "" )
	return n
end

--- Removes all whitespace from a string.
-- @param string The string to remove the whitespace from.
-- @return The edited string.
function Utils:removeWhitespace( string )
	return string:gsub( "%s+", "" )
end

--- Trims all leading and trailing whitespace from a string.
-- @param string The string to trim the whitespace from.
-- @return The edited string.
function Utils:trimWhitespace( string )
	return string:match'^%s*(.*%S)' or ''
end

--- Checks if a table contains a value.
-- @param table The table to check.
-- @param value The value to look for.
-- @return True if it does, false otherwise.
function Utils:tableContains( table, value )

	if table then
		if #table > 0 then
			for i = 1, #table, 1 do
				if table[ i ] == value then
					return true, i
				end
			end
		else
			for _, v in pairs( table ) do
				if v == value then
					return true
				end
			end
		end
	end

	return false

end

--- Finds the value from a table that's nearest to another.
-- @param table The table to look through.
-- @param value The origin to check using.
-- @return The index of the nearest value.
function Utils:findNearestValue( table, value )

	local valueIndex = nil
	local distance, closestDistance = nil

	for i = 1, #table, 1 do
		distance = abs( value - table[ i ] )
		if not closestDistance or distance < closestDistance then
			closestDistance = distance
			valueIndex = i
		end
	end

	return valueIndex

end

--- Counts the number of elements in a table.
-- @param table The table to check.
-- @return The count.
function Utils:countTable( table )

	local count = 0

	for _, _ in pairs( table ) do
		count = count + 1
	end

	return count

end

--- Splits a string based on a separator character.
-- @param str The string to split.
-- @param separator The character to split on.
-- @return Table containing the separated strings.
function Utils:splitString( str, separator )
	if str and type( str ) == "string" then
		local separator, fields = separator or ":", {}
		local pattern = format( "([^%s]+)", separator )
		str:gsub( pattern, function( c ) fields[ #fields + 1 ] = c end )
		return fields
	end
end

--- Capitalises the first letter of a string.
-- @param str The string to edit.
-- @return The edited string.
function Utils:capitaliseFirstLetter( str )
	return ( str:gsub( "^%l", upper ) )
end

--- Decapitalises the first letter of a string.
-- @param str The string to edit.
-- @return The edited string.
function Utils:decapitaliseFirstLetter( str )
	return str:sub(1,1):lower()..str:sub(2)
end

--- Splits a camelCase string. Borrowed from here - https://love2d.org/forums/viewtopic.php?t=81128
-- @param str The string to split.
-- @return The split string.
function Utils:splitCamelCase( str )

	local function split(char)
		return " " .. char
	end

	return ( str:gsub( "[A-Z]", split ):gsub( "^.", upper ) )

end

--- Converts a string to camelCase.
-- @param str The string to convert.
-- @return The converted string.
function Utils:toCamelCase( str )

	str = self:removeWhitespace( str )
	str = self:decapitaliseFirstLetter( str )

	return str

end

--- Removes all special characters from a string.
-- @param str The string to work on.
-- @return The fixed string.
function Utils:removeSpecialChars( str )
	return str:gsub( '[%p%c%s]', '' )
end

--- Converts a file from one location to another.
-- @param pathA The current path of the file.
-- @param pathB The new path of the file.
-- @return True if the copy was successful.
function Utils:copyFile( pathA, pathB )

	if pathA and pathB then

		local fileA = open( pathA, "rb" )
		local fileB = open( pathB, "wb" )

		local fileASize, fileBSize = 0, 0
			if not fileA or not fileB then
				return false
			end
		while true do
			local block = fileA:read( 2^13 )
			if not block then
				fileASize = fileA:seek( "end" )
				break
			end
			fileB:write( block )
		end

		fileA:close()
		fileBSize = fileB:seek( "end" )
		fileB:close()

		return fileBSize == fileASize

	end

end


--- Replaces special characters in a string with something else.
-- @param str The string to edit.
-- @param what The character to swap out.
-- @param with The character to swap in.
-- @return The edited string.
function Utils:replaceSpecialCharactersInString( str, what, with )
	what = gsub( what, "[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%1" ) -- escape pattern
	with = gsub( with, "[%%]", "%%%%" ) -- escape replacement
	return str and type( str ) == "string" and gsub( str, what, with )
end

--- Extracts a filename from a path.
-- @param path The path to use.
-- @return The extracted filename.
function Utils:getFilenameFromPath( path )

	local splitPath = self:splitString( path, "/" )

	return splitPath and splitPath[ #splitPath ]

end

--- Removes a filename from a path string.
-- @param path The path to use.
-- @return New path without the filename.
function Utils:removeFilenameFromPath( path )

	local splitPath = self:splitString( path, "/" )

	return splitPath[ 1 ]

end

--- Extracts an extension from a filename.
-- @param filename The filename to use.
-- @return The extracted extension.
function Utils:getExtensionFromFilename( filename )

	local splitFilename = {}
	local pattern = format("([^%s]+)", ".")
	filename:gsub( pattern, function( c ) splitFilename[ #splitFilename + 1 ] = c end )

	return splitFilename[ 2 ]

end

--- Extracts the file from a filename.
-- @param filename The filename to use.
-- @return The extracted file.
function Utils:getFileFromFilename( filename )

	local splitFilename = {}
	local pattern = format("([^%s]+)", ".")
	filename:gsub( pattern, function( c ) splitFilename[ #splitFilename + 1 ] = c end )

	return splitFilename[ 1 ]

end

--- Gets the directory separator for the current platform.
-- @return The separator,
function Utils:getDirSeperator()
	return dirSeperator
end

--- Gets a list of all files in a path, including its sub directories.
-- @param path The path to search.
-- @return A list of file paths.
function Utils:listFiles( path, files )

	-- Table for the files
	local files = {}

	path = pathForFile( path, ResourceDirectory )

	if path then

		-- Loop though each file in the directory
		for filename, attr in dirtree( path ) do

			-- Is this entry a file?
			if attr.mode == "file" then

				-- Add it to the list
				files[ #files + 1 ] = filename

			end

		end

	end

	-- And return the files
	return files

end

function Utils:dirTree( path )

	assert(dir and dir ~= "", "Please pass directory parameter")
	if string.sub(dir, -1) == "/" then
		dir=string.sub(dir, 1, -2)
	end

	local function yieldtree(dir)
		for entry in lfs.dir(dir) do
			if entry ~= "." and entry ~= ".." then
				entry=dir.."/"..entry
				local attr=lfs.attributes(entry)
				coroutine.yield(entry,attr)
				if attr.mode == "directory" then
					yieldtree(entry)
				end
			end
		end
	end

	return coroutine.wrap(function() yieldtree(dir) end)

end

--- Reverses a table.
-- @param table The table to reverse.
-- @return The reversed table.
function Utils:reverseTable( table )
	for i = 1, floor( #table / 2 ) do
		table[ i ], table[ #table - i + 1 ] = table[ #table - i + 1 ], table[ i ]
	end
	return table
end

--- Shuffles a table.
-- @param table The table to shuffle.
-- @return The shuffled table.
function Utils:shuffleTable( table )

	local j

	for i = #table, 2, -1 do
		j = random( i )
		table[ i ], table[ j ] = table[ j ], table[ i ]
	end

	return table

end

--- Sorts a in descending order table.
-- @param table The table to sort.
-- @return The sorted table.
function Utils:sortTable( table )
	sort( table, function( a, b ) return a and b and tonumber( a ) > tonumber( b ) end )
	return table
end

--- Checks if a string is only alphanumeric.
-- @param str The string to check.
-- @return True if it is, false otherwise.
function Utils:isAlphaNumeric( str )
	return not str:match("%W")
end

--- Scans a directory recursively for all files and then stores them out into a list with the filename, full path, and a automatic name built from the path.
-- @param path The path to scan.
-- @return The list of files and names.
function Utils:convertPathsToNames( path )

	-- Store out the original path
	local originalPath = path

	-- Get the dir separator for this platform
	local dirSeperator = self:getDirSeperator()

	-- Get the files in our directory
	local files = self:listFiles( path )

	-- Loop through the files
	for i = #files, 1, -1 do

		-- Removing the game/audio part from the path
		local path = gsub( files[ i ], path .. dirSeperator, "" )

		-- Remove the original path from the new path
		path = gsub( path, pathForFile( originalPath, ResourceDirectory ), "" )

		-- Get the filename, making sure to deal with hyphens
		local filename = self:replaceSpecialCharactersInString( self:getFilenameFromPath( path ), "-", "%-" )

		-- Remove the filename from the path
		path = gsub( path, filename, "" )

		-- Get the sound type
		local type = self:splitString( path, dirSeperator )[ 1 ]

		-- Make sure we have a valid file
		if path ~= "" and type and filename ~= ".DS_Store" then

			-- Get the filename without the extension
			local name = self:getFileFromFilename( filename )

			-- Get the localised path
			local dirPath = gsub( path, type .. dirSeperator, "" )

			-- Swap out slashes for hyphens
			dirPath = gsub( dirPath, "/", "-" )
			dirPath = gsub( dirPath, "\\", "-" )

			-- Create the new name for the sound
			name = dirPath .. name

			-- Store out the path, filename, and name
			files[ i ] = { path = files[ i ], filename = filename, name = name }

		-- Otherwise
		else

			-- Remove this from the list
			tRemove( files, i )

		end

	end

	-- Return the list of files and names etc
	return files

end

--- Drags a display object.
-- @param object The display object to drag.
-- @param event The touch event.
function Utils:dragObject( object, event )

	if event.phase == "began" then

		object._x0 = object.x
		object._y0 = object.y

		event.target.isFocus = true
		display.getCurrentStage():setFocus( event.target, event.id )

	elseif event.target.isFocus then

		if event.phase == "moved" then

			local x = ( event.x - ( event.xStart or 0 ) ) + ( object._x0 or 0 )
			local y = ( event.y - ( event.yStart or 0 ) ) + ( object._y0 or 0 )

			object.x, object.y = x, y

		else

			event.target.isFocus = false
			display.getCurrentStage():setFocus( nil, event.id )

		end

	end

	return true

end

--- Try to load a module, but in a safe manner so it won't explode if the module doesn't exist.
-- @param path The path to the module.
-- @param code The loaded module.
function Utils:require( path )

	-- pre-declare the loaded code
	local code

	-- do a protected call to make sure the code/plugin exists
	local success, err = pcall( cachedRequire, path )

	-- if it was a success the code must exist
	if success then
		code = cachedRequire( path )
	end

	-- return the loaded module
	return code

end

--- Unload a module.
-- @param path The path to the module.
function Utils:unrequire( path )

	-- Make sure we have a path
	if path then

		-- Remove it from the loaded modules space
		package.loaded[ path ] = nil

		-- And the global space
		_G[ path ] = nil

	end

end

return Utils
