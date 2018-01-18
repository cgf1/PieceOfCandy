-- POC german localization file

-- Options
local strings = {
    POC_WARNING_LGS_ENABLE =             "Warnung: Aktiviere LibGroupSocket um zu senden -> /lgs 1",
    POC_OPTIONS_HEADER =                 "Optionen",
    POC_OPTIONS_DRAG_LABEL =             "Elemente verschieben",
    POC_OPTIONS_DRAG_TOOLTIP =           "Wenn die Option aktiviert ist, können alle Elemente verschoben werden.",
    POC_OPTIONS_ONLY_AVA_LABEL =         "Nur im AvA Gebiet anzeigen",
    POC_OPTIONS_ONLY_AVA_TOOLTIP =       "Wenn die Option aktiviert ist, sind alle Elemente nur in Cyrodiil (AvA) sichtbar.",
    POC_OPTIONS_USE_LGS_LABEL =          "Kommunikation via LibGroupSocket",
    POC_OPTIONS_USE_LGS_TOOLTIP =        "Wenn die Option aktiviert ist, wird versucht eine Kommunikation via LibGroupSocket aufzubauen. LibGroupSocket muss dazu separat als eigenes Addon installiert sein.",
    POC_OPTIONS_USE_SORTING_LABEL =      "Listen nach Ulti-Fortschritt sortieren",
    POC_OPTIONS_USE_SORTING_TOOLTIP =    "Wenn die Option aktiviert ist, werden alle Listen nach Ulti-Fortschritt sortiert (Volle Ultis oben).",
    POC_OPTIONS_STYLE_LABEL =            "Style auswählen",
    POC_OPTIONS_STYLE_TOOLTIP =          "Wähle den gewünschten Style aus. Simple-Liste, Schwimmbahn-Liste oder Kompakte Schwimmbahn-Liste",
    POC_OPTIONS_STYLE_SIMPLE =           "Simple-Liste",
    POC_OPTIONS_STYLE_SWIM =             "Schwimmbahn-Liste",
    POC_OPTIONS_STYLE_SHORT_SWIM =       "Kompakte Schwimmbahn-Liste",
    POC_DESCRIPTIONS_NEGATE =            "Magienegation Ultimates der Zauberer Klasse",
    POC_DESCRIPTIONS_ATRO =              "Atronach Ultimates der Zauberer Klasse",
    POC_DESCRIPTIONS_OVER =              "Überladung Ultimates der Zauberer Klasse",
    POC_DESCRIPTIONS_SWEEP =             "Schwung Ultimates der Templer Klasse",
    POC_DESCRIPTIONS_NOVA =              "Nova Ultimates der Templer Klasse",
    POC_DESCRIPTIONS_TPHEAL =            "Heil Ultimates der Templer Klasse",
    POC_DESCRIPTIONS_STAND =             "Standarten Ultimates der Drachenritter Klasse",
    POC_DESCRIPTIONS_LEAP =              "Drachensprung Ultimates der Drachenritter Klasse",
    POC_DESCRIPTIONS_MAGMA =             "Magma Ultimates der Drachenritter Klasse",
    POC_DESCRIPTIONS_STROKE =            "Todesstoß Ultimates der Nachtklingen Klasse",
    POC_DESCRIPTIONS_VEIL =              "Schleier Ultimates der Nachtklingen Klasse",
    POC_DESCRIPTIONS_NBSOUL =            "Seelenfetzen Ultimates der Nachtklingen Klasse",
    POC_DESCRIPTIONS_FREEZE =            "Sturm Ultimates der Hüter Klasse",
    POC_DESCRIPTIONS_WDHEAL =            "Hain Ultimates der Hüter Klasse",
    POC_DESCRIPTIONS_ICE =               "Frost Ultimates des Zerstörungsstabes",
    POC_DESCRIPTIONS_FIRE =              "Feuer Ultimates des Zerstörungsstabes",
    POC_DESCRIPTIONS_LIGHT =             "Blitz Ultimates des Zerstörungsstabes",
    POC_DESCRIPTIONS_STHEAL =            "Heil Ultimates des Heilstabes",
    POC_DESCRIPTIONS_BERSERK =           "Berserker Ultimates des Zweihänders",
    POC_DESCRIPTIONS_SHIELD =            "Schild Ultimates von Einhand und Schild",
    POC_DESCRIPTIONS_DUAL =              "Zerfleischen Ultimates von Zwei Waffen",
    POC_DESCRIPTIONS_BOW =               "Schnellfeuer Ultimates von Bogen",
    POC_DESCRIPTIONS_SOUL =              "Seelenschlag Ultimates aus der Seelenmagie Linie",
    POC_DESCRIPTIONS_WERE =              "Werwolfverwandlung Ultimates aus der Werwolf Linie",
    POC_DESCRIPTIONS_VAMP =              "Schwarm Ultimates aus der Vampir Linie",
    POC_DESCRIPTIONS_METEOR =            "Meteor Ultimates aus der Magiergilde",
    POC_DESCRIPTIONS_DAWN =              "Dämmerbrecher Ultimates aus der Kriegergilde",
    POC_DESCRIPTIONS_BARRIER =           "Barriere Ultimates aus der Unterstützung Linie",
    POC_DESCRIPTIONS_HORN =              "Kriegshorn Ultimates aus der Sturmangriff Linie"
}

for stringId, stringValue in pairs(strings) do
	ZO_CreateStringId(stringId, stringValue)
	SafeAddVersion(stringId, 1)
end
