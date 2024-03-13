// ======================================================
// Copyright (c) 2017-2024 the ReSDK_A3 project
// sdk.relicta.ru
// ======================================================

#include <GameMode.h>

//all public tasks here...
#include <CommonTasks\PublicTasks.sqf>

taskSystem_allTasks = [];
taskSystem_checkedOnEndRound = [];

taskSystem_map_tags = createHashMap; //map of all tagged tasks

//register tasksystem functions
#include "taskSystem_functions.sqf"


#ifdef EDITOR
	#define editor_task_test
#endif

/* 
	Обновлённая система задач

	Задачи делятся на 2 категории:
	 - проверяемые в конце раунда
	 - проверяемые до успешного выполнения

	У задачи всегда есть состояние: выполнено/не выполнено.
	Задачи проверяемые в конце раунда выполняются по условию true
		Провалены если условие не выполнено к концу раунда
	Задачи, выполняемые до успешного выполнения, считаются успешно завершенными когда условие выполнено (после выполнения проверка останавливается)
		Провалены если режим закончился или сработали условия провала (объект уничтожен, владелец задачи уничтожен и т.д.)


	Интерфейсы:
	ItemKindTask - задача относящаяся к работе с игровыми предметами
		- входные параметры: ссылка объекта, глобальнаяссылка, массив ссылок или глобальных ссылок, тип, массив типов
	MobKindTask - задача относящаяся к работе с сущностями
		- входные параметры: ссылка объекта
	GameObjectKindTask - задача относящаяся к работе с игровыми объектами
		- входные параметры: ссылка объекта, глобальная ссылка, ... (как в ItemKindTask)
		TODO inherit from item (or item inherit from this)
	CounterKindTask - задача для работы с подсчетом значений
		- входные параметры: int - счетчик
	LocationKindTask - задача относящаяся к работе с локациями (прибытие и нахождение в локации)
		- входные параметры: позиция, дистанция, возможный triggerArea, ссылки на объекты
	RoleKindTask - задача на работу с ролями
	TODO ReagentTask - 
	TODO StatusEffectGetTask -
*/

//todo remove legacy task
#include "__old_tasks.sqf"

editor_attribute("ColorClass" arg "1370A2")
class(TaskBase) extends(IGameEvent)

	func(constructor)
	{
		objParams();
		assert_str(callSelf(getParentClassName)!="TaskBase","Abstract task cannot be created");
		private _nf = {
			objParams();
			if (count getSelf(owners) == 0) exitWith {
				_etext = format["Задача %1 (%2) не была назначена ни одному из владельцев.",getSelf(name),callSelf(getClassName)];
				setLastError(_etext);
			};
		}; nextFrameParams(_nf,this);
	};

	func(destructor)
	{
		objParams();
		private _ctx = format["%1 (%2)",getSelf(name),callSelf(getClassName)];
		setLastError("Ручное удаление задачи не допускается: " + _ctx);
	};

	"
		name:Задача
		desc:Базовая игровая задача для персонажа
		path:Игровая логика.Задачи
	" node_class

	"
		name:Тэг задачи
		desc:Тэг созданной задачи. По умолчанию пустая строка
		prop:get
	" node_var
	var(tag,"");//системный тэг задачи

	//Установить тэг задачи
	"
		name:Установить тэг задачи
		desc:Устанавливает тэг задачи. Может быть несколько задач с одинаковым тэгом.
		type:method
		lockoverride:1
		in:string:Тэг:Новый тэг задачи
	" node_met
	func(setTag)
	{
		objParams_1(_tagName);
		private _oldTag = getSelf(tag);
		if array_exists(taskSystem_map_tags,_oldTag) then {
			private _tasksByTag = (taskSystem_map_tags get _oldTag);
			_tasksByTag deleteAt (_tasksByTag find this);
		};

		if array_exists(taskSystem_map_tags,_tagName) then {
			(taskSystem_map_tags get _tagName) pushBack this;
		} else {
			taskSystem_map_tags set [_tagName,[this]];
		};

		setSelf(tag,_tagName);
	};
	
	"
		name:Название задачи
		desc:Название задачи
		prop:all
		defval:Задача
	" node_var
	var(name,"Задача");

	"
		name:Описание задачи
		desc:Системное описание задачи
		prop:all
		defval:Сделать дело
	" node_var
	var(desc,"Сделать дело");

	"
		name:Ролевое описание задачи
		desc:Ролевое описание задачи
		prop:all
		defval:Нужно сделать дело...
	" node_var
	var(descRoleplay,"Нужно сделать дело...");

	"
		name:Обработчик описания задачи
		desc:Вызываемая функция вывода описания задачи. Обычно в этой функции вычисляются форматируемые значения (например, список объектов). Чтобы посмотреть исходную строку выведите в консоли 'Ролевое описание задачи'.
		prop:all
		return:function[event=string=BasicTask^]:Описание задачи
	" node_var
	var(_taskDescDelegate,{getSelf(descRoleplay)});
	func(getTaskDescription)
	{
		objParams();
		[this] call getSelf(_taskDescDelegate)
	};

	"
		name:Единоразовая проверка условий
		desc:При включении этой опции задача будет выполнять проверку для всех её владельцев. В выключенном состоянии проверка осуществляется только для первого владельца задачи. "+
		"Это свойство не влияет на вызов событий при выполнении или провале задачи - успех и провал выполняется ко всем владельцам задачи.
		prop:all
		return:bool:Проверка условий
		defval:false
	" node_var
	var(isTaskSingleCheck,false); //проверка только для первого владельца

	var(owners,[]); //кто владеет данной задачей

	"
		name:Владельцы задачи
		desc:Получает список владельцев задачи
		type:get
		lockoverride:1
		return:array[Mob^]:Владельцы задачи
	" node_met
	getter_func(getOwners,getSelf(owners));

	"
		name:Задача завершена
		desc:Возвращает ИСТИНУ, если задача завершила выполнение. Провал задачи также считается завершением. Задачи, проверяемые только в конце раунда завершаются когда раунд закончится.
		prop:get
		return:bool:Завершено ли выполнение задачи
		defval:false
	" node_var
	var(isDone,false); //метка активности задачи

	//флаг, отвечающий за то является ли задача выполняемой до конца раунда или по условию в прогрессе
	getterconst_func(checkCompleteOnEnd,false);

	"
		name:Частота проверки задачи
		desc:Время, через которое выполняется проверка условия выполнения задачи
		prop:get
		return:int:Частота проверки условия задачи
		defval:2
	" node_var
	var(checkDelay,2);

	"
		name:Результат задачи
		desc:Возвращает числовое значение результата задачи. Если результат равен нулю, то считается что задача не выполнена.
		prop:get
		return:int:Результат выполнения задачи
		defval:0
	" node_var
	var(result,0); //всё что отлично от 0 является результатом задачи. Принимается правило, что отрицательные значения - провал, положительные - успех
	
	func(onRegisterInTarget)
	{
		objParams_1(_mob);
		if getSelf(taskRegistered) exitWith {
			getSelf(owners) pushBackUnique _mob;
		};

		setSelf(taskRegistered,true);

		taskSystem_allTasks pushBack this;
		callSelfParams(setTag,getSelf(tag));

		getSelf(owners) pushBackUnique _mob;

		callSelf(onTaskRegistered);

		if callSelf(checkCompleteOnEnd) then {
			taskSystem_checkedOnEndRound pushBack this;
		} else {
			setSelf(_taskHandle__,startUpdateParams(getSelfFunc(updateMethod),getSelf(checkDelay),this));
		};
	};

	// Флаг, указывающий, что задача уже зарегистрирована
	var(taskRegistered,false);

	func(onTaskRegistered)
	{
		objParams();
		//virtual function
	};

	var(_taskHandle__,-1);

	func(destructor)
	{
		if (getSelf(_taskHandle__)!=-1) then {
			stopUpdate(getSelf(_taskHandle__));
			setSelf(_taskHandle__,-1);
		};
		array_remove(taskSystem_allTasks,this);
	};

	func(updateMethod)
	{
		updateParams();
		callSelf(updateMethodInternal);
	};
	func(updateMethodInternal)
	{
		objParams();
		private _singleCheck = getSelf(isTaskSingleCheck);
		{
			callSelfParams(onTaskCheck,_x);

			//останавливаем проверку после выполнения задачи
			if (getSelf(isDone) || getSelf(result)!=0) exitWith {};

			if (_singleCheck && _foreachindex <= 0) exitWith {};
		} foreach getSelf(owners);
	};

	"
		name:Дополнительные условия
		desc:Дополнительные условия, которые должны быть выполнены для проверки задачи. Первый параметр - вызывающий событие объект (Задача), второй параметр - владелец задачи (Моб).
		prop:all
		return:function[event=bool=BasicTask^@Mob^]:Условие проверки задачи
	" node_var
	var(_customCondition,{true});

	func(onTaskCheck)
	{
		objParams_1(_owner);
	};

	"
		name:Установить результат задачи
		desc:Устанавливает результат задачи. Если результат не равен нулю, то задача завершается с указанным результатом. Положительный результат считается успешным выполнением задачи, а отрицательный - провалом. "+
		"Если задача помечена как выполненная - ничего не произойдёт.
		type:method
		lockoverride:1
		in:int:Результат:Результат выполнения задачи
	" node_met
	func(setTaskResult)
	{
		params ['this',"_tr",["_endroundCheck",false]];

		if getSelf(isDone) exitWith {}; //task already done - exit
		setSelf(result,_tr);

		if (!callSelf(checkCompleteOnEnd) || _endroundCheck) then {
			if (_tr != 0) then {
				callSelf(onTaskDone);
			};
		};
	};

	//вызывается автоматически при задаче с checkCompleteOnEnd, либо при пользовательской проверке на завершение
	func(onTaskDone)
	{
		objParams();
		setSelf(isDone,true);
		private _tr = getSelf(result);
		if (_tr > 0) then {
			{
				_x params ["_mob"];
				[this,_mob,_foreachindex] call getSelf(_taskOnSuccessDeletage);
			} foreach getSelf(owners);
		} else {
			{
				_x params ["_mob"];
				[this,_mob,_foreachindex] call getSelf(_taskOnFailDeletage);
			} foreach getSelf(owners);
		};
	};

	// обработчики успешного выполнения и провала
	"
		name:Обработчик успешного выполнения задачи
		desc:Вызывается при успешном выполнении задачи для каждого владцельца.
		prop:all
		return:function[event=null=BasicTask^@Mob^@int]:Обработчик успешного выполнения задачи
	" node_var
	var(_taskOnSuccessDeletage,{});
	"
		name:Обработчик провала задачи
		desc:Вызывается при провале задачи для каждого владельца.
		prop:all
		return:function[event=null=BasicTask^@Mob^@int]:Обработчик провала задачи
	" node_var
	var(_taskOnFailDeletage,{});

	"
		name:Копировать задачу
		desc:Создает копию задачи. Тэг и владельцы задачи не копируются.
		type:method
		lockoverride:1
	" node_met
	func(copyTask)
	{
		objParams();
		private _class = callSelf(getClassName);
		private _instance = instantiate(_class);
		private _fvals = (allVariables _instance) apply {tolower _x};
		private _excludedVars = ["_taskHandle__","owners","tag"] apply {tolower _x};
		private _fnamesUpdate = _fvals - _excludedVars;
		private _temp = null;
		{
			_temp = getSelfReflect(_x);
			if equalTypes(_temp,[]) then {
				_temp = array_copy(_temp);
			};
			setVarReflect(_instance,_x,_temp);
		} foreach _fnamesUpdate;
	};

endclass
