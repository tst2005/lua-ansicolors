local split = require "mini.string.splitfilter"

local function split_line_to_args(line)
	local function dropempty(v, _t)
		if v=="" then return nil end
		return v
	end
	local r = {}
	for _i,v in ipairs( split(line, "%{", true)) do -- plain text search
		local tags, trailing = split(v, "}", true, 1, function(v) return v end) -- function(self, pat, plain, max, filter)
		assert(#tags == 1 or (#tags == 2 and trailing ~= ""))
		if not trailing then trailing = tags[2] end
		tags=tags[1]
		--local tags, trailing = v:match("^(.-)}(.*)$")
		if tags then
			-- Split the list using spaces, '+' or '_' separators
			table.insert(r, split(tags, "[+_%s]+", false, nil, dropempty))
		else
			trailing = v
		end
		if trailing then
			table.insert(r, trailing)
		end
	end
	return r
end

local function ansicolors(t_args, out)
	out = out or function(txt) io.stdout:write(txt) end

	local noerror=false
	local eval=true -- eval==true => evaluated value (ansi sequence)
			-- eval==false => the raw code to be evaluated (the quoted sequence)
	local usecolor=nil

	for _i, v in ipairs(t_args) do -- items : <string to print>|<table of tag(s)>
		local function process_tags(t_tags)
			local codes=''
			local bg=false; local hi=false			-- Background and High Intensity
			local fgc					-- Foreground color code
			local bgc					-- Background color code
			local s0, s1, s2, s3, s4, s5, s6, s7, s8 =	-- all Styles
			      "", "", "", "", "", "", "", "", ""

			local trailing=''
			for _i, tag in ipairs(t_tags) do -- %{BG_Red+Yellow} => tag=bg ; tag=red ; tag=yellow
				tag = tag:lower()

				local c=nil				-- tmp color code

				if tag=='' then
				elseif tag=='raw' then	eval=false
				elseif tag=='eval' then	eval=true

				elseif tag=='color=no' or tag=='color=never' then	usecolor=false
				elseif tag=='color=yes' or tag=='color=always' then	usecolor=true
				elseif tag=='color=auto' or tag=='color' then
					--TODO : [ -t 1 ] && printf='printf' || printf=':'
					error("NYI: color=auto")

				elseif tag=='noerror' then			noerror=true
				elseif tag=='error' then			noerror=false

				elseif tag=='bg' then				bg=true
				elseif tag=='hi' then				hi=true

				elseif tag=='black' then			c=30
				elseif tag=='red' then				c=31
				elseif tag=='green' then			c=32
				elseif tag=='yellow' then			c=33
				elseif tag=='blue' then				c=34
				elseif tag=='purple' then			c=35
				elseif tag=='cyan' then				c=36
				elseif tag=='white' then			c=37

			--	elseif tag=='none' then				exit 1
			--	elseif tag=='reset' then			codes='0'; break
				elseif tag=='-' or tag=='normal' then		s0="0" -- FIXME: in sh version remove the "" support
				elseif tag=='default' then			s0="0"
				elseif tag=='b' or tag=='bold' then		s1="1"
				elseif tag=='s1' then				s1="1"
				elseif tag=='s2' then				s2="2"
				elseif tag=='s3' then				s3="3"
				elseif tag=='u' or tag=='underline' then	s4="4"
				elseif tag=='s4' then				s4="4"
				elseif tag=='s5' then				s5="5"
				elseif tag=='s6' then				s6="6"
				elseif tag=='s7' then				s7="7"
				elseif tag=='s8' then				s8="8"
				elseif tag=='lf' or tag==[[\n]] then
					if eval then				trailing="\n"
					else					trailing=[[\n]]
					end
				elseif tag=='cr' or tag==[[\r]] then
					if eval then				trailing="\r"
					else					trailing=[[\r]]
					end
				elseif tag=='crlf' or tag==[[\r\n]] then
					if eval then				trailing="\r\n"
					else					trailing=[[\r\n]]
					end
				else
					if not noerror then
						error("ERROR: instruction not supported: "..tag)
					end
				end

				if c then
					-- Regular                   = color       [30-37]
					-- Background                = color+10    [40-47]
					-- High Intensity            = color+60    [90-97]
					-- Background High Intensity = color+60+10 [100-107]
					if hi then
						c=c + 60
					end
					if bg then
						bgc=c + 10
					else
						fgc=c
					end
					bg=false
					hi=false
					c=nil
				end

			end -- end of ipairs(t_tags)

			-- generate the ansi color sequence
			if codes == "" then	-- if codes exists use it as is (useful to force a returned code value)
				codes=table.concat( {
					s0, s1, s2, s3, s4, s5, s6, s7, s8,
					fgc and fgc or "", bgc and bgc or ""
				}, "")
				-- got something like '0;1;4;37;43'
			end
			if codes and codes ~= "" then
				if color~=false then
					if eval then -- eval
						out("\27[" .. codes .. 'm')
					else -- raw
						out( [[\033[]] .. codes .. 'm' )
					end
				else
					-- nothing or out("")
				end
			end
			if trailing then
				out(trailing)
			end
		end -- end of process_tags(t_tags)

		if type(v)=="string" then -- a string value, not a tag
			out(v)
		elseif type(v)=="table" then -- tags: the content of %{ ... }
			process_tags(v)
		else
			error("unknown case")
		end
	end -- end of ipairs(t_args)
end

local function ansicolors_line(line, out)
--[[
		case "$line" in
			('%{'*'}'*) ;;
			(*'%{'*)
				echo >&2 "unterminated color tag, missing '}' in $line"
				return 1
			;;
			("")	break ;;
			(*)
				set -- "$@" "$line"
				break
			;;
		esac
]]--
	local t_args = split_line_to_args(line)
	return ansicolors(t_args, out)
end

return {args=ansicolors, line=ansicolors_line}
