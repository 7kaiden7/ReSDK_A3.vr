// ======================================================
// Copyright (c) 2017-2023 the ReSDK_A3 project
// sdk.relicta.ru
// ======================================================


interface_class(InfluenceEventAllMaps) extends(BaseProgressInfluenceEvent) 
endclass

interface_class(InfluenceEventDirtpit) extends(BaseProgressInfluenceEvent)
	var(allowedMaps,["Minimap"]);
endclass

// var(name,"Мельтешачье безумие");
// var(desc,"Мельтешата озверели. Они кусаются в два раза больнее и серьезнее.");

// var(name,"Сон. час");
// var(desc,"Персонажи игроков падают в сон. Либо таймер на 30 секунд, либо без таймера. Просто резко все падают в сон.");

// var(name,"Кислое молоко");
// var(desc,"Всё существующее молоко на карте скисло.");

//Пропажа (некоторые предметы (кроме блядских ключей и важных для режима) тпшаются за карту либо удаляются)


//TODO
//всё холодное оружие требует в 2 раза больше силы и утяжеляется в половину
//эпидемия
//Набег жрунов - все призраки могут заспавниться за жрунов
//Морок (кто-то на карте начинает испытвать симптомы превращения в жруна)
//Отдай свои страдания - все на карте рандомно меняются своим физическим состоянием, исключая мертвых. То есть в теории кому-то могут вернуться руки, в то время как у другого они отнимутся
