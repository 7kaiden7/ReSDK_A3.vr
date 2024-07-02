// ======================================================
// Copyright (c) 2017-2024 the ReSDK_A3 project
// sdk.relicta.ru
// ======================================================


#include "..\engine.hpp"
#include "..\oop.hpp"
#include "..\struct.hpp"
#include "..\ServerRpc\serverRpc.hpp"
#include "..\GameObjects\GameConstants.hpp"
#include "Atmos.hpp"
#include "Atmos.h"

/*
	List typedef(AtmosArea) 
		-> AtmosChunk 
			-> AtmosAreaBase

*/

struct(AtmosChunk)
	def(chCtr) 0; //chunk counter

	def(areaSR) null;//saferef to area
	def(chId) null;
	def(chNum) -1; //local chunk id
	def(chLPos) null; //local position in area 
	def(lastUpd) 0;
	def(getChunkCenterPos) {(self getv(chId)) call atmos_chunkIdToPos}
	def(getChunkZoneOffset) {self getv(chLPos)}
	def(getChunkAreaId) {(self getv(chId)) call atmos_chunkIdToAreaId}
	def(getArea)
	{
		self getv(areaSR) callv(getValue)
	}


	def(objInside) null; //gameobjects inside this chunk
	def(flagUpdObj) true;

	def(cfg) -1;//light config effector
	
	//atmos objects inside this chunk. Used for faster enumerate
	def(atmosList) null;
		def(aFire) null;
		def(aGas) null;
		def(aWater) null;

	def(hasFire) {!isNull(self getv(aFire))};
	def(hasGas) {!isNull(self getv(aGas))};
	def(hasWater) {!isNull(self getv(aWater))};

	def(updateLight)
	{
		if (self callv(hasFire) && {
			self getv(aFire) callv(isActive)
		}) exitWith {
			private _oldCfg = self getv(cfg);
			self setv(cfg,self getv(aFire) callv(getCfg));
			if (_oldCfg!=(self getv(cfg))) then {
				[self] call atmos_onUpdateAreaByChunk;
			};
		};
		if (self callv(hasGas) && {
			self getv(aGas) callv(isActive)
		}) exitWith {
			private _oldCfg = self getv(cfg);
			self setv(cfg,self getv(aGas) callv(getCfg));
			if (_oldCfg!=(self getv(cfg))) then {
				[self] call atmos_onUpdateAreaByChunk;
			};
		};

		self callv(_resetLightAndUpdate)
	}

	def(_resetLightAndUpdate)
	{
		private _oldCfg = self getv(cfg);
		self setv(cfg,-1); //no light founded
		if (_oldCfg!=(self getv(cfg))) then {
			[self] call atmos_onUpdateAreaByChunk;
		};
	}

	//generate packet for client
	def(getPacket)
	{
		[self getv(chNum),self getv(cfg)]
	}

	def(init)
	{
		params ["_chId"];
		
		self setv(objInside, []);
		self setv(atmosList,[]);

		self setv(chId,_chId);

		//setup local position and chunk localID
		self setv(chLPos,_chId call atmos_getLocalChunkIdInArea);
		self setv(chNum, (self getv(chLPos)) call atmos_encodeChId);

		self setv(chCtr,atmos_chunks_uniqIdx);
		INC(atmos_chunks_uniqIdx);

		INC(atmos_chunks);
	}
	
	def(del)
	{
		DEC(atmos_chunks);
	}

	def(registerArea)
	{
		params ["_aType","_fieldName","_aIdx"];
		private _p = [self getv(chId)];
		private _atr = [_aType,_p] call struct_alloc;
		self set [_fieldName,_atr];
		self getv(atmosList) set [_aIdx,_atr];

		self callv(updateLight); //first loading light

		_atr
	}

	def(unregisterArea)
	{
		params ["_fieldName","_aIdx"];
		//free references
		self set [_fieldName,null];
		self getv(atmosList) set [_aIdx,null];

		self callv(getArea) set [ATMOS_AREA_INDEX_LASTDELETE,tickTime];

		self callv(updateLight); //release atmos obj - update light
	}

	def(getObjectsInChunk)
	{
		if (self getv(flagUpdObj)) then {
			self setv(objInside,[self getv(chId)] call atmos_chunkGetNearObjects);
			self setv(flagUpdObj,false);
		};
		self getv(objInside);
	}

	def(str)
	{
		private _flags = "";
		if (self callv(hasFire)) then {
			modvar(_flags) + "F";
		};
		if (self callv(hasGas)) then {
			modvar(_flags) + "G";
		};
		if (self callv(hasWater)) then {
			modvar(_flags) + "W";
		};
		if (count _flags > 0) then {
			_flags = "<" + _flags + ">";
		};
		format["A%2Ch%1%3",self getv(chId),self callv(getChunkAreaId),_flags]
	}

	//запрос соседних чанков. генерирует новый объект чанка если не существует
	def(getChunkDown) {[self getv(chId) vectorAdd [0,0,-1]] call atmos_getChunkAtChId}
	def(getChunkUp) {[self getv(chId) vectorAdd [0,0,1]] call atmos_getChunkAtChId}
	def(getChunkFromSide)
	{
		params ["_side"];
		[self getv(chId) vectorAdd _side] call atmos_getChunkAtChId
	}

	def(getChunkUserInfo)
	{
		params ["_usr"];
		//! ВНИМАНИЕ. Похоже что exitWith возвращает null. Не знаю почему так происходит...
		if (self callv(hasFire)) then {
			private _f = self getv(aFire);
			(format ["%1 %2",
				pick["Тут вот","Ещё","Тут","А ещё"],
				pick["горит","пожар","загорелось","огонь хреначит"]
			]) editor_conditional(+ " size:" + (str (_f getv(size))) + "; force:"+(str (_f getv(force))),;);
		} else {
			""
		};
	};

endstruct

struct(AtmosAreaBase)
	def(getCfg) {-1} //interface for getting light cfg
	def(chunkId) null; //vec3 to chunk id
	def(getChunk) {[self getv(chunkId)] call atmos_getChunkAtChIdUnsafe}
	def(getChunkTo)
	{
		params ["_side"];
		[(self getv(chunkId))vectorAdd _side] call atmos_getChunkAtChId
	}

	def(c_spreadTimeout) 5;
	def(lastActivity) 0;

	def(canActivity) {tickTime > self getv(lastActivity)}
	def(isActive) {true} //по умолчанию. требуется переопределение
	
	//spread setup. constval, getting by ref
	def(c_spreadCountMin) 5
	def(c_spreadCountMax) 6
	def(c_spreadType) ATMOS_SPREAD_TYPE_NORMAL //тип распространения

	def(c_spreadSearchMode) ATMOS_SEARCH_MODE_FIRST_INTERSECT //режим поиска для возможности распространения

	def(onActivity) {
		self setv(lastActivity,tickTime + (self getv(c_spreadTimeout)));

		private _sides = [
			randInt(self getv(c_spreadCountMin),self getv(c_spreadCountMax)),
			self getv(c_spreadType)
		] call atmos_getNextRandAroundChunks;
		
		{
			if (self callp(canSpreadTo,_x)) then {
				self callp(onSpreadTo,_x);
			};
			false
		} count _sides;
	}

	def(canSpreadTo) {
		params ["_side"];
		[self getv(chunkId),_side,self getv(c_spreadSearchMode)] call atmos_getIntersectInfo;
	}

	def(onSpreadTo) {
		params ["_side"];
		private _makePos = self callp(getChunkTo,_side) callv(getChunkCenterPos);
		private _p = [_makePos,struct_typename(self)] call atmos_createProcess;
		_p
	}

	//вызывается при контакте объекта с этим типом атмоса
	def(onObjectContact) {params["_obj"]}
	//вызывается при контакте моба с этим типом атмоса
	//TODO продумать как лучше делать контакт по нескольким зонам
	def(onMobContact) {params["_mob"]}

	def(updateLight)
	{
		self callv(getChunk) callv(updateLight);
	}

	def(init)
	{
		params ["_chId"];
		self setv(chunkId,_chId);
		self setv(lastActivity,tickTime + (self getv(spreadTimeout)) + rand(1,3));

		INC(atmos_areas);
	}

	def(del)
	{
		DEC(atmos_areas);
	}

	//принудительное создание обрабатывает параметры указанные при создании
	def(onManualCreated)
	{
		//параметры могут быть динамическими
	}

	//вызывается при инициализации объекта. параметры динамические
	def(onInitialized)
	{

	}
	
	def(str)
	{
		format["%1<%2>",struct_typename(self),self getv(chunkId)]
	}

	def(getUnlinkStructInfo) {
		atmos_imap_process_t get struct_typename(self)
	}

	//release resource
	def(unlinkStruct)
	{
		(self callv(getUnlinkStructInfo)) params ["_memName","_idx"];
		self callv(getChunk) callp(unregisterArea,_memName arg _idx)
	}
endstruct

struct(AtmosAreaFire) base(AtmosAreaBase)
	def(force) 3; //default fire force
	def(size) 1;
	def(isActive) {self getv(force) > 0}
	def(hasFireDown) {
		private _ch = self callv(getChunk);
		private _chD = _ch callv(getChunkDown);
		_chD callv(hasFire);
	}
	def(init)
	{
		params ["_chId"];
	}

	def(getCfg)
	{
		self callv(getLightTypeBySize)
	}

	def(calcFireSize)
	{
		round linearConversion [1,15,self getv(force),1,3,true];
	}

	def(getLightTypeBySize)
	{
		[
			SLIGHT_ATMOS_FIRE_1,
			SLIGHT_ATMOS_FIRE_2,
			SLIGHT_ATMOS_FIRE_3
		] select ((self getv(size))-1)
	}

	def(onActivity)
	{
		callbase(onActivity);

		private _newForce = -1;

		self callp(adjustForce,_newForce);
		if (self callv(isActive)) then {
			//создаем дым
			private _gas = [
				self callv(getChunk) callv(getChunkCenterPos),
				"AtmosAreaGas",
				true,
				["GasBase",4 * (self getv(size))]
			] call atmos_createProcess;
			_gas callp(adjustGas,"GasBase" arg 1.0 * (self getv(size)) arg true);
		};
	}

	def(canSpreadTo)
	{
		params ["_side"];
		
		if (self getv(size)<=1) exitWith {false};
		if !(callbase(canSpreadTo)) exitWith {false};
		//check materials in next chunk
		private _nChunk = self callp(getChunkTo,_side);

		if (_nChunk callv(hasFire)) exitWith {false};
		private _matObj = nullPtr;
		private _found = false;
		{
			_matObj = callFunc(_x,getMaterial);
			if isNullReference(_matObj) then {continue};
			if prob(callFunc(_matObj,getFireDamageIgniteProb)) exitWith {
				_found = true;
			};
		} foreach (_nChunk callv(getObjectsInChunk));

		_found
	}

	def(onObjectContact)
	{
		params ["_obj"];
		if callFunc(_obj,canApplyDamage) then {
			private _m = callFunc(_obj,getMaterial);
			if isNullReference(_m) exitwith {};

			private _dam = floor (D6 * callFunc(_m,getFireDamageModifier));
			private _oldHP = getVar(_obj,hp);
			private _mpos = ifcheck(prob(30),callFunc(_obj,getModelPosition),null);
			callFuncParams(_obj,applyDamage,_dam arg DAMAGE_TYPE_BURN arg _mpos);
			if not_equals(_oldHP,getVar(_obj,hp)) then {
				self callp(adjustForce,2); //because decrement is 1
			};
		};
	}

	def(adjustForce)
	{
		params ["_force"];
		private _newForce = ((self getv(force))+_force) max 0 min 30;
		if !(self callv(hasFireDown)) then {
			if (_newForce > 3) then {
				//тут нечему гореть. совсем
				if (count (self callv(getChunk) callv(getObjectsInChunk)) == 0) then {
					_newForce = 0;
				};
			};
		};

		self setv(force,_newForce);
		private _size = self callv(calcFireSize);
		if (_size!=(self getv(size))) then {
			self setv(size,_size);
			self callv(updateLight);//size changed. request for updating light
		};

		if !(self callv(isActive)) then {
			self callv(unlinkStruct);
		};
	}
endstruct

struct(AtmosAreaGas) base(AtmosAreaBase)
	def(isActive) {self getv(volume) > 0}

	def(c_spreadCountMin) 3
	def(c_spreadCountMax) 4
	def(c_spreadType) ATMOS_SPREAD_TYPE_NO_Z //тип распространения

	def(c_spreadSearchMode) ATMOS_SEARCH_MODE_NO_INTERSECT

	def(gCont) null //контейнер газов
	def(volume) 0 //текущее количество
	def(leftVol) 1000 //оставшееся количество
	def(c_maxVolume) 1000 //макс количество
	def(leadingGas) null //лидирующий газ. отвечает за то какой будет визуал

	def(getCfg)
	{
		self getv(leadingGas) callv(getLightCfg)
	}

	def(init)
	{
		params ["_chId"];
		self setv(gCont,createHashMap);
	}

	def(onInitialized)
	{
		params ["_gas","_vol"];
		if !isNullVar(_gas) then {
			self callp(adjustGas,_gas arg _vol arg true);
		};
	}

	def(onActivity) {
		self setv(lastActivity,tickTime + (self getv(c_spreadTimeout)));

		if !(self callv(isActive)) exitWith {
			self callv(unlinkStruct);
		};

		self callp(removeVolume,0.1 arg true);

		private _sides = [
			randInt(self getv(c_spreadCountMin),self getv(c_spreadCountMax)),
			self getv(c_spreadType)
		] call atmos_getNextRandAroundChunks;

		_sides pushBack [0,0,1]; //up
		private _psides = [];
		{
			if (self callp(canSpreadTo,_x)) then {
				_psides pushBack _x;
			};
			false
		} count _sides;

		private _iterCnt = count _psides;
		if (_iterCnt==0) exitWith {};

		private _DIFF_RATE = 0.5;
		private _valPass = (self getv(volume)) * _DIFF_RATE;
		private _val = _valPass/_iterCnt;
		{
			self callp(onSpreadTo,_x arg _val);
			false
		} count _psides;
	}

	def(canSpreadTo)
	{
		params ["_side"];
		if (self getv(volume)<=0.5) exitWith {false};
		callbase(canSpreadTo)
	}

	def(onSpreadTo)
	{
		params ["_side","_transVal"];
		if ((self getv(volume))<=0)exitWith {};
		private _newGas = callbase(onSpreadTo);
		self callp(transferTo,_newGas arg _transVal);
	}

	// volume management

	def(updateLeadingGas)
	{
		private _ld = null;
		private _max = 0;
		private _cur = 0;

		{
			_cur = _y getv(volume);
			if (_cur > _max) then {
				_max = _cur;
				_ld = _y;
			};
		} foreach (self getv(gCont));

		if !isNullVar(_ld) then {
			self setv(leadingGas,_ld);
			self callv(updateLight);
		};
	}

	def(adjustGas)
	{
		params ["_gas","_vol",["_updateLead",false]];
		private _left = self getv(leftVol);
		_vol = _vol max 0 min _left;
		//_gas = tolower _gas;//! это не позволит создать структуру газа
		private _gc = self getv(gCont);
		//!здесь может возникнуть ошибка переполнения - фактический объем может стать меньше чем внутри газа
		if (_gas in _gc) then {
			private _gStruct = _gc get _gas;
			_gStruct setv(volume,(_gStruct getv(volume))+_vol);
		} else {
			private _gStruct = [_gas] call struct_alloc;
			_gc set [_gas,_gStruct];
			_gStruct setv(volume,_vol);
		};
		self setv(leftVol,(_left-_vol)max 0);
		self setv(volume,((self getv(volume)) + _vol) min (self getv(c_maxVolume)));

		if (_updateLead) then {
			self callv(updateLeadingGas);
		};

		true
	}

	def(removeGas)
	{
		params ["_gas","_vol",["_updateLead",false]];
		//_gas = tolower _gas;
		private _gc = self getv(gCont);
		if !(_gas in _gc) exitWith {false};
		private _gobj = _gc get _gas;
		private _newamount = (_gobj getv(volume)) - _vol;
		if (_newamount <= 0 || (_newamount toFixed 4) == "0.0000") then {
			_vol = _gobj getv(volume);
			_gc deleteAt _gas;
		} else {
			_gobj setv(volume,_newamount);
		};

		self setv(volume,((self getv(volume)) - _vol) max 0);
		self setv(leftVol,((self getv(leftVol)) +_vol) min (self getv(c_maxVolume)));
		
		if (_updateLead) then {
			self callv(updateLeadingGas);
		};

		true
	}

	def(addVolume)
	{
		params ["_v"];
	}

	def(removeVolume)
	{
		params ["_val",["_updateLead",false]];

		private _curvol = self getv(volume);
		if (_curvol<=0) exitWith {false};
		_val = _val max 0 min _curvol;
		private _gcmap = self getv(gCont);
		private _trEach = _val / _curvol;
		private _trans = 0;
		private _newamount = 0;
		private _newvol = 0;
		private _toDel = [];
		{
			_trans = (_y getv(volume)) * _trEach;
			_y setv(volume,(_y getv(volume)) - _trans);
			_newamount = _y getv(volume);
			//traceformat("trans %1(%3) new %2",_trans arg _newamount toFixed 4 arg _y);
			if (_newamount <= 0 || (_newamount toFixed 4) == "0.0000") then {
				_toDel pushBack _x;
				_newamount = 0;
			};

			modvar(_newvol) + _newamount;
		} foreach _gcmap;

		self setv(leftVol,(self getv(c_maxVolume)) - _newvol);
		self setv(volume,_newvol max 0);

		{
			_gcmap deleteAt _x;
		} foreach _toDel;

		if (_updateLead) then {
			self callv(updateLeadingGas);
		};

		true
	}

	def(transferTo)
	{
		params ["_toAreaGas","_vol",["_updateLead",false]];
		_vol = _vol max 0 min (self getv(volume));
		_vol = _vol max 0 min (_toAreaGas getv(leftVol));

		if (_vol==0) exitWith {false};

		private _gcFrom = self getv(gCont);
		private _trEach = _vol/(self getv(volume));
		private _trans = 0;
		{
			_trans = (_y getv(volume)) * _trEach;
			self callp(removeGas,_x arg _trans);
			_toAreaGas callp(adjustGas,_x arg _trans);
		} foreach +_gcFrom;

		if (_updateLead) then {
			self callv(updateLeadingGas);
			_toAreaGas callv(updateLeadingGas);
		};

		true
	}
	
	//метод пересчета текущего и оставшегося объема
	def(updateVolume)
	{
		private _vol = 0;
		{
			modvar(_vol) + (_x getv(volume));
		} foreach (self getv(gCont));
		self setv(volume,_vol);
		self setv(leftVol,(self getv(c_maxVolume)) - _vol);
		_vol
	}


endstruct

#include "Atmos_Gases.sqf"