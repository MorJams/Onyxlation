GLOBAL_LIST_INIT(ai_names, world.file2list("config/names/ai.txt"))
GLOBAL_LIST_INIT(wizard_first, world.file2list("config/names/wizardfirst.txt"))
GLOBAL_LIST_INIT(wizard_second, world.file2list("config/names/wizardsecond.txt"))
GLOBAL_LIST_INIT(ninja_titles, world.file2list("config/names/ninjatitle.txt"))
GLOBAL_LIST_INIT(ninja_names, world.file2list("config/names/ninjaname.txt"))
GLOBAL_LIST_INIT(commando_names, world.file2list("config/names/death_commando.txt"))
GLOBAL_LIST_INIT(first_names_male, world.file2list("config/names/first_male.txt"))
GLOBAL_LIST_INIT(first_names_female, world.file2list("config/names/first_female.txt"))
GLOBAL_LIST_INIT(last_names, world.file2list("config/names/last.txt"))
GLOBAL_LIST_INIT(clown_names, world.file2list("config/names/clown.txt"))

GLOBAL_LIST_INIT(in_character_filter, world.file2list("config/names/namefilter.txt"))

var/list/first_names_male_usmc = file2list("config/names/first_male_bund.txt")
var/list/first_names_female_usmc = file2list("config/names/first_female_bund.txt")
var/list/first_names_male_cccp = file2list("config/names/first_male_cccp.txt")
var/list/first_names_female_cccp = file2list("config/names/first_female_cccp.txt")
var/list/first_names_male_bund = file2list("config/names/first_male_bund.txt")
var/list/first_names_female_bund = file2list("config/names/first_female_bund.txt")
var/list/last_names_bund = file2list("config/names/last_male_bund.txt")
var/list/last_names_usmc = file2list("config/names/last_male_usmc.txt")
var/list/last_names_cccp = file2list("config/names/last_male_cccp.txt")
var/list/last_names_female_cccp = file2list("config/names/last_female_cccp.txt")

GLOBAL_LIST_INIT(verbs, world.file2list("config/names/verbs.txt"))
GLOBAL_LIST_INIT(adjectives, world.file2list("config/names/adjectives.txt"))
//loaded on startup because of "
//would include in rsc if ' was used
