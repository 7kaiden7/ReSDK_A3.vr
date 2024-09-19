// ======================================================
// Copyright (c) 2017-2024 the ReSDK_A3 project
// sdk.relicta.ru
// ======================================================

#include <..\..\..\engine.hpp>
#include <..\..\..\oop.hpp>
#include <..\..\..\text.hpp>
#include <..\..\GameConstants.hpp>

//Растительность
editor_attribute("InterfaceClass")
editor_attribute("TemplatePrefab")
class(SmallStoneBase) extends(Constructions) 
	var(name,"Камень"); 
	editor_only(var(desc,"Каменные камни");) 
	var(material,"MatStone");
	var(dr,3);
endclass

editor_attribute("EditorGenerated")
class(YellowStone) extends(SmallStoneBase)
	var(model,"a3\rocks_f_argo\limestone\limestone_01_01_f.p3d");
endclass