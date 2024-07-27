// ======================================================
// Copyright (c) 2017-2024 the ReSDK_A3 project
// sdk.relicta.ru
// ======================================================

regScriptEmit(SLIGHT_LIGHTCELLKOPILKA)
	[
		"ltd",
		null,
		_emitAlias("Направленный свет 2")
		["linkToSrc",[0,0,-0.162998]],
		["setOrient",[0,-266.987,0]],
		["setLightColor",[1,1,0.6588]],
		["setLightIntensity",600],
		["setLightUseFlare",true],
		["setLightFlareSize",0.522],
		["setLightFlareMaxDistance",8.12],
		["setLightAttenuation",[0,0,0,0,2,10]],
		["setLightConePars",[175.43,109.36,0]]
	]
	,[
		"lt",
		null,
		_emitAlias("Точечный свет 4")
		["linkToLight",[0,0,0]],
		["setLightColor",[1,1,0.6588]],
		["setLightAmbient",[1,1,1]],
		["setLightIntensity",150]
	]
endScriptEmit