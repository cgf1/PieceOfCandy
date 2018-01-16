-- POC german localization file

-- Options
local strings = {
    TGU_WARNING_LGS_ENABLE =             "Warnung: Aktiviere LibGroupSocket um zu senden -> /lgs 1",
    TGU_OPTIONS_HEADER =                 "Optionen",
    TGU_OPTIONS_DRAG_LABEL =             "Elemente verschieben",
    TGU_OPTIONS_DRAG_TOOLTIP =           "Wenn die Option aktiviert ist, können alle Elemente verschoben werden.",
    TGU_OPTIONS_ONLY_AVA_LABEL =         "Nur im AvA Gebiet anzeigen",
    TGU_OPTIONS_ONLY_AVA_TOOLTIP =       "Wenn die Option aktiviert ist, sind alle Elemente nur in Cyrodiil (AvA) sichtbar.",
    TGU_OPTIONS_USE_LGS_LABEL =          "Kommunikation via LibGroupSocket",
    TGU_OPTIONS_USE_LGS_TOOLTIP =        "Wenn die Option aktiviert ist, wird versucht eine Kommunikation via LibGroupSocket aufzubauen. LibGroupSocket muss dazu separat als eigenes Addon installiert sein.",
    TGU_OPTIONS_USE_SORTING_LABEL =      "Listen nach Ulti-Fortschritt sortieren",
    TGU_OPTIONS_USE_SORTING_TOOLTIP =    "Wenn die Option aktiviert ist, werden alle Listen nach Ulti-Fortschritt sortiert (Volle Ultis oben).",
    TGU_OPTIONS_STYLE_LABEL =            "Style auswählen",
    TGU_OPTIONS_STYLE_TOOLTIP =          "Wähle den gewünschten Style aus. Simple-Liste, Schwimmbahn-Liste oder Kompakte Schwimmbahn-Liste",
    TGU_OPTIONS_STYLE_SIMPLE =           "Simple-Liste",
    TGU_OPTIONS_STYLE_SWIM =             "Schwimmbahn-Liste",
    TGU_OPTIONS_STYLE_SHORT_SWIM =       "Kompakte Schwimmbahn-Liste",
    TGU_DESCRIPTIONS_NEGATE =            "Magienegation Ultimates der Zauberer Klasse",
    TGU_DESCRIPTIONS_ATRO =              "Atronach Ultimates der Zauberer Klasse",
    TGU_DESCRIPTIONS_OVER =              "Überladung Ultimates der Zauberer Klasse",
    TGU_DESCRIPTIONS_SWEEP =             "Schwung Ultimates der Templer Klasse",
    TGU_DESCRIPTIONS_NOVA =              "Nova Ultimates der Templer Klasse",
    TGU_DESCRIPTIONS_TPHEAL =            "Heil Ultimates der Templer Klasse",
    TGU_DESCRIPTIONS_STAND =             "Standarten Ultimates der Drachenritter Klasse",
    TGU_DESCRIPTIONS_LEAP =              "Drachensprung Ultimates der Drachenritter Klasse",
    TGU_DESCRIPTIONS_MAGMA =             "Magma Ultimates der Drachenritter Klasse",
    TGU_DESCRIPTIONS_STROKE =            "Todesstoß Ultimates der Nachtklingen Klasse",
    TGU_DESCRIPTIONS_VEIL =              "Schleier Ultimates der Nachtklingen Klasse",
    TGU_DESCRIPTIONS_NBSOUL =            "Seelenfetzen Ultimates der Nachtklingen Klasse",
    TGU_DESCRIPTIONS_FREEZE =            "Sturm Ultimates der Hüter Klasse",
    TGU_DESCRIPTIONS_WDHEAL =            "Hain Ultimates der Hüter Klasse",
    TGU_DESCRIPTIONS_ICE =               "Frost Ultimates des Zerstörungsstabes",
    TGU_DESCRIPTIONS_FIRE =              "Feuer Ultimates des Zerstörungsstabes",
    TGU_DESCRIPTIONS_LIGHT =             "Blitz Ultimates des Zerstörungsstabes",
    TGU_DESCRIPTIONS_STHEAL =            "Heil Ultimates des Heilstabes",
    TGU_DESCRIPTIONS_BERSERK =           "Berserker Ultimates des Zweihänders",
    TGU_DESCRIPTIONS_SHIELD =            "Schild Ultimates von Einhand und Schild",
    TGU_DESCRIPTIONS_DUAL =              "Zerfleischen Ultimates von Zwei Waffen",
    TGU_DESCRIPTIONS_BOW =               "Schnellfeuer Ultimates von Bogen",
    TGU_DESCRIPTIONS_SOUL =              "Seelenschlag Ultimates aus der Seelenmagie Linie",
    TGU_DESCRIPTIONS_WERE =              "Werwolfverwandlung Ultimates aus der Werwolf Linie",
    TGU_DESCRIPTIONS_VAMP =              "Schwarm Ultimates aus der Vampir Linie",
    TGU_DESCRIPTIONS_METEOR =            "Meteor Ultimates aus der Magiergilde",
    TGU_DESCRIPTIONS_DAWN =              "Dämmerbrecher Ultimates aus der Kriegergilde",
    TGU_DESCRIPTIONS_BARRIER =           "Barriere Ultimates aus der Unterstützung Linie",
    TGU_DESCRIPTIONS_HORN =              "Kriegshorn Ultimates aus der Sturmangriff Linie"
}

for stringId, stringValue in pairs(strings) do
	ZO_CreateStringId(stringId, stringValue)
	SafeAddVersion(stringId, 1)
end
