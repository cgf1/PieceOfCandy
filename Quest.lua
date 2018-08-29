setfenv(1, POC)
Quest = {
    Name = "POC-Quest"
}
Quest.__index = Quest

local OLDKEEP_IX = 1
local OLDRESOURCE_IX = 2
local OLDKILL_IX = 3

local AcceptSharedQuest = AcceptSharedQuest
local GetJournalQuestName = GetJournalQuestName
local GetNumJournalQuests = GetNumJournalQuests
local GetUnitName = GetUnitName
local ShareQuest = ShareQuest

local nametocat = {}
local nametoqid = {}
local qidtoname = {}
local qidtoix = {}
local ixtoname = {}

local want = {}
local have = {}
local saved

local sharequests = false

local function havequest(what, qid)
    if qid <= 0 then
	return true
    end
    for i = 1, GetNumJournalQuests() do
	local qname = GetJournalQuestName(i)
	if nametocat[qname] == what then
	    return true
	end
    end
    return false
end

local function _init()
    saved = Settings.SavedVariables
    local ref = {
	en = {
	    {3218, "keep", "Capture Chalman Keep"},
	    {3256, "resource", "Capture Chalman Mine"},
	    {3157, "kill", "Kill Enemy Players"},
	    {-1, "keep", "-- don't share keep quest --"},
	    {-2, "resource", "-- don't share resource quest --"},
	    {-3, "kill", "-- don't share kill enemy quest --"},
	    {2759, "kill", "Kill Enemy Players"},
	    {2915, "keep", "Capture Fort Warden"},
	    {2916, "keep", "Capture Fort Rayles"},
	    {2917, "keep", "Capture Fort Glademist"},
	    {2918, "keep", "Capture Fort Ash"},
	    {2919, "keep", "Capture Fort Aleswell"},
	    {2920, "keep", "Capture Fort Dragonclaw"},
	    {2921, "keep", "Capture Chalman Keep"},
	    {2922, "keep", "Capture Arrius Keep"},
	    {2923, "keep", "Capture Kingscrest Keep"},
	    {2924, "keep", "Capture Farragut Keep"},
	    {2925, "keep", "Capture Blue Road Keep"},
	    {2926, "keep", "Capture Drakelowe Keep"},
	    {2927, "keep", "Capture Castle Alessia"},
	    {2928, "keep", "Capture Castle Faregyl"},
	    {2929, "keep", "Capture Castle Roebeck"},
	    {2930, "keep", "Capture Castle Brindle"},
	    {2931, "keep", "Capture Castle Black Boot"},
	    {2932, "keep", "Capture Castle Bloodmayne"},
	    {2933, "resource", "Capture Warden Mine"},
	    {2934, "resource", "Capture Rayles Mine"},
	    {2935, "resource", "Capture Glademist Mine"},
	    {2936, "resource", "Capture Ash Mine"},
	    {2937, "resource", "Capture Aleswell Mine"},
	    {2938, "resource", "Capture Dragonclaw Mine"},
	    {2939, "resource", "Capture Chalman Mine"},
	    {2940, "resource", "Capture Arrius Mine"},
	    {2941, "resource", "Capture Kingscrest Mine"},
	    {2942, "resource", "Capture Farragut Mine"},
	    {2943, "resource", "Capture Blue Road Mine"},
	    {2944, "resource", "Capture Drakelowe Mine"},
	    {2945, "resource", "Capture Alessia Mine"},
	    {2946, "resource", "Capture Faregyl Mine"},
	    {2947, "resource", "Capture Roebeck Mine"},
	    {2950, "resource", "Capture Brindle Mine"},
	    {2951, "resource", "Capture Black Boot Mine"},
	    {2952, "resource", "Capture Bloodmayne Mine"},
	    {2953, "resource", "Capture Warden Farm"},
	    {2954, "resource", "Capture Rayles Farm"},
	    {2955, "resource", "Capture Glademist Farm"},
	    {2956, "resource", "Capture Ash Farm"},
	    {2957, "resource", "Capture Aleswell Farm"},
	    {2958, "resource", "Capture Dragonclaw Farm"},
	    {2959, "resource", "Capture Chalman Farm"},
	    {2960, "resource", "Capture Arrius Farm"},
	    {2961, "resource", "Capture Kingscrest Farm"},
	    {2962, "resource", "Capture Farragut Farm"},
	    {2963, "resource", "Capture Blue Road Farm"},
	    {2964, "resource", "Capture Drakelowe Farm"},
	    {2966, "resource", "Capture Faregyl Farm"},
	    {2967, "resource", "Capture Roebeck Farm"},
	    {2968, "resource", "Capture Brindle Farm"},
	    {2969, "resource", "Capture Black Boot Farm"},
	    {2970, "resource", "Capture Bloodmayne Farm"},
	    {2972, "resource", "Capture Warden Lumbermill"},
	    {2973, "resource", "Capture Rayles Lumbermill"},
	    {2974, "resource", "Capture Glademist Lumbermill"},
	    {2975, "resource", "Capture Ash Lumbermill"},
	    {2976, "resource", "Capture Aleswell Lumbermill"},
	    {2977, "resource", "Capture Dragonclaw Lumbermill"},
	    {2978, "resource", "Capture Chalman Lumbermill"},
	    {2979, "resource", "Capture Arrius Lumbermill"},
	    {2980, "resource", "Capture Kingscrest Lumbermill"},
	    {2981, "resource", "Capture Farragut Lumbermill"},
	    {2982, "resource", "Capture Blue Road Lumbermill"},
	    {2983, "resource", "Capture Drakelowe Lumbermill"},
	    {2984, "resource", "Capture Alessia Lumbermill"},
	    {2985, "resource", "Capture Faregyl Lumbermill"},
	    {2986, "resource", "Capture Roebeck Lumbermill"},
	    {2987, "resource", "Capture Brindle Lumbermill"},
	    {2988, "resource", "Capture Black Boot Lumbermill"},
	    {2989, "resource", "Capture Bloodmayne Lumbermill"},
	    {3083, "keep", "Capture Fort Warden"},
	    {3084, "keep", "Capture Fort Rayles"},
	    {3085, "keep", "Capture Fort Glademist"},
	    {3086, "keep", "Capture Fort Ash"},
	    {3087, "keep", "Capture Fort Aleswell"},
	    {3088, "keep", "Capture Fort Dragonclaw"},
	    {3089, "keep", "Capture Chalman Keep"},
	    {3090, "keep", "Capture Arrius Keep"},
	    {3091, "keep", "Capture Kingscrest Keep"},
	    {3092, "keep", "Capture Farragut Keep"},
	    {3093, "keep", "Capture Blue Road Keep"},
	    {3094, "keep", "Capture Drakelowe Keep"},
	    {3095, "keep", "Capture Castle Alessia"},
	    {3096, "keep", "Capture Castle Faregyl"},
	    {3097, "keep", "Capture Castle Roebeck"},
	    {3098, "keep", "Capture Castle Brindle"},
	    {3099, "keep", "Capture Castle Black Boot"},
	    {3100, "keep", "Capture Castle Bloodmayne"},
	    {3101, "resource", "Capture Warden Farm"},
	    {3102, "resource", "Capture Rayles Farm"},
	    {3103, "resource", "Capture Glademist Farm"},
	    {3104, "resource", "Capture Ash Farm"},
	    {3105, "resource", "Capture Aleswell Farm"},
	    {3106, "resource", "Capture Dragonclaw Farm"},
	    {3108, "resource", "Capture Chalman Farm"},
	    {3109, "resource", "Capture Arrius Farm"},
	    {3110, "resource", "Capture Kingscrest Farm"},
	    {3111, "resource", "Capture Farragut Farm"},
	    {3112, "resource", "Capture Blue Road Farm"},
	    {3113, "resource", "Capture Drakelowe Farm"},
	    {3114, "resource", "Capture Alessia Farm"},
	    {3115, "resource", "Capture Faregyl Farm"},
	    {3116, "resource", "Capture Roebeck Farm"},
	    {3117, "resource", "Capture Brindle Farm"},
	    {3118, "resource", "Capture Black Boot Farm"},
	    {3119, "resource", "Capture Bloodmayne Farm"},
	    {3120, "resource", "Capture Warden Mine"},
	    {3121, "resource", "Capture Rayles Mine"},
	    {3122, "resource", "Capture Glademist Mine"},
	    {3123, "resource", "Capture Ash Mine"},
	    {3124, "resource", "Capture Aleswell Mine"},
	    {3125, "resource", "Capture Dragonclaw Mine"},
	    {3126, "resource", "Capture Chalman Mine"},
	    {3127, "resource", "Capture Arrius Mine"},
	    {3128, "resource", "Capture Kingscrest Mine"},
	    {3130, "resource", "Capture Farragut Mine"},
	    {3131, "resource", "Capture Blue Road Mine"},
	    {3132, "resource", "Capture Drakelowe Mine"},
	    {3133, "resource", "Capture Alessia Mine"},
	    {3134, "resource", "Capture Faregyl Mine"},
	    {3135, "resource", "Capture Roebeck Mine"},
	    {3136, "resource", "Capture Brindle Mine"},
	    {3137, "resource", "Capture Black Boot Mine"},
	    {3138, "resource", "Capture Bloodmayne Mine"},
	    {3139, "resource", "Capture Warden Lumbermill"},
	    {3140, "resource", "Capture Rayles Lumbermill"},
	    {3141, "resource", "Capture Glademist Lumbermill"},
	    {3142, "resource", "Capture Ash Lumbermill"},
	    {3143, "resource", "Capture Aleswell Lumbermill"},
	    {3144, "resource", "Capture Dragonclaw Lumbermill"},
	    {3145, "resource", "Capture Chalman Lumbermill"},
	    {3146, "resource", "Capture Arrius Lumbermill"},
	    {3147, "resource", "Capture Kingscrest Lumbermill"},
	    {3148, "resource", "Capture Farragut Lumbermill"},
	    {3149, "resource", "Capture Blue Road Lumbermill"},
	    {3150, "resource", "Capture Drakelowe Lumbermill"},
	    {3151, "resource", "Capture Alessia Lumbermill"},
	    {3152, "resource", "Capture Faregyl Lumbermill"},
	    {3153, "resource", "Capture Roebeck Lumbermill"},
	    {3154, "resource", "Capture Brindle Lumbermill"},
	    {3155, "resource", "Capture Black Boot Lumbermill"},
	    {3156, "resource", "Capture Bloodmayne Lumbermill"},
	    {3194, "resource", "Capture Warden Farm"},
	    {3195, "resource", "Capture Rayles Farm"},
	    {3196, "resource", "Capture Glademist Farm"},
	    {3197, "resource", "Capture Ash Farm"},
	    {3198, "resource", "Capture Aleswell Farm"},
	    {3199, "resource", "Capture Dragonclaw Farm"},
	    {3200, "resource", "Capture Chalman Farm"},
	    {3201, "resource", "Capture Arrius Farm"},
	    {3202, "resource", "Capture Kingscrest Farm"},
	    {3203, "resource", "Capture Farragut Farm"},
	    {3204, "resource", "Capture Blue Road Farm"},
	    {3205, "resource", "Capture Drakelowe Farm"},
	    {3206, "resource", "Capture Alessia Farm"},
	    {3207, "resource", "Capture Faregyl Farm"},
	    {3208, "resource", "Capture Roebeck Farm"},
	    {3209, "resource", "Capture Brindle Farm"},
	    {3210, "resource", "Capture Black Boot Farm"},
	    {3211, "resource", "Capture Bloodmayne Farm"},
	    {3212, "keep", "Capture Fort Warden"},
	    {3213, "keep", "Capture Fort Rayles"},
	    {3214, "keep", "Capture Fort Glademist"},
	    {3215, "keep", "Capture Fort Ash"},
	    {3216, "keep", "Capture Fort Aleswell"},
	    {3217, "keep", "Capture Fort Dragonclaw"},
	    {3219, "keep", "Capture Arrius Keep"},
	    {3220, "keep", "Capture Kingscrest Keep"},
	    {3221, "keep", "Capture Farragut Keep"},
	    {3222, "keep", "Capture Blue Road Keep"},
	    {3223, "keep", "Capture Drakelowe Keep"},
	    {3224, "keep", "Capture Castle Alessia"},
	    {3225, "keep", "Capture Castle Faregyl"},
	    {3226, "keep", "Capture Castle Roebeck"},
	    {3227, "keep", "Capture Castle Brindle"},
	    {3228, "keep", "Capture Castle Black Boot"},
	    {3229, "keep", "Capture Castle Bloodmayne"},
	    {3231, "resource", "Capture Warden Lumbermill"},
	    {3232, "resource", "Capture Rayles Lumbermill"},
	    {3233, "resource", "Capture Glademist Lumbermill"},
	    {3234, "resource", "Capture Ash Lumbermill"},
	    {3236, "resource", "Capture Aleswell Lumbermill"},
	    {3237, "resource", "Capture Dragonclaw Lumbermill"},
	    {3238, "resource", "Capture Chalman Lumbermill"},
	    {3239, "resource", "Capture Arrius Lumbermill"},
	    {3240, "resource", "Capture Kingscrest Lumbermill"},
	    {3241, "resource", "Capture Farragut Lumbermill"},
	    {3242, "resource", "Capture Blue Road Lumbermill"},
	    {3243, "resource", "Capture Drakelowe Lumbermill"},
	    {3244, "resource", "Capture Alessia Lumbermill"},
	    {3245, "resource", "Capture Faregyl Lumbermill"},
	    {3246, "resource", "Capture Roebeck Lumbermill"},
	    {3247, "resource", "Capture Brindle Lumbermill"},
	    {3248, "resource", "Capture Black Boot Lumbermill"},
	    {3249, "resource", "Capture Bloodmayne Lumbermill"},
	    {3250, "resource", "Capture Warden Mine"},
	    {3251, "resource", "Capture Rayles Mine"},
	    {3252, "resource", "Capture Glademist Mine"},
	    {3253, "resource", "Capture Ash Mine"},
	    {3254, "resource", "Capture Aleswell Mine"},
	    {3255, "resource", "Capture Dragonclaw Mine"},
	    {3257, "resource", "Capture Arrius Mine"},
	    {3258, "resource", "Capture Kingscrest Mine"},
	    {3259, "resource", "Capture Farragut Mine"},
	    {3260, "resource", "Capture Blue Road Mine"},
	    {3261, "resource", "Capture Drakelowe Mine"},
	    {3262, "resource", "Capture Alessia Mine"},
	    {3263, "resource", "Capture Faregyl Mine"},
	    {3265, "resource", "Capture Roebeck Mine"},
	    {3266, "resource", "Capture Brindle Mine"},
	    {3268, "resource", "Capture Black Boot Mine"},
	    {3269, "resource", "Capture Bloodmayne Mine"},
	    {3390, "keep", "Capture Fort Balfiera"},
	    {3441, "keep", "Capture Fort Balfiera"},
	    {3442, "resource", "Capture Balfiera Lumbermill"},
	    {3443, "resource", "Capture BalfieraMine"},
	    {3457, "keep", "Capture Fort Balfiera"},
	    {5220, "kill", "Kill Enemy Templars"},
	    {5221, "kill", "Kill Enemy Templars"},
	    {5222, "kill", "Kill Enemy Templars"},
	    {5226, "kill", "Kill Enemy Dragonknights"},
	    {5227, "kill", "Kill Enemy Dragonknights"},
	    {5228, "kill", "Kill Enemy Dragonknights"},
	    {5229, "kill", "Kill Enemy Nightblades"},
	    {5230, "kill", "Kill Enemy Nightblades"},
	    {5231, "kill", "Kill Enemy Nightblades"},
	    {5232, "kill", "Kill Enemy Sorcerers"},
	    {5233, "kill", "Kill Enemy Sorcerers"},
	    {5234, "kill", "Kill Enemy Sorcerers"},
	    {6010, "kill", "Kill Enemy Wardens"},
	    {6011, "kill", "Kill Enemy Wardens"},
	    {6012, "kill", "Kill Enemy Wardens"},
	    {3185, "conquest", "Capture Any Nine Resources"},
	    {3186, "conquest", "Capture All 3 Towns"},
	    {3188, "conquest", "Capture Any Three Keeps"},
	    {3205, "conquest", "Kill 40 Enemy Players"}
	},
	fr = {
	    {3218, "keep", "Capturez la bastille Chalman"},
	    {3256, "resource", "Capturez la mine de Chalman"},
	    {3157, "kill", "Tuez les joueurs adverses"},
	    {-1, "keep", "-- ne partagez la quête du châteaui --"},
	    {-2, "resource", "-- ne partagez la quête de ressources --"},
	    {-3, "kill", "-- ne partagez la quête de tuer l'ennemi --"},
	    {2759, "kill", "Tuez les joueurs adverses"},
	    {2915, "keep", "Capturez fort Bayle"},
	    {2916, "keep", "Capturez fort Rayles"},
	    {2917, "keep", "Capturez fort Brumeclaire"},
	    {2918, "keep", "Capturez fort Cendre"},
	    {2919, "keep", "Capturez fort Houblon"},
	    {2920, "keep", "Capturez fort Griffe-dragon"},
	    {2921, "keep", "Capturez la bastille Chalman"},
	    {2922, "keep", "Capturez la bastille Arrius"},
	    {2923, "keep", "Capturez la bastille des Armoiries"},
	    {2924, "keep", "Capturez la bastille de Farragut"},
	    {2925, "keep", "Capturez la bastille de Sente-azur"},
	    {2926, "keep", "Capturez la bastille Malard"},
	    {2927, "keep", "Capturez le château d'Alessia"},
	    {2928, "keep", "Capturez le château Faregyl"},
	    {2929, "keep", "Capturez le château Roebeck"},
	    {2930, "keep", "Capturez le château de Bringée"},
	    {2931, "keep", "Capturez le château de Botte-Noire"},
	    {2932, "keep", "Capturez le château Crin-de-Sang"},
	    {2933, "resource", "Capturez la mine de Bayle"},
	    {2934, "resource", "Capturez la mine de Rayles"},
	    {2935, "resource", "Capturez la mine de Brumeclaire"},
	    {2936, "resource", "Capturez la mine de Cendre"},
	    {2937, "resource", "Capturez la mine de Houblon"},
	    {2938, "resource", "Capturez la mine de Griffe-dragon"},
	    {2939, "resource", "Capturez la mine de Chalman"},
	    {2940, "resource", "Capturez la mine d'Arrius"},
	    {2941, "resource", "Capturez la mine des Armoiries"},
	    {2942, "resource", "Capturez la mine de Farragut"},
	    {2943, "resource", "Capturez la mine de Sente-azur"},
	    {2944, "resource", "Capturez la mine de Malard"},
	    {2945, "resource", "Capturez la mine d'Alessia"},
	    {2946, "resource", "Capturez la mine de Faregyl"},
	    {2947, "resource", "Capturez la mine de Roebeck"},
	    {2950, "resource", "Capturez la mine de Bringée"},
	    {2951, "resource", "Capturez la mine de Botte-Noire"},
	    {2952, "resource", "Capturez la mine du Crin-de-Sang"},
	    {2953, "resource", "Capturez la ferme de Bayle"},
	    {2954, "resource", "Capturez la ferme de Rayles"},
	    {2955, "resource", "Capturez la ferme de Brumeclaire"},
	    {2956, "resource", "Capturez la ferme de Cendre"},
	    {2957, "resource", "Capturez la ferme de Houblon"},
	    {2958, "resource", "Capturez la ferme de Griffe-dragon"},
	    {2959, "resource", "Capturez la ferme de Chalman"},
	    {2960, "resource", "Capturez la ferme d'Arrius"},
	    {2961, "resource", "Capturez la ferme des Armoiries"},
	    {2962, "resource", "Capturez la ferme de Farragut"},
	    {2963, "resource", "Capturez la ferme de Sente-azur"},
	    {2964, "resource", "Capturez la ferme de Malard"},
	    {2966, "resource", "Capturez la ferme de Faregyl"},
	    {2967, "resource", "Capturez la ferme de Roebeck"},
	    {2968, "resource", "Capturez la ferme de Bringée"},
	    {2969, "resource", "Capturez la ferme de Botte-Noire"},
	    {2970, "resource", "Capturez la ferme du Crin-de-Sang"},
	    {2972, "resource", "Capturez la scierie de Bayle"},
	    {2973, "resource", "Capturez la scierie de Rayles"},
	    {2974, "resource", "Capturez la scierie de Brumeclaire"},
	    {2975, "resource", "Capturez la scierie de Cendre"},
	    {2976, "resource", "Capturez la scierie de Houblon"},
	    {2977, "resource", "Capturez la scierie de Griffe-dragon"},
	    {2978, "resource", "Capturez la scierie de Chalman"},
	    {2979, "resource", "Capturez la scierie d'Arrius"},
	    {2980, "resource", "Capturez la scierie des Armoiries"},
	    {2981, "resource", "Capturez la scierie de Farragut"},
	    {2982, "resource", "Capturez la scierie de Sente-azur"},
	    {2983, "resource", "Capturez la scierie de Malard"},
	    {2984, "resource", "Capturez la scierie d'Alessia"},
	    {2985, "resource", "Capturez la scierie de Faregyl"},
	    {2986, "resource", "Capturez la scierie de Roebeck"},
	    {2987, "resource", "Capturez la scierie de Bringée"},
	    {2988, "resource", "Capturez la scierie de Botte-Noire"},
	    {2989, "resource", "Capturez la scierie du Crin-de-Sang"},
	    {3083, "keep", "Capturez fort Bayle"},
	    {3084, "keep", "Capturez fort Rayles"},
	    {3085, "keep", "Capturez fort Brumeclaire"},
	    {3086, "keep", "Capturez fort Cendre"},
	    {3087, "keep", "Capturez fort Houblon"},
	    {3088, "keep", "Capturez fort Griffe-dragon"},
	    {3089, "keep", "Capturez la bastille Chalman"},
	    {3090, "keep", "Capturez la bastille Arrius"},
	    {3091, "keep", "Capturez la bastille des Armoiries"},
	    {3092, "keep", "Capturez la bastille Farragut"},
	    {3093, "keep", "Capturez la bastille de Sente-azur"},
	    {3094, "keep", "Capturez la bastille Malard"},
	    {3095, "keep", "Capturez le château d'Alessia"},
	    {3096, "keep", "Capturez le château Faregyl"},
	    {3097, "keep", "Capturez le château Roebeck"},
	    {3098, "keep", "Capturez le château de Bringée"},
	    {3099, "keep", "Capturez le château de Botte-Noire"},
	    {3100, "keep", "Capturez le château Crin-de-Sang"},
	    {3101, "resource", "Capturez la ferme de Bayle"},
	    {3102, "resource", "Capturez la ferme de Rayles"},
	    {3103, "resource", "Capturez la ferme de Brumeclaire"},
	    {3104, "resource", "Capturez la ferme de Cendre"},
	    {3105, "resource", "Capturez la ferme de Houblon"},
	    {3106, "resource", "Capturez la ferme de Griffe-dragon"},
	    {3108, "resource", "Capturez la ferme de Chalman"},
	    {3109, "resource", "Capturez la ferme d'Arrius"},
	    {3110, "resource", "Capturez la ferme des Armoiries"},
	    {3111, "resource", "Capturez la ferme de Farragut"},
	    {3112, "resource", "Capturez la ferme de Sente-azur"},
	    {3113, "resource", "Capturez la ferme de Malard"},
	    {3114, "resource", "Capturez la ferme d'Alessia"},
	    {3115, "resource", "Capturez la ferme de Faregyl"},
	    {3116, "resource", "Capturez la ferme de Roebeck"},
	    {3117, "resource", "Capturez la ferme de Bringée"},
	    {3118, "resource", "Capturez la ferme de Botte-Noire"},
	    {3119, "resource", "Capturez la ferme du Crin-de-Sang"},
	    {3120, "resource", "Capturez la mine de Bayle"},
	    {3121, "resource", "Capturez la mine de Rayles"},
	    {3122, "resource", "Capturez la mine de Brumeclaire"},
	    {3123, "resource", "Capturez la mine de Cendre"},
	    {3124, "resource", "Capturez la mine de Houblon"},
	    {3125, "resource", "Capturez la mine de Griffe-dragon"},
	    {3126, "resource", "Capturez la mine de Chalman"},
	    {3127, "resource", "Capturez la mine d'Arrius"},
	    {3128, "resource", "Capturez la mine des Armoiries"},
	    {3130, "resource", "Capturez la mine de Farragut"},
	    {3131, "resource", "Capturez la mine de Sente-azur"},
	    {3132, "resource", "Capturez la mine de Malard"},
	    {3133, "resource", "Capturez la mine d'Alessia"},
	    {3134, "resource", "Capturez la mine de Faregyl"},
	    {3135, "resource", "Capturez la mine de Roebeck"},
	    {3136, "resource", "Capturez la mine de Bringée"},
	    {3137, "resource", "Capturez la mine de Botte-Noire"},
	    {3138, "resource", "Capturez la mine du Crin-de-Sang"},
	    {3139, "resource", "Capturez la scierie de Bayle"},
	    {3140, "resource", "Capturez la scierie de Rayles"},
	    {3141, "resource", "Capturez la scierie de Brumeclaire"},
	    {3142, "resource", "Capturez la scierie de Cendre"},
	    {3143, "resource", "Capturez la scierie de Houblon"},
	    {3144, "resource", "Capturez la scierie de Griffe-dragon"},
	    {3145, "resource", "Capturez la scierie de Chalman"},
	    {3146, "resource", "Capturez la scierie d'Arrius"},
	    {3147, "resource", "Capturez la scierie des Armoiries"},
	    {3148, "resource", "Capturez la scierie de Farragut"},
	    {3149, "resource", "Capturez la scierie de Sente-azur"},
	    {3150, "resource", "Capturez la scierie de Malard"},
	    {3151, "resource", "Capturez la scierie d'Alessia"},
	    {3152, "resource", "Capturez la scierie de Faregyl"},
	    {3153, "resource", "Capturez la scierie de Roebeck"},
	    {3154, "resource", "Capturez la scierie de Bringée"},
	    {3155, "resource", "Capturez la scierie de Botte-Noire"},
	    {3156, "resource", "Capturez la scierie du Crin-de-Sang"},
	    {3194, "resource", "Capturez la ferme de Bayle"},
	    {3195, "resource", "Capturez la ferme de Rayles"},
	    {3196, "resource", "Capturez la ferme de Brumeclaire"},
	    {3197, "resource", "Capturez la ferme de Cendre"},
	    {3198, "resource", "Capturez la ferme de Houblon"},
	    {3199, "resource", "Capturez la ferme de Griffe-dragon"},
	    {3200, "resource", "Capturez la ferme de Chalman"},
	    {3201, "resource", "Capturez la ferme d'Arrius"},
	    {3202, "resource", "Capturez la ferme des Armoiries"},
	    {3203, "resource", "Capturez la ferme de Farragut"},
	    {3204, "resource", "Capturez la ferme de Sente-azur"},
	    {3205, "resource", "Capturez la ferme de Malard"},
	    {3206, "resource", "Capturez la ferme d'Alessia"},
	    {3207, "resource", "Capturez la ferme de Faregyl"},
	    {3208, "resource", "Capturez la ferme de Roebeck"},
	    {3209, "resource", "Capturez la ferme de Bringée"},
	    {3210, "resource", "Capturez la ferme de Botte-Noire"},
	    {3211, "resource", "Capturez la ferme du Crin-de-Sang"},
	    {3212, "keep", "Capturez fort Bayle"},
	    {3213, "keep", "Capturez fort Rayles"},
	    {3214, "keep", "Capturez fort Brumeclaire"},
	    {3215, "keep", "Capturez fort Cendre"},
	    {3216, "keep", "Capturez fort Houblon"},
	    {3217, "keep", "Capturez fort Griffe-dragon"},
	    {3219, "keep", "Capturez la bastille Arrius"},
	    {3220, "keep", "Capturez la bastille des Armoiries"},
	    {3221, "keep", "Capturez la bastille Farragut"},
	    {3222, "keep", "Capturez la bastille de Sente-azur"},
	    {3223, "keep", "Capturez la bastille Malard"},
	    {3224, "keep", "Capturez le château d'Alessia"},
	    {3225, "keep", "Capturez le château Faregyl"},
	    {3226, "keep", "Capturez le château Roebeck"},
	    {3227, "keep", "Capturez le château de Bringée"},
	    {3228, "keep", "Capturez le château de Botte-Noire"},
	    {3229, "keep", "Capturez le château Crin-de-Sang"},
	    {3231, "resource", "Capturez la scierie de Bayle"},
	    {3232, "resource", "Capturez la scierie de Rayles"},
	    {3233, "resource", "Capturez la scierie de Brumeclaire"},
	    {3234, "resource", "Capturez la scierie de Cendre"},
	    {3236, "resource", "Capturez la scierie de Houblon"},
	    {3237, "resource", "Capturez la scierie de Griffe-dragon"},
	    {3238, "resource", "Capturez la scierie de Chalman"},
	    {3239, "resource", "Capturez la scierie d'Arrius"},
	    {3240, "resource", "Capturez la scierie des Armoiries"},
	    {3241, "resource", "Capturez la scierie de Farragut"},
	    {3242, "resource", "Capturez la scierie de Sente-azur"},
	    {3243, "resource", "Capturez la scierie de Malard"},
	    {3244, "resource", "Capturez la scierie d'Alessia"},
	    {3245, "resource", "Capturez la scierie de Faregyl"},
	    {3246, "resource", "Capturez la scierie de Roebeck"},
	    {3247, "resource", "Capturez la scierie de Bringée"},
	    {3248, "resource", "Capturez la scierie de Botte-Noire"},
	    {3249, "resource", "Capturez la scierie du Crin-de-Sang"},
	    {3250, "resource", "Capturez la mine de Bayle"},
	    {3251, "resource", "Capturez la mine de Rayles"},
	    {3252, "resource", "Capturez la mine de Brumeclaire"},
	    {3253, "resource", "Capturez la mine de Cendre"},
	    {3254, "resource", "Capturez la mine de Houblon"},
	    {3255, "resource", "Capturez la mine de Griffe-dragon"},
	    {3257, "resource", "Capturez la mine d'Arrius"},
	    {3258, "resource", "Capturez la mine des Armoiries"},
	    {3259, "resource", "Capturez la mine de Farragut"},
	    {3260, "resource", "Capturez la mine de Sente-azur"},
	    {3261, "resource", "Capturez la mine de Malard"},
	    {3262, "resource", "Capturez la mine d'Alessia"},
	    {3263, "resource", "Capturez la mine de Faregyl"},
	    {3265, "resource", "Capturez la mine de Roebeck"},
	    {3266, "resource", "Capturez la mine de Bringée"},
	    {3268, "resource", "Capturez la mine de Botte-Noire"},
	    {3269, "resource", "Capturez la mine du Crin-de-Sang"},
	    {3390, "keep", "Capture Fort Balfiera"},
	    {3441, "keep", "Capture Fort Balfiera"},
	    {3442, "resource", "Capture Balfiera Lumbermill"},
	    {3443, "resource", "Capture BalfieraMine"},
	    {3457, "keep", "Capture Fort Balfiera"},
	    {5220, "kill", "Tuez les templiers ennemis"},
	    {5221, "kill", "Tuez les templiers ennemis"},
	    {5222, "kill", "Tuez les templiers ennemis"},
	    {5226, "kill", "Tuez des Chevaliers-dragons ennemis"},
	    {5227, "kill", "Tuez des Chevaliers-dragons ennemis"},
	    {5228, "kill", "Tuez des Chevaliers-dragons ennemis"},
	    {5229, "kill", "Tuez des Lames noires ennemis"},
	    {5230, "kill", "Tuez des Lames noires ennemis"},
	    {5231, "kill", "Tuez des Lames noires ennemis"},
	    {5232, "kill", "Tuez des Sorciers ennemis"},
	    {5233, "kill", "Tuez des Sorciers ennemis"},
	    {5234, "kill", "Tuez des Sorciers ennemis"},
	    {6010, "kill", "Tuez les gardiens ennemis"},
	    {6011, "kill", "Tuez les gardiens ennemis"},
	    {6012, "kill", "Tuez les gardiens ennemis"},
	    {3185, "conquest", "Capturez neuf ressources différentes"},
	    {3186, "conquest", "Capturez les 3 villes"},
	    {3188, "conquest", "Capturez trois forts différents"},
	    {3205, "conquest", "Tuez 40 joueurs adverses"}
	},
	de = {
	    {3218, "keep", "Erobert die Burg Chalman"},
	    {3256, "resource", "Erobert die Chalman-Mine"},
	    {3157, "kill", "Tötet feindliche Spieler"},
	    {-1, "keep", "-- nicht Kasten Quest teilen --"},
	    {-2, "resource", "-- nicht Ressource Quest teilen --"},
	    {-3, "kill", "-- nicht töten Feind Quest teilen--"},
	    {2759, "kill", "Tötet feindliche Spieler"},
	    {2915, "keep", "Erobert die Feste Obhut"},
	    {2916, "keep", "Erobert die Feste Rayles"},
	    {2917, "keep", "Erobert die Feste Aunebel"},
	    {2918, "keep", "Erobert die Feste Asch"},
	    {2919, "keep", "Erobert die Feste Alebrunn"},
	    {2920, "keep", "Erobert die Feste Drachenklaue"},
	    {2921, "keep", "Erobert die Burg Chalman"},
	    {2922, "keep", "Erobert die Burg Arrius"},
	    {2923, "keep", "Erobert die Burg Königsbanner"},
	    {2924, "keep", "Erobert die Burg Farragut"},
	    {2925, "keep", "Erobert die Burg Blauweg"},
	    {2926, "keep", "Erobert die Burg Drakenschein"},
	    {2927, "keep", "Erobert das Kastell Alessia"},
	    {2928, "keep", "Erobert das Kastell Faregyl"},
	    {2929, "keep", "Erobert das Kastell Roebeck"},
	    {2930, "keep", "Erobert das Kastell Brindell"},
	    {2931, "keep", "Erobert das Kastell Schwarzstiefel"},
	    {2932, "keep", "Erobert das Kastell Blutmähne"},
	    {2933, "resource", "Erobert die Obhut-Mine"},
	    {2934, "resource", "Erobert die Rayles-Mine"},
	    {2935, "resource", "Erobert die Aunebel-Mine"},
	    {2936, "resource", "Erobert die Asch-Mine"},
	    {2937, "resource", "Erobert die Alebrunn-Mine"},
	    {2938, "resource", "Erobert die Drachenklaue-Mine"},
	    {2939, "resource", "Erobert die Chalman-Mine"},
	    {2940, "resource", "Erobert die Arrius-Mine"},
	    {2941, "resource", "Erobert die Königsbanner-Mine"},
	    {2942, "resource", "Erobert die Farragut-Mine"},
	    {2943, "resource", "Erobert die Blauweg-Mine"},
	    {2944, "resource", "Erobert die Drakenschein-Mine"},
	    {2945, "resource", "Erobert die Alessia-Mine"},
	    {2946, "resource", "Erobert die Faregyl-Mine"},
	    {2947, "resource", "Erobert die Roebeck-Mine"},
	    {2950, "resource", "Erobert die Brindell-Mine"},
	    {2951, "resource", "Erobert die Schwarzstiefel-Mine"},
	    {2952, "resource", "Erobert die Blutmähne-Mine"},
	    {2953, "resource", "Erobert den Obhut-Bauernhof"},
	    {2954, "resource", "Erobert den Rayles-Bauernhof"},
	    {2955, "resource", "Erobert den Aunebel-Bauernhof"},
	    {2956, "resource", "Erobert den Asch-Bauernhof"},
	    {2957, "resource", "Erobert den Alebrunn-Bauernhof"},
	    {2958, "resource", "Erobert den Drachenklaue-Bauernhof"},
	    {2959, "resource", "Erobert den Chalman-Bauernhof"},
	    {2960, "resource", "Erobert den Arrius-Bauernhof"},
	    {2961, "resource", "Erobert den Königsbanner-Bauernhof"},
	    {2962, "resource", "Erobert den Farragut-Bauernhof"},
	    {2963, "resource", "Erobert den Blauweg-Bauernhof"},
	    {2964, "resource", "Erobert den Drakenschein-Bauernhof"},
	    {2966, "resource", "Erobert den Faregyl-Bauernhof"},
	    {2967, "resource", "Erobert den Roebeck-Bauernhof"},
	    {2968, "resource", "Erobert den Brindell-Bauernhof"},
	    {2969, "resource", "Erobert den Schwarzstiefel-Bauernhof"},
	    {2970, "resource", "Erobert den Blutmähne-Bauernhof"},
	    {2972, "resource", "Erobert das Obhut-Holzfällerlager"},
	    {2973, "resource", "Erobert das Rayles-Holzfällerlager"},
	    {2974, "resource", "Erobert das Aunebel-Holzfällerlager"},
	    {2975, "resource", "Erobert das Asch-Holzfällerlager"},
	    {2976, "resource", "Erobert das Alebrunn-Holzfällerlager"},
	    {2977, "resource", "Erobert das Drachenklaue-Holzfällerlager"},
	    {2978, "resource", "Erobert das Chalman-Holzfällerlager"},
	    {2979, "resource", "Erobert das Arrius-Holzfällerlager"},
	    {2980, "resource", "Erobert das Königsbanner-Holzfällerlager"},
	    {2981, "resource", "Erobert das Farragut-Holzfällerlager"},
	    {2982, "resource", "Erobert das Blauweg-Holzfällerlager"},
	    {2983, "resource", "Erobert das Drakenschein-Holzfällerlager"},
	    {2984, "resource", "Erobert das Alessia-Holzfällerlager"},
	    {2985, "resource", "Erobert das Faregyl-Holzfällerlager"},
	    {2986, "resource", "Erobert das Roebeck-Holzfällerlager"},
	    {2987, "resource", "Erobert das Brindell-Holzfällerlager"},
	    {2988, "resource", "Erobert das Schwarzstiefel-Holzfällerlager"},
	    {2989, "resource", "Erobert das Blutmähne-Holzfällerlager"},
	    {3083, "keep", "Erobert die Feste Obhut"},
	    {3084, "keep", "Erobert die Feste Rayles"},
	    {3085, "keep", "Erobert die Feste Aunebel"},
	    {3086, "keep", "Erobert die Feste Asch"},
	    {3087, "keep", "Erobert die Feste Alebrunn"},
	    {3088, "keep", "Erobert die Feste Drachenklaue"},
	    {3089, "keep", "Erobert die Burg Chalman"},
	    {3090, "keep", "Erobert die Burg Arrius"},
	    {3091, "keep", "Erobert die Burg Königsbanner"},
	    {3092, "keep", "Erobert die Burg Farragut"},
	    {3093, "keep", "Erobert die Burg Blauweg"},
	    {3094, "keep", "Erobert die Burg Drakenschein"},
	    {3095, "keep", "Erobert das Kastell Alessia"},
	    {3096, "keep", "Erobert das Kastell Faregyl"},
	    {3097, "keep", "Erobert das Kastell Roebeck"},
	    {3098, "keep", "Erobert das Kastell Brindell"},
	    {3099, "keep", "Erobert das Kastell Schwarzstiefel"},
	    {3100, "keep", "Erobert das Kastell Blutmähne"},
	    {3101, "resource", "Erobert den Obhut-Bauernhof"},
	    {3102, "resource", "Erobert den Rayles-Bauernhof"},
	    {3103, "resource", "Erobert den Aunebel-Bauernhof"},
	    {3104, "resource", "Erobert den Asch-Bauernhof"},
	    {3105, "resource", "Erobert den Alebrunn-Bauernhof"},
	    {3106, "resource", "Erobert den Drachenklaue-Bauernhof"},
	    {3108, "resource", "Erobert den Chalman-Bauernhof"},
	    {3109, "resource", "Erobert den Arrius-Bauernhof"},
	    {3110, "resource", "Erobert den Königsbanner-Bauernhof"},
	    {3111, "resource", "Erobert den Farragut-Bauernhof"},
	    {3112, "resource", "Erobert den Blauweg-Bauernhof"},
	    {3113, "resource", "Erobert den Drakenschein-Bauernhof"},
	    {3114, "resource", "Erobert den Alessia-Bauernhof"},
	    {3115, "resource", "Erobert den Faregyl-Bauernhof"},
	    {3116, "resource", "Erobert den Roebeck-Bauernhof"},
	    {3117, "resource", "Erobert den Brindell-Bauernhof"},
	    {3118, "resource", "Erobert den Schwarzstiefel-Bauernhof"},
	    {3119, "resource", "Erobert den Blutmähne-Bauernhof"},
	    {3120, "resource", "Erobert die Obhut-Mine"},
	    {3121, "resource", "Erobert die Rayles-Mine"},
	    {3122, "resource", "Erobert die Aunebel-Mine"},
	    {3123, "resource", "Erobert die Asch-Mine"},
	    {3124, "resource", "Erobert die Alebrunn-Mine"},
	    {3125, "resource", "Erobert die Drachenklaue-Mine"},
	    {3126, "resource", "Erobert die Chalman-Mine"},
	    {3127, "resource", "Erobert die Arrius-Mine"},
	    {3128, "resource", "Erobert die Königsbanner-Mine"},
	    {3130, "resource", "Erobert die Farragut-Mine"},
	    {3131, "resource", "Erobert die Blauweg-Mine"},
	    {3132, "resource", "Erobert die Drakenschein-Mine"},
	    {3133, "resource", "Erobert die Alessia-Mine"},
	    {3134, "resource", "Erobert die Faregyl-Mine"},
	    {3135, "resource", "Erobert die Roebeck-Mine"},
	    {3136, "resource", "Erobert die Brindell-Mine"},
	    {3137, "resource", "Erobert die Schwarzstiefel-Mine"},
	    {3138, "resource", "Erobert die Blutmähne-Mine"},
	    {3139, "resource", "Erobert das Obhut-Holzfällerlager"},
	    {3140, "resource", "Erobert das Rayles-Holzfällerlager"},
	    {3141, "resource", "Erobert das Aunebel-Holzfällerlager"},
	    {3142, "resource", "Erobert das Asch-Holzfällerlager"},
	    {3143, "resource", "Erobert das Alebrunn-Holzfällerlager"},
	    {3144, "resource", "Erobert das Drachenklaue-Holzfällerlager"},
	    {3145, "resource", "Erobert das Chalman-Holzfällerlager"},
	    {3146, "resource", "Erobert das Arrius-Holzfällerlager"},
	    {3147, "resource", "Erobert das Königsbanner-Holzfällerlager"},
	    {3148, "resource", "Erobert das Farragut-Holzfällerlager"},
	    {3149, "resource", "Erobert das Blauweg-Holzfällerlager"},
	    {3150, "resource", "Erobert das Drakenschein-Holzfällerlager"},
	    {3151, "resource", "Erobert das Alessia-Holzfällerlager"},
	    {3152, "resource", "Erobert das Faregyl-Holzfällerlager"},
	    {3153, "resource", "Erobert das Roebeck-Holzfällerlager"},
	    {3154, "resource", "Erobert das Brindell-Holzfällerlager"},
	    {3155, "resource", "Erobert das Schwarzstiefel-Holzfällerlager"},
	    {3156, "resource", "Erobert das Blutmähne-Holzfällerlager"},
	    {3194, "resource", "Erobert den Obhut-Bauernhof"},
	    {3195, "resource", "Erobert den Rayles-Bauernhof"},
	    {3196, "resource", "Erobert den Aunebel-Bauernhof"},
	    {3197, "resource", "Erobert den Asch-Bauernhof"},
	    {3198, "resource", "Erobert den Alebrunn-Bauernhof"},
	    {3199, "resource", "Erobert den Drachenklaue-Bauernhof"},
	    {3200, "resource", "Erobert den Chalman-Bauernhof"},
	    {3201, "resource", "Erobert den Arrius-Bauernhof"},
	    {3202, "resource", "Erobert den Königsbanner-Bauernhof"},
	    {3203, "resource", "Erobert den Farragut-Bauernhof"},
	    {3204, "resource", "Erobert den Blauweg-Bauernhof"},
	    {3205, "resource", "Erobert den Drakenschein-Bauernhof"},
	    {3206, "resource", "Erobert den Alessia-Bauernhof"},
	    {3207, "resource", "Erobert den Faregyl-Bauernhof"},
	    {3208, "resource", "Erobert den Roebeck-Bauernhof"},
	    {3209, "resource", "Erobert den Brindell-Bauernhof"},
	    {3210, "resource", "Erobert den Schwarzstiefel-Bauernhof"},
	    {3211, "resource", "Erobert den Blutmähne-Bauernhof"},
	    {3212, "keep", "Erobert die Feste Obhut"},
	    {3213, "keep", "Erobert die Feste Rayles"},
	    {3214, "keep", "Erobert die Feste Aunebel"},
	    {3215, "keep", "Erobert die Feste Asch"},
	    {3216, "keep", "Erobert die Feste Alebrunn"},
	    {3217, "keep", "Erobert die Feste Drachenklaue"},
	    {3219, "keep", "Erobert die Burg Arrius"},
	    {3220, "keep", "Erobert die Burg Königsbanner"},
	    {3221, "keep", "Erobert die Burg Farragut"},
	    {3222, "keep", "Erobert die Burg Blauweg"},
	    {3223, "keep", "Erobert die Burg Drakenschein"},
	    {3224, "keep", "Erobert das Kastell Alessia"},
	    {3225, "keep", "Erobert das Kastell Faregyl"},
	    {3226, "keep", "Erobert das Kastell Roebeck"},
	    {3227, "keep", "Erobert das Kastell Brindell"},
	    {3228, "keep", "Erobert das Kastell Schwarzstiefel"},
	    {3229, "keep", "Erobert das Kastell Blutmähne"},
	    {3231, "resource", "Erobert das Obhut-Holzfällerlager"},
	    {3232, "resource", "Erobert das Rayles-Holzfällerlager"},
	    {3233, "resource", "Erobert das Aunebel-Holzfällerlager"},
	    {3234, "resource", "Erobert das Asch-Holzfällerlager"},
	    {3236, "resource", "Erobert das Alebrunn-Holzfällerlager"},
	    {3237, "resource", "Erobert das Drachenklaue-Holzfällerlager"},
	    {3238, "resource", "Erobert das Chalman-Holzfällerlager"},
	    {3239, "resource", "Erobert das Arrius-Holzfällerlager"},
	    {3240, "resource", "Erobert das Königsbanner-Holzfällerlager"},
	    {3241, "resource", "Erobert das Farragut-Holzfällerlager"},
	    {3242, "resource", "Erobert das Blauweg-Holzfällerlager"},
	    {3243, "resource", "Erobert das Drakenschein-Holzfällerlager"},
	    {3244, "resource", "Erobert das Alessia-Holzfällerlager"},
	    {3245, "resource", "Erobert das Faregyl-Holzfällerlager"},
	    {3246, "resource", "Erobert das Roebeck-Holzfällerlager"},
	    {3247, "resource", "Erobert das Brindell-Holzfällerlager"},
	    {3248, "resource", "Erobert das Schwarzstiefel-Holzfällerlager"},
	    {3249, "resource", "Erobert das Blutmähne-Holzfällerlager"},
	    {3250, "resource", "Erobert die Obhut-Mine"},
	    {3251, "resource", "Erobert die Rayles-Mine"},
	    {3252, "resource", "Erobert die Aunebel-Mine"},
	    {3253, "resource", "Erobert die Asch-Mine"},
	    {3254, "resource", "Erobert die Alebrunn-Mine"},
	    {3255, "resource", "Erobert die Drachenklaue-Mine"},
	    {3257, "resource", "Erobert die Arrius-Mine"},
	    {3258, "resource", "Erobert die Königsbanner-Mine"},
	    {3259, "resource", "Erobert die Farragut-Mine"},
	    {3260, "resource", "Erobert die Blauweg-Mine"},
	    {3261, "resource", "Erobert die Drakenschein-Mine"},
	    {3262, "resource", "Erobert die Alessia-Mine"},
	    {3263, "resource", "Erobert die Faregyl-Mine"},
	    {3265, "resource", "Erobert die Roebeck-Mine"},
	    {3266, "resource", "Erobert die Brindell-Mine"},
	    {3268, "resource", "Erobert die Schwarzstiefel-Mine"},
	    {3269, "resource", "Erobert die Blutmähne-Mine"},
	    {3390, "keep", "Capture Fort Balfiera"},
	    {3441, "keep", "Capture Fort Balfiera"},
	    {3442, "resource", "Capture Balfiera Lumbermill"},
	    {3443, "resource", "Capture BalfieraMine"},
	    {3457, "keep", "Capture Fort Balfiera"},
	    {5220, "kill", "Tötet feindliche Templer"},
	    {5221, "kill", "Tötet feindliche Templer"},
	    {5222, "kill", "Tötet feindliche Templer"},
	    {5226, "kill", "Tötet feindliche Drachenritter"},
	    {5227, "kill", "Tötet feindliche Drachenritter"},
	    {5228, "kill", "Tötet feindliche Drachenritter"},
	    {5229, "kill", "Tötet feindliche Nachtklingen"},
	    {5230, "kill", "Tötet feindliche Nachtklingen"},
	    {5231, "kill", "Tötet feindliche Nachtklingen"},
	    {5232, "kill", "Tötet feindliche Zauberer"},
	    {5233, "kill", "Tötet feindliche Zauberer"},
	    {5234, "kill", "Tötet feindliche Zauberer"},
	    {6010, "kill", "Tötet gegnerische Hüter"},
	    {6011, "kill", "Tötet gegnerische Hüter"},
	    {6012, "kill", "Tötet gegnerische Hüter"},
	    {3185, "conquest", "Nehmt neun beliebige Betriebe ein"},
	    {3186, "conquest", "Nehmt alle 3 Siedlungen ein"},
	    {3188, "conquest", "Erobert drei beliebige Burgen"},
	    {3205, "conquest", "Tötet 40 feindliche Spieler"}
	}
    }

    sharequests = saved.ShareQuests

    local lang = GetCVar('Language.2')
    local quests = ref[lang]
    if quests == nil then
	Error(string.format("Sorry.  Can't handle language \"%s\".  Quest handling disabled.", lang))
	sharequests = false
	return
    end

    -- easy lookup for quest type, quest id, quest qid
    for i, t in ipairs(quests) do
	local qid, cat, qname = unpack(t)
	if not nametocat[qname] then
	    nametocat[qname] = cat
	    nametoqid[qname] = qid
	    ixtoname[#ixtoname + 1] = qname
	end
	qidtoix[qid] = #ixtoname
	qidtoname[qid] = qname
    end

    local default = next(saved.Quests) == nil
    if default or saved.Quests[OLDKEEP_IX] then
	saved.Quests['keep'] = quests[OLDKEEP_IX][1]
	saved.Quests[OLDKEEP_IX] = nil
    end
    if default or saved.Quests[OLDKILL_IX] then
	saved.Quests['kill'] = quests[OLDKILL_IX][1]
	saved.Quests[OLDKILL_IX] = nil
    end
    if default or saved.Quests[OLDRESOURCE_IX] then
	saved.Quests['resource'] = quests[OLDRESOURCE_IX][1]
	saved.Quests[OLDRESOURCE_IX] = nil
    end

    want = {}
    for what, qid in pairs(saved.Quests) do
	want[qidtoname[qid]] = qid
	have[what] = havequest(what, qid)
    end
    _init = function() end
end

local function quest_shared(eventcode, qid)
    local qname = GetOfferedQuestShareInfo(qid)
    watch('quest_shared', qid, '=', qname, want[qname])

    if sharequests and qname and want[qname] then
	Info("Automatically accepted:", qname)
	AcceptSharedQuest(qid)
	have[nametocat[qname]] = true
    end
end

local function quest_added(_, _, qname)
    local cat = nametocat[qname]
    if cat then
	watch("quest_added", cat, '=',	qname)
	have[cat] = true
    end
end

-- 131092 false 3 Capture Chalman Keep 37 294967291 3089
-- 131092 false 4 Capture Chalman Mine 37 294967291 3126
local function quest_gone(eventcode, completed, jix, qname, zix, poiIndex, qid)
    local cat = nametocat[qname]
    if cat then
	watch("quest_gone", "tracked quest gone", qid, qname)
	have[cat] = false
    end
end

function Quest.Process(player, ix)
    watch("Quest.Process", player, ix)
    if ix <= 0 then
	watch("Quest.Process", "zero quest ix?	shouldn't happen")
	return
    end
    if player == COMM_ALL_PLAYERS then
	-- everyone plays
    else
	local groupn = "group" .. player
	if GetUnitName(groupn) ~= myname then
	    return
	end
    end
    local qname = ixtoname[ix]
    if sharequests and qname then
	for i = 1, GetNumJournalQuests() do
	    if GetJournalQuestName(i) == qname then
		-- Info(zo_strformat("Sharing quest <<1>>", GetJournalQuestName(i)))
		ShareQuest(i)
		return
	    end
	end
    end
end

function Quest.Ping()
    for cat, gotit in pairs(have) do
	if gotit then
	    watch("Quest.Ping", "already have", cat)
	else
	    local qid = saved.Quests[cat]
	    if qid <= 0 then
		watch("Quest.Ping", "ignoring", cat)
	    else
		local ix = qidtoix[qid]
		watch("Quest.Ping", "need", cat, qid, ix)
		Comm.Send(COMM_TYPE_NEEDQUEST, COMM_ALL_PLAYERS, ix)
	    end
	end
    end
end

function Quest.ShareThem(x)
    if x ~= nil and x == true or x == 'on' then
	sharequests = true
    elseif x == false or x == "off" or x == "false" or x == "no" then
	sharequests = false
    end
    saved.ShareQuests = sharequests
end

function Quest.Choices(incat)
    _init()
    local t = {}
    local seen = {}
    for qname, cat in pairs(nametocat) do
	if cat == incat and not seen[qname] then
	    t[#t + 1] = qname
	    seen[qname] = true
	end
    end
    table.sort(t)
    return t
end

function Quest.Want(what, val)
    _init()
    if not val then
	local name = qidtoname[saved.Quests[what]]
	return name
    else
	local qid = nametoqid[val]
	-- clear old want
	for qname, _ in pairs(want) do
	    if nametocat[qname] == what then
		want[qname] = nil
		break
	    end
	end
	saved.Quests[what] = qid
	want[val] = qid
	have[what] = havequest(what, qid)
    end
end

function Quest.Initialize()
    _init()
    EVENT_MANAGER:RegisterForEvent(Quest.Name, EVENT_QUEST_REMOVED, quest_gone)
    EVENT_MANAGER:RegisterForEvent(Quest.Name, EVENT_QUEST_SHARED, quest_shared)
    EVENT_MANAGER:RegisterForEvent(Quest.Name, EVENT_QUEST_ADDED, quest_added)
    saved.ChalKeep = nil
    saved.ChalMine = nil

    Slash("quest", "turn off quest sharing", function (x)
	if x ~= '' then
	    Quest.ShareThem(x)
	end
	Info("Quest sharing:", sharequests)
    end)
end
