// ======================================================
// Copyright (c) 2017-2023 the ReSDK_A3 project
// sdk.relicta.ru
// ======================================================

#include <..\..\engine.hpp>
#include <..\..\oop.hpp>

//большие стены
editor_attribute("InterfaceClass")
editor_attribute("TemplatePrefab")
class(BigWall) extends(BigConstructions) var(name,"Большая стена"); var(desc,"Огромная стена выполняющая роль ограничения доступной зоны. Не разрушаема"); endclass


editor_attribute("EditorGenerated")
class(BigStoneWall) extends(BigWall)
	var(model,"ca\structures\castle\a_castle_wall1_20.p3d");
endclass