
/proc/emoji_parse(text)
	. = text
	var/static/list/emojis = icon_states(icon('icons/emoji.dmi'))
	var/parsed = ""
	var/pos = 1
	var/search = 0
	var/emoji = ""
	while(1)
		search = findtext(text, ":", pos)
		parsed += copytext_char(text, pos, search)
		if(search)
			pos = search
			search = findtext(text, ":", pos+1)
			if(search)
				emoji = lowertext(copytext_char(text, pos+1, search))
				if(emoji in emojis)
					parsed += icon2html('icons/emoji.dmi', world, emoji)
					pos = search + 1
				else
					parsed += copytext_char(text, pos, search)
					pos = search
				emoji = ""
				continue
			else
				parsed += copytext_char(text, pos, search)
		break
	return parsed