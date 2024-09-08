// ======================================================
// Copyright (c) 2017-2024 the ReSDK_A3 project
// sdk.relicta.ru
// ======================================================
#define PREPROCESS_DATA "PREPROCESS_OUTPUT"

#include "..\TestFramework.h"

TEST(Yaml_Base)
{
	ASSERT_STR(call yaml_isExtensionLoaded,"ReYaml not found or not loaded");
private _dat = "
  a: 1
  b:
    c: [6,7,8]
    d: [a,b,c]
";
	private _ref = refcreate(0);
	ASSERT([_dat arg _ref] call yaml_loadData);
	private _map = refget(_ref);
	
	ASSERT_EQ(count _map,2);
	ASSERT_EQ(_map get "a",1);
	
	ASSERT_EQ(count (_map get "b"),2);
	
	ASSERT_EQ(count (_map get "b" get "c"),3);
	ASSERT_EQ(_map get "b" get "c" select 2,8);
	
	ASSERT_EQ(count (_map get "b" get "d"),3);
	ASSERT_EQ(_map get "d" select 2,"c");
}

TEST(Yaml_PartialLoading)
{
	//test long yaml (partial loading)
	private _d = [];
	for"_i" from 1 to 20480 do {
		_d pushBack (format["longkey_%1: Ключ с длинным значением по индексу %1",_i]);
	};
	_d pushBack "LATEST: ""EOF""   ";
	_d = _d joinString endl;

	ASSERT([_dat arg _ref] call yaml_loadData);
	_map = refget(_ref);
	ASSERT_EQ(count _map,20480 + 1);
	ASSERT_EQ(_map get "LATEST","EOF");
	ASSERT_EQ(_map get "longkey_20480","Ключ с длинным значением по индексу 20480");
}

TEST(Yaml_FileLoadingAllTypes)
{
	private _dat = ["src\host\Yaml\test.yaml"] call yaml_loadFile;
	ASSERT(_dat);
	ASSERT(count _dat > 0);
	ASSERT_EQ(_dat get "key","value");
	ASSERT("test_null" in _dat && {isNull(_dat get "test_null")});
}

TEST(LootSystem_AllCheckBase)
{
	//cleanup
	loot_mapConfigs = createHashMap;
	loot_list_loader = [];// список файлов для загрузки

	//init
	["test.yml"] call loot_addConfig;
	call loot_init;

	//checks
	ASSERT_STR(count loot_mapConfigs == 1,"Loot templates not loaded");
	ASSERT("TestLoot" in loot_mapConfigs);

	private _lootObj = loot_mapConfigs get "TestLoot";
	private _funcRef = oop_getFieldBaseValue;
	oop_getFieldBaseValue = { "TestMap" }; //override func to return "TestMap"
	ASSERT_EQ(_lootObj callp(checkLootSpawnRestriction,"GamemodeName"),true);
	oop_getFieldBaseValue = _funcRef; //restore func

	ASSERT_EQ(count (_lootObj getv(allowMaps)),4);
	ASSERT_EQ(count (_lootObj getv(allowModes)),0);
	ASSERT_EQ(count (_lootObj getv(items)),2);
	
	private _itemList = _lootObj getv(items);

	private _fit = _itemList select (_itemlist findif {_x getv(itemType) == "Item"});
	ASSERT_EQ(_fit getv(itemType),"Item");
	ASSERT_EQ(_fit getv(countMin),1);
	ASSERT_EQ(_fit getv(countMax),3);

	private _sit = _itemList select (_itemlist findif {_x getv(itemType) == "Key"});
	ASSERT_EQ(_sit getv(itemType),"Key");
	ASSERT_EQ(_sit getv(countMin),4);
	ASSERT_EQ(_sit getv(countMax),4);
	ASSERT_EQ(_sit callv(isRangeBasedCount),false);

	//loot spawn test
	_tobj = ["OldWoodenBox",[10,10,10]] call createGameObjectInWorld;
	ASSERT(!isNullReference(_tobj));
	ASSERT(_sit callp(processSpawnLoot,_tobj));

	//compare checks
	private _clst = _lootObj getv(allowMaps);
	
	//regex base
	traceformat("Compare now: %1",_clst select 0 getv(compareType))
	ASSERT_EQ(_clst select 0 callp(compareTo,"OMap4"),true);
	ASSERT_EQ(_clst select 0 callp(compareTo,"OMap"),false);
	
	//exact
	traceformat("Compare now: %1",_clst select 1 getv(compareType))
	ASSERT(_clst select 1 callp(compareTo,"TestMap"));
	ASSERT(_clst select 1 callp(compareTo,"testmap"));
	
	//inline exact
	ASSERT_EQ(_clst select 1 getv(compareType),_clst select 2 getv(compareType));
	
	//typeof
	traceformat("Compare now: %1",_clst select 3 getv(compareType))
	(_clst select 3) setv(value,"ManagedObject");
	ASSERT(_clst select 3 callp(compareTo,"object"));
}

TEST(FileSystem_Basic)
{
	private _thisfile = "src\host\UnitTests\TestsCollection\io.sqf";

	ASSERT(fileExists(_thisFile));
	ASSERT([_thisfile] call fileExists_Node);
	
	//content load
	private _content = [_thisfile] call fileLoad_Node;
	ASSERT("#define PREPROCESS_DATA" in _content);
	
	private _pcontent = [_thisfile,true] call fileLoad_Node;
	ASSERT(PREPROCESS_DATA in _pcontent);
}