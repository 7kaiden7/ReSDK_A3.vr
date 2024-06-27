// ======================================================
// Copyright (c) 2017-2024 the ReSDK_A3 project
// sdk.relicta.ru
// ======================================================
#include "NOEngineClient_NetAtmos.hpp"
#include "..\..\host\struct.hpp"

#define NOE_NETATMOS_UPDATE_DELAY 1

noe_client_nat_isEnabled = {noe_client_nat_handleUpdate != -1};
noe_client_nat_handleUpdate = -1;
/*
	key-AreaId
	value-AtmosAreaClient
*/
noe_client_nat_areas = createHashMap;
noe_client_nat_prevArea = null;

noe_client_nat_setEnabled = {
	params ["_mode"];
	if equals(_mode,call noe_client_nat_isEnabled) exitWith {false};

	if (_mode) then {
		noe_client_nat_handleUpdate = startUpdate(noe_client_nat_onUpdate,NOE_NETATMOS_UPDATE_DELAY);
	} else {
		stopUpdate(noe_client_nat_handleUpdate);
		noe_client_nat_handleUpdate = -1;
	};
	true;
};

//основной цикл обработки областей
noe_client_nat_onUpdate = {
	_mob = player;
	_arCenter = (getposatl _mob) call atmos_getAreaIdByPos;
	if isNull(noe_client_nat_prevArea) then {
		noe_client_nat_prevArea = _arCenter;
	};
	_prevCenter = noe_client_nat_prevArea;
	
	//update last area
	noe_client_nat_prevArea = _arCenter;
	
	_toLoad = [_arCenter] call atmos_getAroundAreas;
	_toUnload = [_prevCenter] call atmos_getAroundAreas;

	//отбраковка
	_idx = -1;
	{
		_idx = _toUnload find _x;
		if (_idx!=-1) then {
			_toUnload deleteAt _idx;
		};
	} foreach _toLoad;

	//выгрузка старых
	_aObj = null; //oftype AtmosAreaClient
	{
		_aObj = [_x] call noe_client_nat_getArea;
		if (_aObj getv(state) == NAT_LOADING_STATE_LOADED) then {
			[_aObj] call noe_client_nat_unloadArea;
		};
	} foreach _toUnload;

	//загружаем новые
	{
		_aObj = [_x] call noe_client_nat_getArea;
		if (_aObj getv(state) <= NAT_LOADING_STATE_NOT_LOADED) then {
			[_aObj] call noe_client_nat_requestLoad;
		};
	} foreach _toLoad;
};
//получение области. если область не создана - генерирует новую
noe_client_nat_getArea = {
	params ["_areaId"];
	private _key = str _areaId;
	if isNull(noe_client_nat_areas get _key) then {
		noe_client_nat_areas set [_key,["AtmosAreaClient",[_areaId]] call struct_alloc];
	};
	noe_client_nat_areas get _key
};

//запрос зоны на загрузку
noe_client_nat_requestLoad = {
	params ["_areaObj"];
	_areaObj setv(state,NAT_LOADING_STATE_AWAIT_RESPONE);
	private _packet = [
		clientOwner,
		_areaObj get "areaId",
		_areaObj get "lastUpd"
	];
	rpcSendToServer("salr",_packet);
};

//ответ от сервера
noe_client_nat_onLoadArea = {
	private _packet = _this;
	_aid = _packet select [0,3];
	_packet deleteRange [0,3];
	_upd = _packet deleteAt 0;
	assert_str((count _packet) % 2 == 0,"Packet must be even items count");

	_aObj = [_aid] call noe_client_nat_getArea;
	_aObj setv(state,NAT_LOADING_STATE_LOADING);

	_addList = [];
	_remList = [];
	if ([_packet,_addList,_remList] call noe_client_nat_decodePacket) then {
		[_aObj,_addList] call noe_client_nat_loadVisualArea;
		[_aObj,_remList] call noe_client_nat_deleteChunks;
		_aObj setv(state,NAT_LOADING_STATE_LOADED);
	} else {
		_aObj setv(state,NAT_LOADING_STATE_ERROR);
	};
};
rpcAdd("cuar",noe_client_nat_onLoadArea);

//декодирование пакета в массивы запросов
noe_client_nat_decodePacket = {
	params ["_buff","_addList","_remList"];
	private _buffLen = count _buff;
	if (_buffLen%2!=0) exitWith {
		errorformat("Error on decoding packet, size %1",_buffLen);
		false;
	};
	private _chIdLoc = -1;
	private _cmd = null;
	for "_i" from 0 to _buffLen-1 step 2 do {
		_chIdLoc = [_buff select _i] call atmos_decodeChId;
		_cmd = _buff select (_i+1);
		if (_cmd==-1) then {
			_remList pushBack _chIdLoc;
		} else {
			_addList pushBack [_chIdLoc,_cmd];
		};
	};

	true
};

noe_client_nat_loadVisualArea = {
	params ["_aObj","_arrChDat"];//_arrChDat<localChId,cmd_t>
	{
		_aObj call ["loadChunkEffect",_x];
	} foreach _arrChDat;
};

//выгрузка зоны. обращаю внимание, что проверка состояния загруженности должна производиться снаружи функции
noe_client_nat_unloadArea = {
	params ["_areaObj"];
	_areaObj setv(state,NAT_LOADING_STATE_NOT_LOADED);
	traceformat("Unloading area %1",_areaObj)
	//TODO unloading chunks in area
};

//-------------------------------------------
// atmos client extension 
//-------------------------------------------
#include "..\..\host\Atmos\Atmos_shared.sqf"
