/*
Asset cache quick users guide:

Make a datum at the bottom of this file with your assets for your thing.
The simple subsystem will most like be of use for most cases.
Then call get_asset_datum() with the type of the datum you created and store the return
Then call .send(client) on that stored return value.

You can set verify to TRUE if you want send() to sleep until the client has the assets.
*/


// Amount of time(ds) MAX to send per asset, if this get exceeded we cancel the sleeping.
// This is doubled for the first asset, then added per asset after
#define ASSET_CACHE_SEND_TIMEOUT 7

//When sending mutiple assets, how many before we give the client a quaint little sending resources message
#define ASSET_CACHE_TELL_CLIENT_AMOUNT 8

//When passively preloading assets, how many to send at once? Too high creates noticable lag where as too low can flood the client's cache with "verify" files
#define ASSET_CACHE_PRELOAD_CONCURRENT 3

/client
	var/list/cache = list() // List of all assets sent to this client by the asset cache.
	var/list/completed_asset_jobs = list() // List of all completed jobs, awaiting acknowledgement.
	var/list/sending = list()
	var/last_asset_job = 0 // Last job done.

//This proc sends the asset to the client, but only if it needs it.
//This proc blocks(sleeps) unless verify is set to false
/proc/send_asset(var/client/client, var/asset_name, var/verify = TRUE, var/check_cache = TRUE)
	if(!istype(client))
		if(ismob(client))
			var/mob/M = client
			if(M.client)
				client = M.client

			else
				return 0

		else
			return 0

	if(check_cache && (client.cache.Find(asset_name) || client.sending.Find(asset_name)))
		return 0

	client << browse_rsc(SSassets.cache[asset_name], asset_name)
	if(!verify) // Can't access the asset cache browser, rip.
		client.cache += asset_name
		return 1

	client.sending |= asset_name
	var/job = ++client.last_asset_job

	client << browse({"
	<script>
		window.location.href="?asset_cache_confirm_arrival=[job]"
	</script>
	"}, "window=asset_cache_browser")

	var/t = 0
	var/timeout_time = (ASSET_CACHE_SEND_TIMEOUT * client.sending.len) + ASSET_CACHE_SEND_TIMEOUT
	while(client && !client.completed_asset_jobs.Find(job) && t < timeout_time) // Reception is handled in Topic()
		sleep(1) // Lock up the caller until this is received.
		t++

	if(client)
		client.sending -= asset_name
		client.cache |= asset_name
		client.completed_asset_jobs -= job

	return 1

//This proc blocks(sleeps) unless verify is set to false
/proc/send_asset_list(var/client/client, var/list/asset_list, var/verify = TRUE)
	if(!istype(client))
		if(ismob(client))
			var/mob/M = client
			if(M.client)
				client = M.client

			else
				return 0

		else
			return 0

	var/list/unreceived = asset_list - (client.cache + client.sending)
	if(!unreceived || !unreceived.len)
		return 0
	if (unreceived.len >= ASSET_CACHE_TELL_CLIENT_AMOUNT)
		to_chat(client, "Sending Resources...")
	for(var/asset in unreceived)
		if(asset in SSassets.cache)
			client << browse_rsc(SSassets.cache[asset], asset)

	if(!verify) // Can't access the asset cache browser, rip.
		client.cache += unreceived
		return 1

	client.sending |= unreceived
	var/job = ++client.last_asset_job

	client << browse({"
	<script>
		window.location.href="?asset_cache_confirm_arrival=[job]"
	</script>
	"}, "window=asset_cache_browser")

	var/t = 0
	var/timeout_time = ASSET_CACHE_SEND_TIMEOUT * client.sending.len
	while(client && !client.completed_asset_jobs.Find(job) && t < timeout_time) // Reception is handled in Topic()
		sleep(1) // Lock up the caller until this is received.
		t++

	if(client)
		client.sending -= unreceived
		client.cache |= unreceived
		client.completed_asset_jobs -= job

	return 1

//This proc will download the files without clogging up the browse() queue, used for passively sending files on connection start.
//The proc calls procs that sleep for long times.
/proc/getFilesSlow(var/client/client, var/list/files, var/register_asset = TRUE)
	var/concurrent_tracker = 1
	for(var/file in files)
		if(!client)
			break
		if(register_asset)
			register_asset(file, files[file])
		if(concurrent_tracker >= ASSET_CACHE_PRELOAD_CONCURRENT)
			concurrent_tracker = 1
			send_asset(client, file)
		else
			concurrent_tracker++
			send_asset(client, file, verify = FALSE)
		sleep(0) //queuing calls like this too quickly can cause issues in some client versions

//This proc "registers" an asset, it adds it to the cache for further use, you cannot touch it from this point on or you'll fuck things up.
//if it's an icon or something be careful, you'll have to copy it before further use.
/proc/register_asset(var/asset_name, var/asset)
	SSassets.cache[asset_name] = asset

// will return filename for cached atom icon or null if not cached
// can accept atom objects or types
/proc/getAtomCacheFilename(var/atom/A)
	if(!A || (!istype(A) && !ispath(A)))
		return
	var/filename = "[ispath(A) ? A : A.type].png"
	filename = sanitizeFileName(filename)

//Generated names do not include file extention.
//Used mainly for code that deals with assets in a generic way
//The same asset will always lead to the same asset name
/proc/generate_asset_name(file)
	return "asset.[md5(fcopy_rsc(file))]"


//These datums are used to populate the asset cache, the proc "register()" does this.

//all of our asset datums, used for referring to these later
/var/global/list/asset_datums = list()

//get a assetdatum or make a new one
/proc/get_asset_datum(var/type)
	if (!(type in asset_datums))
		return new type()
	return asset_datums[type]

/datum/asset/New()
	asset_datums[type] = src
	register()

/datum/asset/proc/register()
	return

/datum/asset/proc/send(client)
	return

//If you don't need anything complicated.
/datum/asset/simple
	var/assets = list()
	var/verify = FALSE

/datum/asset/simple/register()
	for(var/asset_name in assets)
		register_asset(asset_name, assets[asset_name])

/datum/asset/simple/send(client)
	send_asset_list(client,assets,verify)

// For registering or sending multiple others at once
/datum/asset/group
	var/list/children

/datum/asset/group/register()
	for(var/type in children)
		get_asset_datum(type)

/datum/asset/group/send(client/C)
	for(var/type in children)
		var/datum/asset/A = get_asset_datum(type)
		A.send(C)

//DEFINITIONS FOR ASSET DATUMS START HERE.

/datum/asset/simple/pda
	assets = list(
		"pda_atmos.png"			= 'icons/pda_icons/pda_atmos.png',
		"pda_back.png"			= 'icons/pda_icons/pda_back.png',
		"pda_bell.png"			= 'icons/pda_icons/pda_bell.png',
		"pda_blank.png"			= 'icons/pda_icons/pda_blank.png',
		"pda_boom.png"			= 'icons/pda_icons/pda_boom.png',
		"pda_bucket.png"		= 'icons/pda_icons/pda_bucket.png',
		"pda_chatroom.png"      = 'icons/pda_icons/pda_chatroom.png',
		"pda_crate.png"         = 'icons/pda_icons/pda_crate.png',
		"pda_cuffs.png"         = 'icons/pda_icons/pda_cuffs.png',
		"pda_eject.png"			= 'icons/pda_icons/pda_eject.png',
		"pda_exit.png"			= 'icons/pda_icons/pda_exit.png',
		"pda_honk.png"			= 'icons/pda_icons/pda_honk.png',
		"pda_locked.png"        = 'icons/pda_icons/pda_locked.png',
		"pda_mail.png"			= 'icons/pda_icons/pda_mail.png',
		"pda_medical.png"		= 'icons/pda_icons/pda_medical.png',
		"pda_menu.png"			= 'icons/pda_icons/pda_menu.png',
		"pda_mule.png"			= 'icons/pda_icons/pda_mule.png',
		"pda_notes.png"			= 'icons/pda_icons/pda_notes.png',
		"pda_power.png"			= 'icons/pda_icons/pda_power.png',
		"pda_rdoor.png"			= 'icons/pda_icons/pda_rdoor.png',
		"pda_reagent.png"		= 'icons/pda_icons/pda_reagent.png',
		"pda_refresh.png"		= 'icons/pda_icons/pda_refresh.png',
		"pda_scanner.png"		= 'icons/pda_icons/pda_scanner.png',
		"pda_signaler.png"		= 'icons/pda_icons/pda_signaler.png',
		"pda_status.png"		= 'icons/pda_icons/pda_status.png'
	)

/datum/asset/simple/tgui
	assets = list(
		"tgui.css"	= 'tgui/assets/tgui.css',
		"tgui.js"	= 'tgui/assets/tgui.js'
	)

/datum/asset/nanoui
	var/list/common = list()

	var/list/common_dirs = list(
		"nano/css/",
		"nano/images/",
		"nano/images/status_icons/",
		"nano/images/modular_computers/",
		"nano/js/"
	)
	var/list/uncommon_dirs = list(
		"nano/templates/",
		"news_articles/images/"
	)

/datum/asset/nanoui/register()
	// Crawl the directories to find files.
	for (var/path in common_dirs)
		var/list/filenames = flist(path)
		for(var/filename in filenames)
			if(copytext_char(filename, length(filename)) != "/") // Ignore directories.
				if(fexists(path + filename))
					common[filename] = fcopy_rsc(path + filename)
					register_asset(filename, common[filename])
	for (var/path in uncommon_dirs)
		var/list/filenames = flist(path)
		for(var/filename in filenames)
			if(copytext_char(filename, length(filename)) != "/") // Ignore directories.
				if(fexists(path + filename))
					register_asset(filename, fcopy_rsc(path + filename))

	var/list/mapnames = list()
	for(var/z in GLOB.using_map.map_levels)
		mapnames += map_image_file_name(z)

	var/list/filenames = flist(MAP_IMAGE_PATH)
	for(var/filename in filenames)
		if(copytext_char(filename, length(filename)) != "/") // Ignore directories.
			var/file_path = MAP_IMAGE_PATH + filename
			if((filename in mapnames) && fexists(file_path))
				common[filename] = fcopy_rsc(file_path)
				register_asset(filename, common[filename])

/datum/asset/nanoui/send(client, uncommon)
	if(!islist(uncommon))
		uncommon = list(uncommon)

	send_asset_list(client, uncommon, FALSE)
	send_asset_list(client, common, TRUE)

/datum/asset/group/goonchat
	children = list(
		/datum/asset/simple/jquery,
		/datum/asset/simple/goonchat,
		/datum/asset/simple/fontawesome
	)

/datum/asset/simple/jquery
	verify = FALSE
	assets = list(
		"jquery.min.js"            = 'code/modules/goonchat/browserassets/js/jquery.min.js',
	)

/datum/asset/simple/goonchat
	verify = TRUE
	assets = list(
		"json2.min.js"             = 'code/modules/goonchat/browserassets/js/json2.min.js',
		"browserOutput.js"         = 'code/modules/goonchat/browserassets/js/browserOutput.js',
		"chatbg.png"			   = 'icons/misc/chatbg.png',
		"browserOutput.css"	       = 'code/modules/goonchat/browserassets/css/browserOutput.css',
		"browserOutput_white.css"  = 'code/modules/goonchat/browserassets/css/browserOutput_white.css',
	)

/datum/asset/simple/fontawesome
	verify = FALSE
	assets = list(
		"fa-regular-400.eot"  = 'html/font-awesome/webfonts/fa-regular-400.eot',
		"fa-regular-400.woff" = 'html/font-awesome/webfonts/fa-regular-400.woff',
		"fa-solid-900.eot"    = 'html/font-awesome/webfonts/fa-solid-900.eot',
		"fa-solid-900.woff"   = 'html/font-awesome/webfonts/fa-solid-900.woff',
		"font-awesome.css"    = 'html/font-awesome/css/all.min.css',
		"v4shim.css"          = 'html/font-awesome/css/v4-shims.min.css'
	)

/*
	Asset cache
*/

/decl/asset_cache
	var/list/cache = list()

/decl/asset_cache/proc/load()
	for(var/type in typesof(/datum/asset) - list(/datum/asset, /datum/asset/simple))
		var/datum/asset/A = new type()
		A.register()

	for(var/client/C in GLOB.clients) // This is also called in client/New, but as we haven't initialized the cache until now, and it's possible the client is already connected, we risk doing it twice.
		// Doing this to a client too soon after they've connected can cause issues, also the proc we call sleeps.
		spawn(10)
			getFilesSlow(C, cache, FALSE)
