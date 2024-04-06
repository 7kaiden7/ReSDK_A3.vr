// ======================================================
// Copyright (c) 2017-2024 the ReSDK_A3 project
// sdk.relicta.ru
// ======================================================

#include "..\engine.hpp"
#include "..\oop.hpp"


class(ScriptedGameObject) extends(object)
	"
		name:Скрипт игрового объекта
		desc:Базовый скрипт игрового объекта для реализации пользовательской логики.
		path:Игровые объекты.Скриптовые
	" node_class

	"
		name:Название скрипта
		desc:Внутреннее название скрипта для игрового объекта.
		prop:all
		classprop:1
		return:string:Название скрипта
		defval:Скрипт игрового объекта
	" node_var
	var(name,"Скрипт игрового объекта");

	"
		name:Владелец скрипта
		desc:Игровой объект, к которому привязан скрипт.
		prop:get
		return:IDestructible^:Игровой объект.
	" node_var
	var(src,nullPtr);

	"
		name:Ограничения типов
		desc:Какие типы игровых объектов могут владеть этим скриптом. "+
		"При указании класса для ограничения используется наследование. Например, указав класс Item все типы, унаследованные от него (например, свеча) могут так же использовать этот скрипт.
		type:const
		classprop:1
		return:array[classname]:Список ролей, доступных в режиме.
		defval:[""IDestructible""]
		restr:IDestructible
	" node_met
	getter_func(getRestrictions,["IDestructible"]);

	// ------------------------------ common setup -------------------------------
	//auto add script to all objects - когда создается первый объект такого скрипта он апллаится ко всем объектам указанного типа
	"
		name:Применить ко всем объектам
		desc:Создает экземпляры скрипта для всех игровых объектов, являющихся типами (или их наследниками), указанных в ограничениях типов. Применение происходит когда хотя бы один игровой объект получил созданный скрипт, либо скрипт указан в объектах карты.
		type:const
		classprop:1
		return:bool:Автоприменение скрипта
		defval:false
	" node_met
	getterconst_func(addScriptToAllObjects,false);

	// ------------------------------------------- logic -------------------------------------------

	func(assignScript)
	{
		objParams_1(_src);

		assert_str(!isNullVar(_src),"Internal param error; Script source is null");
		assert_str(!isNullReference(_src),"Source object is null reference");
		assert_str(isTypeOf(_src,IDestructible),"Script must be assigned to IDestructible instance");
		assert_str(!isTypeOf(_src,BasicMob),"Script cannot be assigned to mob or entity");

		assert_str(isNullReference(getVar(_src,__script)),"Script already assigned to object " + str _src);

		if isNullReference(_src) exitWith {};
		if !isTypeOf(_src,IDestructible) exitWith {};
		if isTypeOf(_src,BasicMob) exitWith {};
		private _canUse = false;
		private _restrList = callSelf(getRestrictions);
		{
			if isTypeStringOf(_src,_x) exitWith {
				_canUse = true;
			};
		} foreach _restrList;

		if (!_canUse) exitWith {
			setLastError("Script " + callSelf(getClassName) + " cannot be assigned to game object " + callFunc(_src,getClassName));
		};
		

		setVar(_src,__script,this);
		setSelf(src,_src);

		callSelfParams(onScriptAssigned,_src);
	};

	"
		name:Скрипт присвоен
		desc:Выполняется когда скрипт присваивается игровому объекту.
		type:event
		out:IDestructible^:Объект:Игровой объект, к которому привязан скрипт.
	" node_met
	func(onScriptAssigned)
	{
		objParams_1(_obj);
	};

	//Действия персонажа к объекту
region(Main action)
	"
		name:При основном действии
		namelib:При основном действии
		desc:Срабатывает при исполнении персонажем основного действия с объектом (при нажатии кнопки ""Е""). "+
		"Основное действие выполняется, если персонаж может его выполнить. "+
		"Для этого он должен быть в сознании и у него должна быть рука, которой производится действие.
		type:event
		out:BasicMob:Персонаж:Тот, кто выполняет действие по отношению к объекту.
	" node_met
	func(_onMainActionWrapper)
	{
		objParams_1(_usr);
		callSelfParams(callBaseMainAction,_usr);
	};

	func(onMainAction)
	{
		objParams_1(_usr);
		callSelfParams(_onMainActionWrapper,_usr);
	};
	
	"
		name:Основное действие
		desc:Базовая логика основного действия, определенная в игровом объекте.
		type:method
		lockoverride:1
	" node_met
	func(callBaseMainAction)
	{
		params ['this'];
		assert_str(!isNullVar(_usr),"Internal error on call base main action - user not defined");
		callFuncParams(getSelf(src),onMainAction,_usr);
	};

	"
		name:Текст основного действия
		desc:Название основного действия, выводимого в окне при нажатии ""ПКМ"" по объекту.
		prop:all
		classprop:1
		return:string:Текст основного действия
		defval:Основное действие
	" node_var
	var(mainActionName,"Основное действие");

	"
		name:Получить текст основного действия
		desc:Данный узел предоставляет возможность гибкой настройки отображаемого названия основного действия при нажатии ""ПКМ"". Например, с помощью этого узла можно выводить ""Включить лампочку"" или ""Выключить лампочку"" в зависимости от состояния игрового объекта, на который назначен скрипт (в этом примере таким объектом является лампочка). "+
		"По умолчанию возвращает значение свойства ""Текст основного действия"".
		type:event
		out:BasicMob:Персонаж:Тот, кто запрашивает текст основного действия.
		return:string:Текст основного действия
	" node_met
	func(_getMainActionNameWrapper)
	{
		objParams_1(_usr);
		getSelf(mainActionName)
	};

	func(getMainActionName)
	{
		objParams_1(_usr);
		callSelfParams(_getMainActionNameWrapper,_usr);
	};

	"
		name:Текст основного действия объекта
		desc:Возвращает текстовое название основного действия, предоставляемое логикой игрового объекта и выводимого в окне при нажатии ""ПКМ"" по объекту.
		type:method
		lockoverride:1
		return:string:Текст основного действия игрового объекта
	" node_met
	func(callBaseGetMainActionName)
	{
		objParams();
		private _r = callFunc(getSelf(src),getMainActionName);
		if isNullVar(_r) then {_r = ""};
		if not_equalTypes(_r,"") then {_r = ""};
		_r
	};
region(Extra action)
	"
		name:При особом действии
		namelib:При особом действии
		desc:Срабатывает при исполнении персонажем особого действия с объектом (при нажатии кнопки ""F"" с включенным спец.действием).
		type:event
		out:BasicMob:Персонаж:Тот, кто выполняет действие по отношению к объекту.
		out:enum.SpecialActionType:Тип действия:Тип специального действия
	" node_met
	func(_onExtraActionWrapper)
	{
		objParams_2(_usr,_act);
		callSelfParams(callBaseExtraAction,_usr arg _act);
	};

	func(onExtraAction)
	{
		objParams_2(_usr,_act);
		if isNullVar(_act) then {
			_act = getVar(_usr,specialAction);
		};
		callSelfParams(_onExtraActionWrapper,_usr arg _act);
	};

	"
		name:Особое действие
		desc:Базовая логика особого действия, определенная в игровом объекте.
		type:method
		lockoverride:1
	" node_met
	func(callBaseExtraAction)
	{
		params ['this'];
		assert_str(!isNullVar(_usr),"Internal error on call base extra action - user not defined");
		callFuncParams(_usr,extraAction,getSelf(src));
	};

region(Common interactions)

	// --------------- generic interactions -----------------------

	"
		name:При клике предметом
		desc:Срабатывает при клике цели объектом.
		type:event
		out:Item:Предмет:Предмет, которым выполняется атака
		out:BasicMob:Персонаж:Тот, кто атакует цель.
	" node_met
	func(_onAttackWithWrapper)
	{
		objParams_3(_with,_usr,_isSelf);
		callSelf(attackWithBase);
	};

	func(onAttackWith)
	{
		objParams_3(_with,_usr,_isSelf);
		callSelfParams(_onAttackWithWrapper,_with arg _usr arg _isSelf);
	};

	func(attackWithBase)
	{
		params ['this'];
		callFuncParams(_usr,clickTarget,_targ);
	};

region(InteractWith)
	"
		name:При взаимодействии предметом
		desc:Срабатывает при взаимодействии персонажа с объектом с помощью предмета.
		type:event
		out:Item:Предмет:Предмет, используемый для взаимодействия.
		out:BasicMob:Персонаж:Персонаж, выполняющий взаимодействие.
	" node_met
	func(_onInteractWithWrapper)
	{
		objParams_2(_with,_usr);
		callSelfParams(callBaseInteractWith,_with arg _usr);
	};

	func(onInteractWith)
	{
		objParams_2(_with,_usr);
		callSelfParams(_onInteractWithWrapper,_with arg _usr);
	};

	"
		name:Взаимодействие предметом
		desc:Основная логика взаимодействия с объектом с помощью предмета.
		type:method
		lockoverride:1
		in:Item:Предмет:Предмет, используемый для взаимодействия.
		in:BasicMob:Персонаж:Персонаж, выполняющий взаимодействие.
	" node_met
	func(callBaseInteractWith)
	{
		params ['this'];
		// Проверки
		assert_str(!isNullVar(_usr),"Internal error on call base interact with - user not defined");
		assert_str(!isNullVar(_with),"Internal error on call base interact with - item not defined");
		assert_str(!isNullReference(_usr),"Internal error on call base interact with - user null reference");
		assert_str(!isNullReference(_with),"Internal error on call base interact with - item null reference");
		
		callFuncParams(getSelf(src),onInteractWith,_with arg _usr);
	};

region(OnClick)
	"
		name:При нажатии
		desc:Срабатывает при нажатии персонажа по объекту.
		type:event
		out:BasicMob:Персонаж:Персонаж, выполняющий нажатие.
	" node_met
	func(_onClickWrapper)
	{
		objParams_1(_usr);
		callSelfParams(callBaseOnClick,_usr);
	};

	func(onClick)
	{
		objParams_1(_usr);
		callSelfParams(_onClickWrapper,_usr);
	};

	"
		name:Нажатие
		desc:Основная логика нажатия на объект.
		type:method
		lockoverride:1
		in:BasicMob:Персонаж:Персонаж, выполняющий нажатие.
	" node_met
	func(callBaseOnClick)
	{
		params ['this'];
		// Проверки
		assert_str(!isNullVar(_usr),"Internal error on call base onClick - user not defined");
		assert_str(!isNullReference(_usr),"Internal error on call base onClick - user null reference");
		
		callFuncParams(getSelf(src),onClick,_usr);
	};

region(ItemClick)
	"
		name:При нажатии предметом на себя
		desc:Срабатывает при нажатии персонажем по предмету в инвентаре.
		type:event
		out:Item:Предмет:Предмет, которым выполняется нажатие.
		out:BasicMob:Персонаж:Персонаж, выполняющий нажатие.
		out:bool:Боевой режим:Возвращает истину, если нажатие произведено в боевом режиме.
	" node_met
	func(_onItemSelfClickWrapper)
	{
		objParams_2(_usr,_combat);
		callSelfParams(callBaseItemSelfClick,_with arg _usr);
	};

	func(onItemSelfClick)
	{
		objParams_2(_usr,_combat);
		callSelfParams(_onItemSelfClickWrapper,_usr arg _combat);
	};

	"
		name:Нажатие предметом на себя
		desc:Основная логика нажатия предметом на себя.
		type:method
		lockoverride:1
		in:Item:Предмет:Предмет, которым выполняется нажатие.
		in:BasicMob:Персонаж:Персонаж, выполняющий нажатие.
	" node_met
	func(callBaseItemSelfClick)
	{
		params ['this'];
		// Проверки
		assert_str(!isNullVar(_usr),"Internal error on call base item self click - user not defined");
		assert_str(!isNullVar(_with),"Internal error on call base item self click - item not defined");
		assert_str(!isNullReference(_usr),"Internal error on call base item self click - user null reference");
		assert_str(!isNullReference(_with),"Internal error on call base item self click - item null reference");
		
		callFuncParams(getSelf(src),onItemSelfClick,_with arg _usr);
	};


	// "
	// 	name:При взаимодействии предметом
	// 	namelib:При взаимодействии предметом
	// 	desc:Срабатывает при исполнении персонажем взаимодействия с объектом с помощью предмета в активной руке. (ЛКМ по объекту с предметом в руке)
	// 	type:event
	// 	out:Item:Предмет:Предмет, которым выполняется взаимодействие с объектом.
	// 	out:BasicMob:Персонаж:Тот, кто выполняет действие по отношению к объекту.
	// " node_met
	// func(_onInteractWithWrapper)
	// {
	// 	objParams_2(_with,_usr);
	// 	callSelfParams(callBaseInteractWith,_with arg _usr);
	// };

	// func(onInteractWith)
	// {
	// 	objParams_2(_with,_usr);
	// 	callSelfParams(_onInteractWithWrapper,_with arg _usr);
	// };

	// "
	// 	name:Взаимодействие предметом
	// 	desc:Базовая логика взаимодействия с помощью предмета, определенная в игровом объекте.
	// 	type:method
	// 	lockoverride:1
	// 	in:Item:Предмет:Предмет, которым выполняется взаимодействие с объектом.
	// 	in:BasicMob:Персонаж:Тот, кто выполняет действие по отношению к объекту.
	// " node_met
	// func(callBaseInteractWith)
	// {
	// 	params ['this'];
	// 	//standard checks
	// 	assert_str(!isNullVar(_usr),"Internal error on call base interact with - user not defined");
	// 	assert_str(!isNullVar(_with),"Internal error on call base interact with - item not defined");
	// 	assert_str(!isNullReference(_usr),"Internal error on call base interact with - user null reference");
	// 	assert_str(!isNullReference(_with),"Internal error on call base interact with - item null reference");
		
	// 	callFuncParams(getSelf(src),onInteractWith,_with arg _usr);
	// };

	// "
	// 	name:При нажатии по объекту
	// 	namelib:При нажатии по объекту
	// 	desc:Срабатывает при нажатии ЛКМ пустой рукой по объекту в мире.
	// 	type:event
	// 	out:BasicMob:Персонаж:Тот, кто выполняет действие по отношению к объекту.
	// 	return:bool:Результат выполнения действия. Возвращает @[bool ИСТИНУ], если действие успешно выполнено.
	// " node_met
	// func(_onClickWrapper)
	// {
	// 	objParams_1(_usr);
	// 	callSelfParams(callBaseClick,_usr);
	// };

	// func(onClick)
	// {
	// 	objParams_1(_usr);
	// 	callSelfParams(_onClickWrapper,_usr);
	// };

	// "
	// 	name:Нажатие по объекту
	// 	desc:Базовая логика нажатия по объекту, определенная в игровом объекте.
	// 	type:method
	// 	lockoverride:1
	// 	in:BasicMob:Персонаж:Тот, кто выполняет действие по отношению к объекту.
	// 	return:bool:Результат выполнения действия. Возвращает @[bool ИСТИНУ], если действие успешно выполнено.
	// " node_met
	// func(callBaseClick)
	// {
	// 	params ['this'];
	// 	private _r = callFuncParams(getSelf(src),onClick,_usr);
	// 	if isNullVar(_r) then {_r = true};
	// 	if not_equalTypes(_r,true) then {_r = true};
	// 	_r
	// };



endclass

/* TODO replace to item script
	"
		name:При нажатии по предмету в инвентаре
		namelib:При нажатии по предмету в инвентаре
		desc:Срабатывает при нажатии персонажем по предмету в слоте собственного инвентаря.
		type:event
		out:BasicMob:Персонаж:Тот, кто выполняет действие по отношению к объекту.
		return:bool:Результат выполнения действия. Возвращает @[bool ИСТИНУ], если действие успешно выполнено.
	" node_met
	func(onItemClick)
	{
		objParams_1(_usr);
		callSelfParams(callBaseItemClick,_usr);
	};

	"
		name:Нажатие по предмету в инвентаре
		desc:Базовая логика нажатия по предмету, определенная в игровом объекте.
		type:method
		lockoverride:1
		in:BasicMob:Персонаж:Тот, кто выполняет действие по отношению к объекту.
		return:bool:Результат выполнения действия. Возвращает @[bool ИСТИНУ], если действие успешно выполнено.
	" node_met
	func(callBaseItemClick)
	{
		params ['this'];
		private _r = callFuncParams(getSelf(src),onItemClick,_usr);
		if isNullVar(_r) then {_r = true};
		if not_equalTypes(_r,true) then {_r = true};
		_r
	};

	"
		name:При нажатии по предмету в активной руке
		namelib:При нажатии по предмету в активной руке
		desc:Срабатывает при нажатии персонажем по предмету в активной руке через инвентарь.
		type:event
		out:BasicMob:Персонаж:Тот, кто выполняет действие по отношению к объекту.
		return:bool:Результат выполнения действия. Возвращает @[bool ИСТИНУ], если действие успешно выполнено.
	" node_met
	func(onItemSelfClick)
	{
		objParams_1(_usr);
		callSelfParams(callBaseItemSelfClick,_usr);
	};

	"
		name:Нажатие по предмету в активной руке
		desc:Базовая логика нажатия по предмету, определенная в игровом объекте.
		type:method
		lockoverride:1
		in:BasicMob:Персонаж:Тот, кто выполняет действие по отношению к объекту.
		return:bool:Результат выполнения действия. Возвращает @[bool ИСТИНУ], если действие успешно выполнено.
	" node_met
	func(callBaseItemSelfClick)
	{
		params ['this'];
		private _r = callFuncParams(getSelf(src),onItemSelfClick,_usr);
		if isNullVar(_r) then {_r = true};
		if not_equalTypes(_r,true) then {_r = true};
		_r
	};
*/