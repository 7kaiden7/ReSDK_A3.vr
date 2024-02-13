// ======================================================
// Copyright (c) 2017-2023 the ReSDK_A3 project
// sdk.relicta.ru
// ======================================================

/*
	Этот файл компилируется в редакторе и отладочной сборке в самую первую очередь
	и используется для условной компиляции в объектной системе

	Избыточные проверки внутри кода исключены из соображений производительности
*/
#include <engine.hpp>

/* ------------------------------------------------------
	Region: generic class info
------------------------------------------------------ */
pc_oop_classBegin = {
	// params ["_className","_definedIn"];
	// _decl_info___ = _definedIn;
	// __testSyntaxClass
	// _class = _className; _mother = "object";
	// p_table_allclassnames pushback _class;
	// private _fields = []; 
	// private _methods = []; 
	// private _attributes = []; 
	// private _autoref = [];
	// private _editor_attrs_cls = [];
	// call pc_oop_declareClassAttr;
	// _editor_next_attr = []; _editor_attrs_f = []; _editor_attrs_m = []; \
	// _classmet_declinfo = createHashMap; \
	// missionNamespace setVariable ["pt_"+_class,createObj]; private _pt_obj = missionNamespace getVariable ("pt_"+_class);

};

pc_oop_regClassTable = {
	params ["_class"];
	p_table_allclassnames pushback _class;
};

pc_oop_newTypeObj = {
	params ["_class"];
	private _obj = createObj;
	missionNamespace setVariable ["pt_"+_class,_obj];
	_obj
};

//функция декларатор атрибутов класса
pc_oop_declareClassAttr = {
	if (isnil '_editor_next_attr') exitwith {};

	if (count _editor_next_attr > 0) then {
		_editor_attrs_cls append _editor_next_attr;
		_editor_next_attr = [];
	};
};

//декларатор конца класса
pc_oop_declareEOC = {
	if (is3DEN) then {
		_pt_obj setvariable ["__decl_info_end__",_this];
	};

	p_table_inheritance pushback [_class,_mother];
	_pt_obj setName format[pc_oop_carr_tntps select is3DEN,_class];
	_pt_obj setvariable ['__fields',_fields];
	_pt_obj setvariable ['__methods',_methods];
	_pt_obj setvariable ['__motherClass',_mother];
	_pt_obj setVariable ['__motherObject',nullPtr];
	_pt_obj setVariable ['__childList',[]];
	_pt_obj setVariable ['__inhlistCase',[]];
	_pt_obj setvariable ['__inhlist',[]];
	_pt_obj setvariable ['__instances',0];
	_pt_obj setvariable ["classname",_class];
	_pt_obj setvariable ["__attributes",_attributes];
	_pt_obj setvariable ["__autoref",_autoref];
	_pt_obj setvariable ["__decl_info__",_decl_info___];
	call pc_oop_declareMemAttrs;

	call pc_oop_postInitClass;
};

//константные типы объектов. 0 - обычные называния типов, 1 - названия в редакторе
pc_oop_carr_tntps = ["<Type::%1>","<EDITOR_Type::%1>"];

//функция привязки атрибутов к типу
pc_oop_declareMemAttrs = {
	if (is3DEN) then {
		_pt_obj setVariable ["__ed_attr_class",_editor_attrs_cls];
		_pt_obj setVariable ["__ed_attr_fields",_editor_attrs_f];
		_pt_obj setVariable ["__ed_attr_methods",_editor_attrs_m];
	};
};

//завершающая иницализация класса.
pc_oop_postInitClass = {

	if (is3DEN) then {
		_class = nil;
	} else {
		{
			_x params ["_name","_code"]; 
			
			__sc = toString _code;

			//в редакторе для видимости методов при помощи отладчика добавляем информацию о методах в тело функций
			#ifdef EDITOR
				__sc = (format["private ___fn___ = ""%1::%2"";private ___fd___ = ""%3"";",_class,_name,_classmet_declinfo get _name]) + __sc;
			#endif

			if ("__BASECALLFLAG__" in __sc) then {
				_methods set [_forEachIndex,
					[
						_name,
						compile([
							__sc,
							"__BASECALLFLAG__",
							format["call(pt_%1 getVariable '%2')",_mother,_name]
						] call regex_replace)
					]
				];
			} else {
				//просто компилируем код со встроенной информации о члене (где нет ключевого слова super)
				#ifdef EDITOR
					_methods set [_forEachIndex,[_name,compile __sc]]
				#endif 
			};true
		
		} foreach _methods;

		_class = nil;
	};
};


/* ------------------------------------------------------
	Region: generic class members info
------------------------------------------------------ */

#define __on_editor_attribute(membername,membertype) if (count _editor_next_attr > 0) then { \
	membertype pushBack [membername,_editor_next_attr]; \
	_editor_next_attr = []; \
};

//регистратор переменной в классе. используется в генераторе узлов
pc_oop_regvar = {
	params ["_f","_v"];
	_mem_name = _f;
	_lastIndex = _fields pushback [_mem_name,_v];
	call pc_oop_handleAttrF;
};

//обработчик атрибутов поля
pc_oop_handleAttrF = {
	if (!isnil '_last_node_info_') then {
		["f",_class,_mem_name,_last_node_info_] call nodegen_registerMember;
		_last_node_info_ = nil;
	};
	if (!isnil '_netuse') then {(_fields select _lastIndex) set [2,"netuse"]; _netuse = nil};
	if (!isnil '_isAutoRefUse') then {_autoref pushBack _mem_name; _isAutoRefUse = nil};
	if (!isnil '_isConstant') then {_pt_obj setvariable ['cst_##var',val]; _isAutoRefUse = nil};
	if (isnil '_editor_next_attr') exitwith {};
	__on_editor_attribute(_mem_name,_editor_attrs_f);
};

//обработчик атрибутов метода
pc_oop_handleAttrM = {
	if (!isnil '_last_node_info_') then {
		["m",_class,_mem_name,_last_node_info_] call nodegen_registerMember;
		_last_node_info_ = nil;
	};
	if (isnil '_editor_next_attr') exitwith {};
	__on_editor_attribute(_mem_name,_editor_attrs_m);
};

//------------------ initializer renode component --------------------
//!nothrow load module
call compile preprocessFile "src\host\ReNode\ReNode_init.sqf";