-- POC french localization file

-- Options
local strings = {
    POC_WARNING_LGS_ENABLE =             "Warning: Enable LibGroupSocket to send -> /lgs 1",
    POC_OPTIONS_HEADER =                 "Options",
    POC_OPTIONS_DRAG_LABEL =             "Drag elements",
    POC_OPTIONS_DRAG_TOOLTIP =           "If activated, you can drag all elements.",
    POC_OPTIONS_ONLY_AVA_LABEL =         "Show only in AvA",
    POC_OPTIONS_ONLY_AVA_TOOLTIP =       "If activated, all elements will only be visible in Cyrodiil (AvA).",
    POC_OPTIONS_USE_LGS_LABEL =          "Communication via LibGroupSocket",
    POC_OPTIONS_USE_LGS_TOOLTIP =        "If activated, the addon will try to activate communication via LibGroupSocket. LibGroupSocket must be installed as own addon.",
    POC_OPTIONS_USE_SORTING_LABEL =      "Sort lists by ultimate progress",
    POC_OPTIONS_USE_SORTING_TOOLTIP =    "If activated, all lists will be sorted by ultimate progress (Maximum on top).",
    POC_OPTIONS_STYLE_LABEL =            "Choose style",
    POC_OPTIONS_STYLE_TOOLTIP =          "Choose your style. Simple-List, Swimlane-List or Compact Swimlane-List",
    POC_OPTIONS_STYLE_SIMPLE =           "Simple-List",
    POC_OPTIONS_STYLE_SWIM =             "Swimlane-List",
    POC_OPTIONS_STYLE_SHORT_SWIM =       "Compact Swimlane-List",
    POC_DESCRIPTIONS_NEGATE =            "Negate ultimates from Sorcerer class",
    POC_DESCRIPTIONS_ATRO =              "Atronach ultimates from Sorcerer class",
    POC_DESCRIPTIONS_OVER =              "Overload ultimates from Sorcerer class",
    POC_DESCRIPTIONS_SWEEP =             "Sweep ultimates from Templar class",
    POC_DESCRIPTIONS_NOVA =              "Nova ultimates from Templar class",
    POC_DESCRIPTIONS_TPHEAL =            "Heal ultimates from Templar class",
    POC_DESCRIPTIONS_STAND =             "Standard ultimates from Dragonknight class",
    POC_DESCRIPTIONS_LEAP =              "Leap ultimates from Dragonknight class",
    POC_DESCRIPTIONS_MAGMA =             "Magma ultimates from Dragonknight class",
    POC_DESCRIPTIONS_STROKE =            "Death Stroke ultimates from Nightblade class",
    POC_DESCRIPTIONS_VEIL =              "Veil of Blades ultimates from Nightblade class",
    POC_DESCRIPTIONS_NBSOUL =            "Soul ultimates from Nightblade class",
    POC_DESCRIPTIONS_FREEZE =            "Storm ultimates from Warden class",
    POC_DESCRIPTIONS_WDHEAL =            "Heal ultimates from Warden class",
    POC_DESCRIPTIONS_ICE =               "Ice ultimates from Destruction Staff weapon",
    POC_DESCRIPTIONS_FIRE =              "Fire ultimates from Destruction Staff weapon",
    POC_DESCRIPTIONS_LIGHT =             "Lightning ultimates from Destruction Staff weapon",
    POC_DESCRIPTIONS_STHEAL =            "Heal ultimates from Healing Staff weapon",
    POC_DESCRIPTIONS_BERSERK =           "2H ultimates from 2H line",
    POC_DESCRIPTIONS_SHIELD =            "Shield ultimates from shield line",
    POC_DESCRIPTIONS_DUAL =              "Dual wield ultimates from dual wield line",
    POC_DESCRIPTIONS_BOW =               "Bow ultimates from bow line",
    POC_DESCRIPTIONS_SOUL =              "Soul magic ultimates from soul line",
    POC_DESCRIPTIONS_WERE =              "Werewolf ultimates from werewolf line",
    POC_DESCRIPTIONS_VAMP =              "Vamp ultimates from vamp line",
    POC_DESCRIPTIONS_METEOR =            "Meteor ultimates from Mages guild",
    POC_DESCRIPTIONS_DAWN =              "Dawnbreaker ultimates from Fighters guild",
    POC_DESCRIPTIONS_BARRIER =           "Barrier ultimates from Support alliance skill line",
    POC_DESCRIPTIONS_HORN =              "Horn ultimates from Assoult alliance skill line"
}

for stringId, stringValue in pairs(strings) do
	ZO_CreateStringId(stringId, stringValue)
	SafeAddVersion(stringId, 1)
end
