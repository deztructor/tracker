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

/*
 * FIXME: We should try to get raw data (from libexif) to avoid processing.
 */

#include "config.h"

#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <setjmp.h>

#include <glib.h>
#include <glib/gstdio.h>

#include <jpeglib.h>

#include <libtracker-common/tracker-file-utils.h>
#include <libtracker-common/tracker-ontology.h>
#include <libtracker-common/tracker-statement-list.h>
#include <libtracker-common/tracker-type-utils.h>
#include <libtracker-common/tracker-utils.h>

#include "tracker-main.h"
#include "tracker-xmp.h"
#include "tracker-iptc.h"

#define NMM_PREFIX TRACKER_NMM_PREFIX
#define NFO_PREFIX TRACKER_NFO_PREFIX
#define NIE_PREFIX TRACKER_NIE_PREFIX
#define DC_PREFIX TRACKER_DC_PREFIX
#define NCO_PREFIX TRACKER_NCO_PREFIX

#define RDF_PREFIX TRACKER_RDF_PREFIX
#define RDF_TYPE RDF_PREFIX "type"

#ifdef HAVE_EXEMPI
#define XMP_NAMESPACE	     "http://ns.adobe.com/xap/1.0/\x00"
#define XMP_NAMESPACE_LENGTH 29
#endif /* HAVE_EXEMPI */

#ifdef HAVE_LIBEXIF
#include <libexif/exif-data.h>
#define EXIF_DATE_FORMAT "%Y:%m:%d %H:%M:%S"
#endif /* HAVE_LIBEXIF */

#ifdef HAVE_LIBIPTCDATA
#define PS3_NAMESPACE	     "Photoshop 3.0\0"
#define PS3_NAMESPACE_LENGTH 14
#include <libiptcdata/iptc-jpeg.h>
#endif /* HAVE_LIBIPTCDATA */

static void extract_jpeg (const gchar *filename,
			  GPtrArray   *metadata);

static TrackerExtractData data[] = {
	{ "image/jpeg", extract_jpeg },
	{ NULL, NULL }
};

struct tej_error_mgr 
{
	struct jpeg_error_mgr jpeg;
	jmp_buf setjmp_buffer;
};

static void tracker_extract_jpeg_error_exit (j_common_ptr cinfo)
{
    struct tej_error_mgr *h = (struct tej_error_mgr *)cinfo->err;
    (*cinfo->err->output_message)(cinfo);
    longjmp(h->setjmp_buffer, 1);
}

#ifdef HAVE_LIBEXIF

typedef gchar * (*PostProcessor) (const gchar*);

typedef struct {
	ExifTag       tag;
	gchar	     *name;
	PostProcessor post;
} TagType;

static gchar *date_to_iso8601	(const gchar *exif_date);
static gchar *fix_focal_length	(const gchar *fl);
static gchar *fix_flash		(const gchar *flash);
static gchar *fix_fnumber	(const gchar *fn);
static gchar *fix_exposure_time (const gchar *et);
static gchar *fix_orientation   (const gchar *orientation);

static TagType tags[] = {
	{ EXIF_TAG_PIXEL_Y_DIMENSION, NFO_PREFIX "height", NULL },
	{ EXIF_TAG_PIXEL_X_DIMENSION, NFO_PREFIX "width", NULL },
	{ EXIF_TAG_RELATED_IMAGE_WIDTH, NFO_PREFIX "width", NULL },
	{ EXIF_TAG_DOCUMENT_NAME, NIE_PREFIX "title", NULL },
	/* { -1, "Image:Album", NULL }, */
	{ EXIF_TAG_DATE_TIME, NIE_PREFIX "contentCreated", date_to_iso8601 },
	{ EXIF_TAG_DATE_TIME_ORIGINAL, NIE_PREFIX "contentCreated", date_to_iso8601 },
	/* { -1, "Image:Keywords", NULL }, */
	{ EXIF_TAG_ARTIST, NCO_PREFIX "creator", NULL },
	{ EXIF_TAG_USER_COMMENT, NIE_PREFIX "comment", NULL },
	{ EXIF_TAG_IMAGE_DESCRIPTION, NIE_PREFIX "description", NULL },
	{ EXIF_TAG_SOFTWARE, "Image:Software", NULL },
	{ EXIF_TAG_MAKE, "Image:CameraMake", NULL },
	{ EXIF_TAG_MODEL, "Image:CameraModel", NULL },
	{ EXIF_TAG_ORIENTATION, "Image:Orientation", fix_orientation },
	{ EXIF_TAG_EXPOSURE_PROGRAM, "Image:ExposureProgram", NULL },
	{ EXIF_TAG_EXPOSURE_TIME, "Image:ExposureTime", fix_exposure_time },
	{ EXIF_TAG_FNUMBER, "Image:FNumber", fix_fnumber },
	{ EXIF_TAG_FLASH, "Image:Flash", fix_flash },
	{ EXIF_TAG_FOCAL_LENGTH, "Image:FocalLength", fix_focal_length },
	{ EXIF_TAG_ISO_SPEED_RATINGS, "Image:ISOSpeed", NULL },
	{ EXIF_TAG_METERING_MODE, "Image:MeteringMode", NULL },
	{ EXIF_TAG_WHITE_BALANCE, "Image:WhiteBalance", NULL },
	{ EXIF_TAG_COPYRIGHT, NIE_PREFIX "copyright", NULL },
	{ -1, NULL, NULL }
};

#endif /* HAVE_EXIF */

#ifdef HAVE_LIBEXIF

static gchar *
date_to_iso8601 (const gchar *date)
{
	/* From: ex; date "2007:04:15 15:35:58"
	 * To  : ex. "2007-04-15T17:35:58+0200 where +0200 is localtime
	 */
	return tracker_date_format_to_iso8601 (date, EXIF_DATE_FORMAT);
}

static gchar *
fix_focal_length (const gchar *fl)
{
	return g_strndup (fl, strstr (fl, " mm") - fl);
}

static gchar *
fix_flash (const gchar *flash)
{
	if (g_str_has_prefix (flash, "Flash fired")) {
		return g_strdup ("1");
	} else {
		return g_strdup ("0");
	}
}

static gchar *
fix_fnumber (const gchar *fn)
{
	gchar *new_fn;

	if (!fn) {
		return NULL;
	}

	new_fn = g_strdup (fn);

	if (new_fn[0] == 'F') {
		new_fn[0] = ' ';
	} else if (fn[0] == 'f' && new_fn[1] == '/') {
		new_fn[0] = new_fn[1] = ' ';
	}

	return g_strstrip (new_fn);
}

static gchar *
fix_exposure_time (const gchar *et)
{
	gchar *sep;

	sep = strchr (et, '/');

	if (sep) {
		gdouble fraction;

		fraction = g_ascii_strtod (sep + 1, NULL);

		if (fraction > 0.0) {
			gdouble val;
			gchar	buf[G_ASCII_DTOSTR_BUF_SIZE];

			val = 1.0f / fraction;
			g_ascii_dtostr (buf, sizeof(buf), val);

			return g_strdup (buf);
		}
	}

	return g_strdup (et);
}

static gchar *
fix_orientation (const gchar *orientation)
{
	guint i;
	static gchar *ostr[8] = {
		"top - left",
		"top - right",
		"bottom - right",
		"bottom - left",
		"left - top",
		"right - top",
		"right - bottom",
		"left - bottom"
	};
	
	for (i=0;i<8;i++) {
		if (strcmp(orientation,ostr[i])==0) {
			gchar buffer[2];
			snprintf (buffer,2,"%d", i+1);
			return g_strdup(buffer);
		}
	}

	return g_strdup("1"); /* We take this as default */
}

static void
read_exif (const unsigned char *buffer,
	   size_t		len,
	   const gchar         *uri,
	   GPtrArray	       *metadata)
{
	ExifData *exif;
	TagType  *p;

	exif = exif_data_new_from_data ((unsigned char *) buffer, len);

	for (p = tags; p->name; ++p) {
		ExifEntry *entry = exif_data_get_entry (exif, p->tag);

		if (entry) {
			gchar buffer[1024];
			gchar *what_i_need;

			exif_entry_get_value (entry, buffer, 1024);

			if (p->post) {
				what_i_need = (*p->post) (buffer);
			} else {
				what_i_need = buffer;
			}

			if (p->tag == EXIF_TAG_ARTIST) {
				gchar *canonical_uri = tracker_uri_printf_escaped ("urn:artist:%s", what_i_need);
				tracker_statement_list_insert (metadata, canonical_uri, RDF_TYPE, NCO_PREFIX "Contact");
				tracker_statement_list_insert (metadata, canonical_uri, NCO_PREFIX "fullname", what_i_need);
				tracker_statement_list_insert (metadata, uri, p->name, canonical_uri);
				g_free (canonical_uri);
			} else {
				tracker_statement_list_insert (metadata, uri, p->name, what_i_need);
			}

			if (p->post)
				g_free (what_i_need);
		}
	}
	
	exif_data_free (exif);
}

#endif /* HAVE_LIBEXIF */


static void
extract_jpeg (const gchar *uri,
	      GPtrArray   *metadata)
{
	struct jpeg_decompress_struct  cinfo;
	struct tej_error_mgr	       tejerr;
	struct jpeg_marker_struct     *marker;
	FILE			      *f;
	goffset                        size;
	gchar                         *filename;

	filename = g_filename_from_uri (uri, NULL, NULL);

	size = tracker_file_get_size (filename);

	if (size < 18) {
		return;
	}

	f = tracker_file_open (filename, "rb", FALSE);

	if (f) {
		gchar *str;
		gsize  len;
#ifdef HAVE_LIBIPTCDATA
		gsize  offset;
		gsize  sublen;
#endif /* HAVE_LIBEXIF */

		tracker_statement_list_insert (metadata, uri, 
		                          RDF_TYPE, 
		                          NFO_PREFIX "Image");

		cinfo.err = jpeg_std_error (&tejerr.jpeg);
		tejerr.jpeg.error_exit = tracker_extract_jpeg_error_exit;
		if (setjmp(tejerr.setjmp_buffer)) {
			goto fail;
		}

		jpeg_create_decompress (&cinfo);
		
		jpeg_save_markers (&cinfo, JPEG_COM, 0xFFFF);
		jpeg_save_markers (&cinfo, JPEG_APP0 + 1, 0xFFFF);
		jpeg_save_markers (&cinfo, JPEG_APP0 + 13, 0xFFFF);
		
		jpeg_stdio_src (&cinfo, f);
		
		jpeg_read_header (&cinfo, TRUE);
		
		/* FIXME? It is possible that there are markers after SOS,
		 * but there shouldn't be. Should we decompress the whole file?
		 *
		 * jpeg_start_decompress(&cinfo);
		 * jpeg_finish_decompress(&cinfo);
		 *
		 * jpeg_calc_output_dimensions(&cinfo);
		 */
		
		marker = (struct jpeg_marker_struct *) &cinfo.marker_list;
		
		while (marker) {
			switch (marker->marker) {
			case JPEG_COM:
				len = marker->data_length;
				str = g_strndup ((gchar*) marker->data, len);

				tracker_statement_list_insert (metadata, uri,
							  NIE_PREFIX "comment",
							  str);
				g_free (str);
				break;
				
			case JPEG_APP0+1:
				str = (gchar*) marker->data;
				len = marker->data_length;

#ifdef HAVE_LIBEXIF
				if (strncmp ("Exif", (gchar*) (marker->data), 5) == 0) {
					read_exif ((unsigned char*) marker->data,
						   marker->data_length, uri,
						   metadata);
				}
#endif /* HAVE_LIBEXIF */

#ifdef HAVE_EXEMPI

				if (strncmp (XMP_NAMESPACE, str, XMP_NAMESPACE_LENGTH) == 0) {
					tracker_read_xmp (str + XMP_NAMESPACE_LENGTH,
							  len - XMP_NAMESPACE_LENGTH,
							  uri, metadata);
				}
#endif /* HAVE_EXEMPI */
				break;
			case JPEG_APP0+13:
				str = (gchar*) marker->data;
				len = marker->data_length;
#ifdef HAVE_LIBIPTCDATA
				if (strncmp (PS3_NAMESPACE, str, PS3_NAMESPACE_LENGTH) == 0) {
					offset = iptc_jpeg_ps3_find_iptc (str, len, &sublen);
					if (offset>0) {
						tracker_read_iptc (str + offset,
								   sublen,
								   uri, metadata);
					}
				}
#endif /* HAVE_LIBIPTCDATA */
				break;
			default:
				marker = marker->next;
				continue;
			}

			marker = marker->next;
		}

		/* We want native size to have priority over EXIF, XMP etc */
		tracker_statement_list_insert_with_int (metadata, uri,
						   NFO_PREFIX "width",
						   cinfo.image_width);
		tracker_statement_list_insert_with_int (metadata, uri,
						   NFO_PREFIX "height",
						    cinfo.image_height);

fail:
		tracker_file_close (f, FALSE);
	}

	g_free (filename);
}

TrackerExtractData *
tracker_get_extract_data (void)
{
	return data;
}
