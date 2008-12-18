/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2006, Mr Jamie McCracken (jamiemcc@gnome.org)
 * Copyright (C) 2008, Nokia
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA  02110-1301, USA.
 */

#ifndef __TRACKER_EXTRACT_H__
#define __TRACKER_EXTRACT_H__

#include <glib.h>
#include "tracker-escape.h"

G_BEGIN_DECLS

/* FIXME: We use this to say that we don't actually have any metadata
 * for this keyword. This is bad because it means we have to string
 * check every value returned in clients that use the Tracker API.
 * This will be fixed in due course after January some time, -mr.
 *
 * 
 */
#define METADATA_UNKNOWN ""

typedef struct TrackerExtractorData TrackerExtractorData;

typedef TrackerExtractorData * (*TrackerExtractorDataFunc)(void);

struct TrackerExtractorData {
	const gchar *mime;

	void (* extractor) (const gchar *filename,
			    GHashTable	*metadata);
};

TrackerExtractorData *tracker_get_extractor_data (void);

G_END_DECLS

#endif /* __TRACKER_EXTRACT_H__ */
