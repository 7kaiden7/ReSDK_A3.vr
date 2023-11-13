// ======================================================
// Copyright (c) 2017-2023 the ReSDK_A3 project
// sdk.relicta.ru
// ======================================================

#include "..\engine.hpp"
#include "..\oop.hpp"

/*
    !Устаревшая информация
    Компонент ReNodes API для генерации библиотеки узлов графа, вызова функций  

    Общие параметры регистрации
    cat - категория, например operators, По умолчанию: functions
    path - путь до узла в поисковике, По умолчанию: NoCategory
    name - выводимое имя узла, По умолчанию: имя функции или имя метода
    desc - выводимое описание, По умолчанию: -
    color - цвет узла; html, type. По умолчанию: определяется из категории
    disabled - выключает доступность узла в генерацию
    
    __basename - проброшенное имя узла (дефолтное имя)

    in - список точек входа
    out - список точек выхода
        name - имя точки, по умолчанию -
        showname - показывать имя точки, по умолчанию да
        multi - указывает что узел мультиконнектный, по умолчанию выходы только один, входы мульти
        types - типы ReNodes которые могут объединять эти узлы. От первого типа указывается стиль и цвет коннектора

    opt - спиcок опций
        type - тип опции: bool,input,spin,fspin,edit,list,vec2,vec3,rgb,rgba,file
        text - стандартное текстовое описание опции, по умолчанию нет
        label (для bool) - вписанный текст в чекбокс (по умолчанию нет)
        default - значение по умолчанию (по умолчанию нет)
        range (для spin,fspin) - 2 значения с нижним и верхним пределом
        fspindata (для fspin) - 2 значения: размер шага и количество символов после запятой
        values (для list) - список элементов

        title (для file) - плейсхолдер текст инпута пути
        ext (для file) - GLOB-паттерн файлов
        root (для file) - дочерняя директория, которая открывается при выборе файла

    inout: Создает вход и выход по типу: ["in","name:Flow","types:Flow"],["out","name:Flow","types:Flow"]

    Минимальный пример: ["cat:functions","name:Тестовая функция","inout:Flow"]

    Порядок сборки:
    1. Запускается симуляция
    2. Гененрируется библиотека lib.json (для редактора) и bindings.nodes (для платформы)

    Генерация биндинга
        Для генерации вызываемой функции в неё должны подставиться параметры

    Регистрация функций:
        В файле биндингов есть общие свойства. Раздел общих свойств с префиксом @

        "@sect_control_operators":{
		"path":"Операторы", //общее
		"name":"Тест имя", //общее
		"cat": "operators", //общее
		"list": { //список узлов в категории operators
			"if_branch": {
				"name": "Ветка", //переопределенное свойство
				"desc": "Ветка"
			},
			"while": {
				"desc": "Цикл"
			}
		}
	}
*/

/*
    Компонент ReNodes API для генерации библиотеки узлов графа, вызова функций  
*/

//текущая версия библиотеки для генерации
nodegen_const_libversion = 1;
//карта рабочих узлов. Ключ - системное название узла, значение - данные типа хэшкарты
if isNull(nodegen_list_library) then {
    nodegen_list_library = [];
};
nodegen_str_outputJsonData = ""; //сгенерированный json
nodegen_internal_generatedLibPath = ""; //сюда записывается сгенерированный json файл

nodegen_bindingsPath = "src\host\ReNodes\ReNodes_bindings.json";
nodegen_objlibPath = "src\host\ReNodes\lib.obj";

nodegen_debug_copyobjlibPath = "P:\Project\ReNodes\lib.obj";

//регистратор метода
nodegen_addClassMethod = {
    private _ctx = _this;
    _ctx call nodegen_commonAdd;
};

nodegen_addClassField = {
    private _ctx = _this;
    _ctx call nodegen_commonAdd;
};

nodegen_addClassFunction = {
    private _ctx = _this;
    _ctx call nodegen_commonAdd;
};

nodegen_commonAdd = {
    #ifdef _SQFVM
    if (true) exitwith {};
    #endif

    //генерация только в редакторе
    if (!is3DEN) exitwith {};

    private _ctx = _this;
    if isNullVar(_last_node_info_) then {
        _last_node_info_ = [];
    };
    _last_node_info_ pushBack _ctx;
};

nodegen_registerFunctions = {
    //Сюда вставляются пути до функций, которые должны быть регистрированы в библиотеке
    //внутри файлов с функциями составляются определения через node_func

};

nodegen_registerMember = {
    params ["_t","_class","_memname","_contextList"];
    nodegen_list_library pushBack [_t,format["%1.%2",_class,_memname],_contextList];
};

nodegen_generateLib = {
    if (!is3DEN) exitwith {
        setLastError("NodeGen cannot generate library outside ReEditor");
        false
    };
    //промежуточная библиотека
    ["Starting generating intermediate library (ver %1)",nodegen_const_libversion] call printLog;

    private _output = "v" + (str nodegen_const_libversion)+endl;
    
    //!Регистрация функций: не реализовано 
    ["Generating functions"] call printLog;
    private _data = "" + endl;//([nodegen_bindingsPath] call file_read);
    modvar(_output) + "$REGION:FUNCTIONS" + endl;
    modvar(_output) + _data + endl;
    modvar(_output) + "$ENDREGION:FUNCTIONS" + endl;

    //Регистрация членов классов
    ["Generating class members"] call printLog;
    modvar(_output) + "$REGION:CLASSMEM" + endl;
    {
        _x params ["_type","_member","_dataList"];
        {
            modvar(_output) + format["def:%1:%2_%3%4%5",_type,_member,_foreachIndex,endl,_x] + endl;
        } foreach _dataList;
    } foreach nodegen_list_library;
    
    modvar(_output) + endl + "$ENDREGION:CLASSMEM" + endl;
    //Сбор мета-данных о классе
    /*
        Сюда попадают словари, содержащие информацию о классах
        Также тут вычисляются типы данных
    */
    ["Generating class metadata"] call printLog;
    private _typeList = (["object",true] call oop_getinhlist) + ["object"];
    private _lastIndex = count _typeList - 1;
    private _missionPath = getMIssionPath "";
    private _calculateFieldValue = {
        private _val = _this;
        private _ntype = null;
        if not_equalTypes(_val,"") then {
            ["Field %1 in class %2 not serialized",_x select 0,_class] call printWarning;
            _ntype = _val;
        } else {
            if ([_val,"\bcall\b"] call regex_isMatch) exitWith {
                if ('"__instance"' in _val) exitWith {
                    "object"
                };
                "runtime_error_type"
            };
            _ntype = call compile _val;
        };

        if equalTypes(_ntype,0) exitWith {
            if (floor _ntype == _ntype) exitWith {"float"};
            "int"
        };
        if isNullVar(_ntype) exitWith {"null"};
        if equalTypes(_ntype,true) exitwith {"bool"};
        if equalTypes(_ntype,"") exitwith {"string"};
        if equalTypes(_ntype,[]) exitwith {"null_array"};
        if equalTypes(_ntype,objNull) exitwith {"model"};
        if equalTypes(_ntype,locationNull) exitWith {"object"};

        if (typename _ntype == "hashmap") exitwith {"null_hashmap"};

        // _estring = "Unknown type for "+ (_class) + " " + typeName _ntype;
        // stackval = format["%1 val",_ntype];
        // [_estring] call printError;
        
        "unknown_type"
    };
    
    private ["_decl","_allfields","_fields","_methods","_defPath","_class"];
    modvar(_output) + "$REGION:CLASSMETA" + endl + "{" + endl ;//+ """object"" : [""object""]" + endl;
    _tempList = [];
    _el = "";
    {
        _class = _x;
        _fields = [_x,"__fields"] call oop_getTypeValue;
        _methods = [_x,"__methods"] call oop_getTypeValue;
        _decl = [_x,"__decl_info__"] call oop_getTypeValue;
        _defPath = [_decl select 0,_missionPath] call stringReplace;
        
        _el = str(_x) + ": {" + endl + //start defclass
        
        //baselist
        format["    'baseList' : %1,",str([_x,"__inhlist"] call oop_getTypeValue)] + endl +
        
        //declare info (file,path)
        format["    'defined' : {'file':%1,'line':%2},",str(_defPath),(_decl select 1)] + endl +
        //fields info
        "   'fields': {" + endl +
            //all members in lowercase
                "       'defined': {" + (
                (_fields apply {format['%1:%2',str(_x select 0),str((_x select 1) call _calculateFieldValue)]})
                    joinString ","
                ) + "}," + endl +
            //all members in lowercase
                "       'all':" + (str([_x,"__allfields"] call oop_getTypeValue)) + endl +
        "   }," + endl +

        //methods info
        "   'methods': {" + endl +
            //with case sensitivity
            "       'defined':" +(str(_methods apply {_x select 0})) + "," + endl +
            //all members in lowercase
            "       'all':" + (str([_x,"__allmethods"] call oop_getTypeValue)) + endl +
        "   }" + endl +
        
        "}"+ endl; //end defclass
        if (_foreachIndex != _lastIndex) then {
            modvar(_el) + ",";
        };
        _tempList pushBack _el;
        if (_foreachIndex % 200 == 0) then {
            ["Generated %1/%2",_foreachIndex+1,_lastIndex+1] call printLog;
        };
    } foreach (_typeList);
    
    modvar(_output) + (_tempList joinString "");

    modvar(_output) + "}" + endl + "$ENDREGION:CLASSMETA" + endl;

    nodegen_str_outputJsonData = _output;

    [nodegen_objlibPath,nodegen_str_outputJsonData] call file_write;
    
    if (!isNull(nodegen_debug_copyobjlibPath) && {nodegen_debug_copyobjlibPath!=""}) then {
        [nodegen_debug_copyobjlibPath,nodegen_str_outputJsonData,false] call file_write;
    };

    true
};

