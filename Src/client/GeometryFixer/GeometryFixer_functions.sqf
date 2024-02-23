// ======================================================
// Copyright (c) 2017-2023 the ReSDK_A3 project
// sdk.relicta.ru
// ======================================================



gf_start = {
	if (gf_handle_update != -1) then {
		call gf_stop;
	};
	
	//first setting last positions to actual pos
	gf_lastPositions = gf_lastPositions apply {getPosATL player};
	
	gf_handle_update = startUpdate(gf_onUpdate,GEOMETRY_FIXER_UPDATE_DELAY);
};

gf_stop = {
	if (gf_handle_update != -1) then {
		stopUpdate(gf_handle_update);
		gf_isCatchedFalling = false;
		gf_isLockedInputByWall = false;
	};
};


gf_onUpdate = {
	
	private _curpos = getposatl player;
	#ifndef GEOMETRYFIXER_ROADWAY_DISABLED
	call gf_processRoadway;
	#endif
	
	#ifdef GEOMETRYFIXER_COLLISION_ALLOWED
	call gf_collisionProcess;
	#endif
	
	if (abs speed player > 0) then {
		
		call gf_processWallLock;
	};
	
	#ifndef GEOMETRYFIXER_GEOSAVER_DISABLED
	call gf_processGeometry;
	#endif
	
/*
	#ifdef GEOMETRY_FIXER_TRACE_POSITIONS
	_texCol = [
		[1,0.9,0],
		[1,0.5,0],
		[1,0.1,0]
	];
	{
		_ctc = _texCol select _forEachIndex;
		_x setposatl (gf_lastPositions select _forEachIndex);
		_x setObjectTexture [0,format["#(rgb,8,8,3)color(%1,%2,%3,1)",_ctc select 0,_ctc select 1,_ctc select 2]];
	} foreach gf_lastposArrows;
	gf_lbfpArrow setPosAtl gf_lastNormalPos;
	gf_lbfpArrow setObjectTexture [0,"#(rgb,8,8,3)color(0,0,1,1)"];
	#endif*/
};	

#ifdef GEOMETRYFIXER_GEOSAVER_DISABLED
gf_lastNormalPos = vec3(0,0,0);
#endif

#ifdef GEOMETRYFIXER_GEOSAVER_DISABLED
//функционал сломан и не поддерживатеся на данный момент
gf_processGeometry = {
	
	if (!isOnGround(player)) then {
		if (!gf_isCatchedFalling) then {
			gf_isCatchedFalling = true;
			gf_lastFallingTime = tickTime + GEOMETRY_FIXER_FALLING_TIMEOUT;
		};	
		
		if (tickTime >= gf_lastFallingTime) then {
			_distZ = (gf_lastNormalPos select 2) - (_curpos select 2);
			if ((abs _distZ) <= GEOMETRY_FIXER_DISTANCE_TO_RESET_POSITION) then {
				player setPosAtl getSavedPosAtIndex(0);
				//player setVelocity [0,0,0];
				//trace("RESET POS")
			};
		};
	} else {
		//trace("non ground")
		gf_lastNormalPos = _curpos;
		if (gf_isCatchedFalling) then {
			gf_isCatchedFalling = false;
			
			//after long falling reset all positions
			gf_lastPositions = gf_lastPositions apply {getPosATL player};
		};
		
		
		if ((_curpos distance getLastSavedPos()) >= GEOMETRY_FIXER_DISTANCE_SAVE_POSITION &&
			{getDistance(_curpos,getSavedPosAtIndex(1) >= GEOMETRY_FIXER_DISTANCE_SAVE_POSITION)} &&
			{getDistance(_curpos,getSavedPosAtIndex(0) >= GEOMETRY_FIXER_DISTANCE_SAVE_POSITION)}
		) then {
			gf_lastPositions deleteAt 0;
			gf_lastPositions pushBack _curpos;
		};
		
		if (abs speed player > 0) then {
			if (stance player == "PRONE" && ("_" in animationState player)) then {
				_p1 = player modelToWorld (player selectionPosition "spine3");
				_p2 = player modelToWorld (player selectionPosition "neck");
				
				#ifdef GEOMETRY_FIXER_TRACE_POSITIONS
				gf_proneFrom setPosATL _p1;
				gf_proneTo setPosATL _p2;
				gf_proneSafePos setposatl (player modelToWorld (player selectionPosition "spine1"));
				#endif
				
				_itsc = lineIntersectsSurfaces [ATLToASL _p1,ATLToASL _p2,
					player,
					objNull, 
					true, 
					1, 
					"GEOM", 
					"NONE"];
				
				if (count _itsc > 0) then {
					player setPosAtl getSavedPosAtIndex(0);
				};
			};
		};
		
	};
	
	/*if isInFallingAnimation(player) then {
		if (!gf_isCatchedFalling) then {
			gf_isCatchedFalling = true;
			gf_lastFallingTime = tickTime + GEOMETRY_FIXER_FALLING_TIMEOUT;
			gf_lastBufferedFallingPos = _curpos;
		};	
		if (tickTime >= gf_lastFallingTime) then {
			_distZ = (gf_lastBufferedFallingPos select 2) - (_curpos select 2);
			if ((abs _distZ) <= GEOMETRY_FIXER_DISTANCE_TO_RESET_POSITION) then {
				if (gf_indexLastPos == -1) exitWith {
					gf_indexLastPos = (count gf_lastPositions) - 1;
					error("gf::onUpdate() - Cant reset position. Index out of range");
				};	
				trace("gf::onUpdate() - Reset position")
				player setPosAtl getSavedPosAtIndex(gf_indexLastPos);
				player setVelocity [0,0,0];
				DEC(gf_indexLastPos);
			} else {
				gf_lastBufferedFallingPos = _curpos;
				trace("gf::onUpdate() - is falling")
			};
			
		};	
	} else {
		if (gf_isCatchedFalling) then {
			gf_isCatchedFalling = false;
			gf_indexLastPos = (count gf_lastPositions) - 1;
		} else {
			if ((_curpos distance getLastSavedPos()) >= GEOMETRY_FIXER_DISTANCE_SAVE_POSITION &&
				{getDistance(_curpos,getSavedPosAtIndex(1) >= GEOMETRY_FIXER_DISTANCE_SAVE_POSITION)} &&
				{getDistance(_curpos,getSavedPosAtIndex(0) >= GEOMETRY_FIXER_DISTANCE_SAVE_POSITION)}
			) then {
				gf_lastPositions deleteAt 0;
				gf_lastPositions pushBack _curpos;
			};
		};
	};*/
};
#endif
//GEOMETRYFIXER_GEOSAVER_DISABLED

gf_processRoadway = {
	_itsc = lineIntersectsSurfaces [ATLToASL _curpos,ATLToASL (_curpos vectoradd [0,0,-1000]),
		player,
		gf_objRoadway, 
		true, 
		1, 
		"GEOM", 
		"NONE"];
	if (count _itsc > 0) then {
		gf_objRoadway setposatl ASLToAtl((_itsc select 0 select 0)vectordiff[0,0,0.0223]);
		gf_objRoadway setobjectscale 0.18;
	};
};	

gf_lastPosWallLock = vec3(0,0,0);

gf_lastWallCrushingTime = 0;
#define LAST_WALL_CRUSH_DELAY 1

gf_processWallLock = {
	_headpos = player modelToWorldVisual (player selectionPosition "head");
	_headpos2 = player modelToWorldVisual (player selectionPosition "head" vectorAdd vec3(0,1.2,0));
	

	
	_itsc = lineIntersectsSurfaces [
		ATLToASL _headpos,
		ATLToASL _headpos2,
		player,
		objNull, 
		true, 
		1, 
		"GEOM", 
		"NONE"];
		
	#ifdef GEOMETRY_FIXER_TRACE_POSITIONS
	gf_campos setPosATL _headpos;
	if (count _itsc > 0) then {
		gf_camtarget setPosATL ASLToAtl(_itsc select 0 select 0);
	} else {
		gf_camtarget setPosATL _headpos2;
	};
	
	#endif
	/*
	player addEventHandler ["AnimStateChanged", {
  params ["", "_anim"];
  _speeds = ["stp", "wlk", "tac", "spr", "run", "eva"];
  _speedsStr = ["Stopped", "Walking", "Tactical", "Running", "Running", "Sprinting"];
  systemChat (_speedsStr select (_speeds find (_anim select [9,3])));
}]
*/
	if (count _itsc > 0) then {
		_dist = _headpos distance (ASLToATL(_itsc select 0 select 0));
		_curanm = animationState player;
		_issprint = "eva" in _curanm;
		_isrun = "spr" in _curanm || "run" in _curanm;
		if (_dist <= 0.6 && (_issprint /*|| _isrun*/)) then {
			gf_isLockedInputByWall = true;
			//do event head fucked
			if (tickTime >= gf_lastWallCrushingTime) then {
				gf_lastWallCrushingTime = tickTime + LAST_WALL_CRUSH_DELAY;
				rpcSendToServer("onCrushingToObject",[player]);
			};
		} else {
			gf_isLockedInputByWall = false;
			//gf_lastPosWallLock = getPosATLVisual player;
		};
		//traceformat("CAMDATA %1",_dist);
	} else {
		gf_isLockedInputByWall = false;
		//gf_lastPosWallLock = getPosATLVisual player;
	};
	
	
};

//процессор коллизии армовских мобов
//не самое оптимизированное решеие. нужно собрать через ближние объекты
gf_collisionProcess = {
	_dist = 0;
	_mindist = 100;
	_mindistobj = objNull;
	{
		_dist = _x distance player;
		if (_dist < 15) then {
			_x disableCollisionWith player;
		};
		if (_dist < _mindist && !isObjectHidden _x) then {_mindist = _dist; _mindistobj = _x};
	} foreach (smd_allInGameMobs-[player]);

	if !isNullReference(_mindistobj) then {
		/*
		if (_mindistobj call gf_cp_internal_isMovingTo) then {
			if (
				(player modelToWorldVisual (player selectionPosition "spine3")) distance
				(_mindistobj modelToWorldVisual (_mindistobj selectionPosition "spine3"))
				<= 0.5
			) then {
				//too near
				gf_isLockedInputByActor = true;
				//TODO check vector move direction and send crushing contact to server
			};
		} else {
			gf_isLockedInputByActor = false;
		};
		*/
	};
};

gf_cp_internal_isMovingTo = {
	private _targ = _this;
	if (true) exitwith {
		abs speed player > 0
	};
	
	private _v1 = vectorNormalized (velocity player);
	private _v2 = vectorDir _targ;
	//????
};