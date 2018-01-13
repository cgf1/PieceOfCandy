-- Taos Group Ultimate english localization file

-- Options
local strings = {
    TGU_WARNING_LGS_ENABLE =             "Warning: Enable LibGroupSocket to send -> /lgs 1",
    TGU_OPTIONS_HEADER =                 "Options",
    TGU_OPTIONS_DRAG_LABEL =             "Drag elements",
    TGU_OPTIONS_DRAG_TOOLTIP =           "If activated, you can drag all elements.",
    TGU_OPTIONS_ONLY_AVA_LABEL =         "Show only in AvA",
    TGU_OPTIONS_ONLY_AVA_TOOLTIP =       "If activated, all elements will only be visible in Cyrodiil (AvA).",
    TGU_OPTIONS_USE_LGS_LABEL =          "Communication via LibGroupSocket",
    TGU_OPTIONS_USE_LGS_TOOLTIP =        "If activated, the addon will try to activate communication via LibGroupSocket. LibGroupSocket must be installed as own addon.",
    TGU_OPTIONS_USE_SORTING_LABEL =      "Sort lists by ultimate progress",
    TGU_OPTIONS_USE_SORTING_TOOLTIP =    "If activated, all lists will be sorted by ultimate progress (Maximum on top).",
    TGU_OPTIONS_STYLE_LABEL =            "Choose style",
    TGU_OPTIONS_STYLE_TOOLTIP =          "Choose your style. Simple-List, Swimlane-List or Compact Swimlane-List",
    TGU_OPTIONS_STYLE_SIMPLE =           "Simple-List",
    TGU_OPTIONS_STYLE_SWIM =             "Swimlane-List",
    TGU_OPTIONS_STYLE_SHORT_SWIM =       "Compact Swimlane-List",
    TGU_DESCRIPTIONS_NEGATE =            "Negate ultimates from Sorcerer class",
    TGU_DESCRIPTIONS_ATRO =              "Atronach ultimates from Sorcerer class",
    TGU_DESCRIPTIONS_OVER =              "Overload ultimates from Sorcerer class",
    TGU_DESCRIPTIONS_SWEEP =             "Sweep ultimates from Templar class",
    TGU_DESCRIPTIONS_NOVA =              "Nova ultimates from Templar class",
    TGU_DESCRIPTIONS_TPHEAL =            "Heal ultimates from Templar class",
    TGU_DESCRIPTIONS_STAND =             "Standard ultimates from Dragonknight class",
    TGU_DESCRIPTIONS_LEAP =              "Leap ultimates from Dragonknight class",
    TGU_DESCRIPTIONS_MAGMA =             "Magma ultimates from Dragonknight class",
    TGU_DESCRIPTIONS_STROKE =            "Death Stroke ultimates from Nightblade class",
    TGU_DESCRIPTIONS_VEIL =              "Veil of Blades ultimates from Nightblade class",
    TGU_DESCRIPTIONS_NBSOUL =            "Soul ultimates from Nightblade class",
    TGU_DESCRIPTIONS_FREEZE =            "Storm ultimates from Warden class",
    TGU_DESCRIPTIONS_WDHEAL =            "Heal ultimates from Warden class",
    TGU_DESCRIPTIONS_ICE =               "Ice ultimates from Destruction Staff weapon",
    TGU_DESCRIPTIONS_FIRE =              "Fire ultimates from Destruction Staff weapon",
    TGU_DESCRIPTIONS_LIGHT =             "Lightning ultimates from Destruction Staff weapon",
    TGU_DESCRIPTIONS_STHEAL =            "Heal ultimates from Healing Staff weapon",
    TGU_DESCRIPTIONS_BERSERK =           "Berserker ultimates from Twohand weapon",
    TGU_DESCRIPTIONS_SHIELD =            "Shield ultimates from One hand and Shield weapon",
    TGU_DESCRIPTIONS_DUAL =              "Dual wield ultimates from Dual Wield weapons",
    TGU_DESCRIPTIONS_BOW =               "Bow ultimates from Bow weapon",
    TGU_DESCRIPTIONS_SOUL =              "Soul ultimates from Soul Magic skill line",
    TGU_DESCRIPTIONS_WERE =              "Werewolf ultimates from Werewolf skill line",
    TGU_DESCRIPTIONS_VAMP =              "Vamp ultimates from Vampire skill line",
    TGU_DESCRIPTIONS_METEOR =            "Meteor ultimates from Mages guild",
    TGU_DESCRIPTIONS_DAWN =              "Dawnbreaker ultimates from Fighters guild",
    TGU_DESCRIPTIONS_BARRIER =           "Barrier ultimates from Support alliance skill line",
    TGU_DESCRIPTIONS_HORN =              "Horn ultimates from Assoult alliance skill line"
}

for stringId, stringValue in pairs(strings) do
	ZO_CreateStringId(stringId, stringValue)
	SafeAddVersion(stringId, 1)
end