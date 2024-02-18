// ======================================================
// Copyright (c) 2017-2023 the ReSDK_A3 project
// sdk.relicta.ru
// ======================================================

#include <..\..\..\engine.hpp>
#include <..\..\..\oop.hpp>
#include <..\..\..\text.hpp>
#include <..\..\GameConstants.hpp>

// Минералы и руды
editor_attribute("InterfaceClass")
editor_attribute("TemplatePrefab")
class(Minerals) extends(Constructions) var(name,"Минерал"); editor_only(var(desc,"Странный");) endclass

editor_attribute("EditorGenerated")
class(ZvyakOre2) extends(Minerals)
	var(model,"a3\rocks_f_argo\limestone\limestone_01_01_f.p3d");
endclass
