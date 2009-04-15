
#ifndef _TRACKER_IPTC_H_
#define _TRACKER_IPTC_H_

#include <glib.h>

void tracker_read_iptc (const unsigned char *buffer,
			size_t		    len,
			const gchar        *uri,
			GPtrArray	   *metadata);

#endif
