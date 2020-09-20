declare('cargolist', {})

targetless = targetless or {}
targetless.api = targetless.api or {}
targetless.api.radarlock = targetless.api.radarlock or false
targetless.var = targetless.var or {}
targetless.var.scanlock = targetless.var.scanlock or false

cargolist.nodeid = ""
cargolist.version = "0.11"

cargolist.timer = Timer()
cargolist.timeout = 2000
cargolist.sortd = -1
cargolist.sortby = {"name", "distance", col = 2}

RegisterEvent(cargolist, 'CARGOLIST_TIMEOUT')

cargolist.sortitem = iup.button{ title = "distance", action = function(self)
			if cargolist.sortby.col == 1 then
				cargolist.sortby.col = 2
			elseif cargolist.sortby.col == 2 then
				cargolist.sortby.col = 1
			end
			cargolist.sortitem.title=cargolist.sortby[cargolist.sortby.col]
			iup.Refresh(cargolist.sortitem)
			cargolist.MatrixSortBy(cargolist.matrix, cargolist.sortby.col, cargolist.sortd)
	end
	}

cargolist.sortdir = iup.button{ title = "descending", action = function(self)
			if cargolist.sortd == -1 then
				cargolist.sortd = 1
				cargolist.sortdir.title = "descending"
			elseif cargolist.sortd == 1 then
				cargolist.sortd = -1
				cargolist.sortdir.title = "ascending"
			end
			iup.Refresh(cargolist.sortdir)
			cargolist.MatrixSortBy(cargolist.matrix, cargolist.sortby.col, cargolist.sortd)
	end
	}

cargolist.pattern = iup.text{
	size = "300x",
	padding = "50x50",
}

cargolist.status_bar = iup.label{
	title = '',
	expand = 'HORIZONTAL',
}

cargolist.matrix = iup.matrix{
	numcol=4,
	EXPAND='YES', 
	EDITABLE ='NO', 
	RESIZEMATRIX='YES',
	BGCOLOR='0 0 0 0*',
	click_cb = function(self, lin, col)
			cargolist.nodeid,cargolist.objectid = self[lin..':3'], self[lin..':4']
			radar.SetRadarSelection(cargolist.nodeid, cargolist.objectid)
	end
}

cargolist.matrix['0:1'] = 'Name'
cargolist.matrix['0:2'] = 'Distance'
cargolist.matrix['0:3'] = 'nodeid'
cargolist.matrix['0:4'] = 'objectid'

cargolist.matrix['WIDTH'..'3']='100'
cargolist.matrix['WIDTH'..'4']='100'

local close = iup.stationbutton{
	title = 'Close',
	action = function(self)
		cargolist.dialog:hide()
	end,
}

cargolist.refresh = iup.stationbutton{
	title='refresh',
	bgcolor = "0 127 0",
}

cargolist.dialog = iup.dialog{
	iup.stationhighopacityframe{
		iup.stationhighopacityframebg{
			iup.vbox{
				iup.hbox{
					iup.vbox{
						iup.label{title = "Search Phrase"},
						cargolist.pattern,
					alignment = "ACENTER",
					gap = "15",
					},
					iup.vbox{
						iup.label{title = "Sort By"},
						iup.frame{
							cargolist.sortitem,
						title="Sort By",
						},
					alignment = 'ACENTER',
					},
					iup.vbox{
						iup.label{title = "Direction"},
						iup.frame{
							cargolist.sortdir,
						title="Sort Direction",
						},
					alignment = 'ACENTER',
					},
				},
				cargolist.matrix,
				iup.hbox{
					cargolist.refresh,
					cargolist.status_bar,
					close,
				},
			},
		},
	},
	title = 'cargolist v'..cargolist.version,
	MENUBOX = 'YES', 
	BORDER = 'YES',
	TOPMOST = 'YES',
	RESIZE = 'YES',
	EXPAND = 'YES',
--	size = 'QUARTERxHALF',
	bgcolor = '0 0 0',
	defaultesc = close,
}

function cargolist.clearmatrix(matrix)
	if matrix.NUMLIN then
		for i = 1,tonumber(matrix.NUMLIN) do
			matrix.DELLIN = 1
		end
	end
end

function cargolist.scan(data)
	cargolist.nodeid = ""
	cargolist.objectid = ""
	cargolist.firstobjid = ""
	cargolist.refresh.bgcolor = "0 127 0"
	iup.Refresh(cargolist.dialog)
	cargolist.timer:SetTimeout(cargolist.timeout, function() cargolist.timerdone(data) end)
	gkinterface.GKProcessCommand("RadarNone")
	if not data then
		data = {}
		cargolist.clearmatrix(cargolist.matrix)
		cargolist.status_bar.title = '...Updating'
		iup.Refresh(cargolist.dialog)
	end
	if cargolist.targetless > 2 then
		if not targetless.api.radarlock then
			targetless.api.radarlock = true
			cargolist.resettl = true
		end
		if targetless.Controller.autox then
			if targetless.Controller.autox == 'autoxactive' then
				targetless.Controller.autox = 'autoxoff'
			end
		end
	end
	repeat
	if cargolist.objectid then
		if cargolist.firstobjid == "" then
			cargolist.firstobjid = cargolist.objectid
		end
	end
	gkinterface.GKProcessCommand'RadarNext'
	cargolist.nodeid,cargolist.objectid = radar.GetRadarSelectionID()
	local name, _, dist = GetTargetInfo()

	if name then
		if name:find('cu)', nil, true) then
			local x = "false"
			if cargolist.pattern.value == ("" or nil) then x = "true"
			else 
				for w in string.gmatch(string.lower(cargolist.pattern.value), "%a+") do
					if string.lower(name):find(w, nil, true) then
						x = "true"
					end
				end
			end
			if x == "true" then
				local line = {name, string.format('%.0f', dist), cargolist.nodeid, cargolist.objectid}
				table.insert(data, line)
				cargolist.matrix.addlin = 1
				local lin_i = cargolist.matrix.numlin
				for col_i, col_v in ipairs(line) do
					cargolist.matrix[lin_i..':'.. col_i] = line[col_i]
				end
			end
		end
	else
		cargolist.status_bar.title = ''
		iup.Refresh(cargolist.dialog)
		cargolist.timer:Kill()
		cargolist.objectid = cargolist.firstobjid
	end
	until cargolist.objectid == cargolist.firstobjid
	if cargolist.resettl then
		targetless.api.radarlock = false
	end
	cargolist.MatrixSortBy(cargolist.matrix,2,-1)
end

cargolist.refresh.action=function()
	cargolist.scan() 
	cargolist.MatrixSortBy(cargolist.matrix, cargolist.sortby.col, cargolist.sortd)
	end
cargolist.dialog:map()

function cargolist.timerdone (data)
	ProcessEvent('CARGOLIST_TIMEOUT', data)
end

function cargolist:CARGOLIST_TIMEOUT(event, data)
	cargolist.status_bar.title = 'TIMEOUT'
	cargolist.refresh.bgcolor = "127 0 0"
	iup.Refresh(cargolist.dialog)
	cargolist.firstobjid = cargolist.objectid
end

function cargolist.cmd(data, args)
	if cargolist.dialog.visible == 'YES' then
		HideDialog(cargolist.dialog)
	else
		if args then
			if string.sub(args[1],1,3) == "ref" then-- auto refresh
				cargolist.scan() 
				cargolist.MatrixSortBy(cargolist.matrix, cargolist.sortby.col, cargolist.sortd)
				cargolist.nodeid,cargolist.objectid = cargolist.matrix['1:3'], cargolist.matrix['1:4']
				radar.SetRadarSelection(cargolist.nodeid, cargolist.objectid)
                PopupDialog(cargolist.dialog, iup.CENTER, iup.TOP)
			end
		else
			PopupDialog(cargolist.dialog, iup.CENTER, iup.TOP)
		end
	end
end

RegisterUserCommand('cl', cargolist.cmd)

-- sort function by blacknet aka Moda Messolus
function cargolist.MatrixSortBy(iMatrix, col, SORTD)
	local MAXCOLS = iMatrix.NUMCOL -1	-- number of columns in the matrix
	local MAXLINES = iMatrix.NUMLIN
	local TBLSorted = {} -- full sorted table
	local TMPTable = {} -- tmp table
	local linecount, CELLCOUNT

	--fill sorting table with sorting column
	--TBLSorted data forat is "foo ID: linenumber"
	--where foo is the data and linenumber is the matrix linenumber.
	for linecount = 1,MAXLINES do
		local MatrixCell = tostring(linecount..':'..col)
		table.insert(TBLSorted,iMatrix[MatrixCell]..' ID:'..linecount)
	end -- end fill sorting table

	--sort the new table
	table.sort(TBLSorted, function(a,b)

		-- strip the line number
		local TestA = string.gsub(string.gsub(a," ID:.*",""),',','') 
		local TestB = string.gsub(string.gsub(b," ID:.*",""),',','')
		
		-- strnatcasecmp(a,b) = -1 == left smaller
		-- strnatcasecmp(b,a) = +1 == right smaller
		-- strnatcasecmp(b,b) = 0  == equals
		local test = gkmisc.strnatcasecmp(TestA,TestB)
		if test == SORTD then return true
		else return false
		end -- if test
	end ) -- end table.sort


	-- dumps sorted data into temp table
	for linecount = 1,#TBLSorted do
		--every line dump col 1 to MAX into the sorted table
		for CELLCOUNT = 1, MAXCOLS do -- 0 based NUMCOL.
			local CellPOS = linecount..':'..CELLCOUNT -- i.e. "1:2"
			table.insert(TMPTable,iMatrix[CellPOS])
		end -- cellcount iteration
	end -- end sorted data dump
	
	--purge the matrix
	for i=1,iMatrix.NUMLIN do iMatrix.DELLIN=1 end

	--fill the matrix from sorted table
	for cellcount = 1,#TBLSorted do
		local ID = string.gsub(TBLSorted[cellcount],".* ID:","") -- line number
		local num = iMatrix.NUMLIN
		iup.SetAttribute(iMatrix,'ADDLIN',num+1) -- add a new line		
		for CELLCOUNT = 1, MAXCOLS do ---all the cells in line X
			iMatrix[(num+1)..':'..CELLCOUNT]=
				TMPTable[(MAXCOLS*tonumber(ID))-(MAXCOLS-CELLCOUNT)]
		end -- cellcount iteration
	end -- end sorted data matrix fill
	-- iMatrix:enteritem_cb(1,0)
--	iMatrix:click_cb(1,0) --set line focus to line 1
		cargolist.matrix['WIDTH'..'3']='100'
		cargolist.matrix['WIDTH'..'4']='100'
end

function cargolist:OnEvent(event, data)
	if event == "PLAYER_ENTERED_GAME" then
		print("cargolist v"..cargolist.version.." /cl")
	elseif event == "PLUGINS_LOADED" then
		cargolist.targetless = 0
		for i,v in pairs(targetless) do
			cargolist.targetless = cargolist.targetless + 1
		end
	end
end

RegisterEvent(cargolist, "PLUGINS_LOADED")
RegisterEvent(cargolist, "PLAYER_ENTERED_GAME")
