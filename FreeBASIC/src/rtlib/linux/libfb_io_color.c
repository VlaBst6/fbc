/*
 *  libfb - FreeBASIC's runtime library
 *	Copyright (C) 2004-2006 Andre V. T. Vicentini (av1ctor@yahoo.com.br) and
 *  the FreeBASIC development team.
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *  As a special exception, the copyright holders of this library give
 *  you permission to link this library with independent modules to
 *  produce an executable, regardless of the license terms of these
 *  independent modules, and to copy and distribute the resulting
 *  executable under terms of your choice, provided that you also meet,
 *  for each linked independent module, the terms and conditions of the
 *  license of that module. An independent module is a module which is
 *  not derived from or based on this library. If you modify this library,
 *  you may extend this exception to your version of the library, but
 *  you are not obligated to do so. If you do not wish to do so, delete
 *  this exception statement from your version.
 */

/*
 * io_color.c -- color (console, no gfx) function for Linux
 *
 * chng: jan/2005 written [lillo]
 *       feb/2005 rewritten to remove ncurses dependency [lillo]
 *
 */

#include "fb.h"
#include "fb_linux.h"


/*:::::*/
int fb_ConsoleColor( int fc, int bc )
{
	const char map[8] = { 0, 4, 2, 6, 1, 5, 3, 7 };
	int old_fg = fb_con.fg_color;
	int old_bg = fb_con.bg_color;
	
	if (!fb_con.inited)
		return old_fg | (old_bg << 16);
	
	fb_hResize();
	
	if (fc >= 0)
		fb_con.fg_color = (fc & 0xF);
	if (bc >= 0)
		fb_con.bg_color = (bc & 0xF);
	
	fb_hTermOut(SEQ_RESET_COLOR, 0, 0);
	if ((fb_con.inited == INIT_CONSOLE) || (fb_con.term_type == TERM_ETERM)) {
		/* console and eterm do not support extended color attributes and only allow 16+8 colors */
		if (fb_con.fg_color != old_fg) {
			if (fb_con.fg_color & 0x8)
				fb_hTermOut(SEQ_BRIGHT_COLOR, 0, 0);
			fb_hTermOut(SEQ_FG_COLOR, 0, map[fb_con.fg_color & 0x7]);
		}
		if (fb_con.bg_color != old_bg)
			fb_hTermOut(SEQ_BG_COLOR, 0, map[fb_con.bg_color & 0x7]);
	}
	else {
		/* generic xterm supports 16+16 colors */
		if (fb_con.fg_color != old_fg)
			fb_hTermOut(SEQ_SET_COLOR_EX, map[fb_con.fg_color & 0x7] + (fb_con.fg_color > 7 ? 90 : 30), 0);
		if (fb_con.bg_color != old_bg)
			fb_hTermOut(SEQ_SET_COLOR_EX, map[fb_con.bg_color & 0x7] + (fb_con.bg_color > 7 ? 100 : 40), 0);
	}
	
	return old_fg | (old_bg << 16);
}

/*:::::*/
int fb_ConsoleGetColorAtt( void )
{
	return fb_con.inited ? (fb_con.fg_color | (fb_con.bg_color << 4)) : 0x7;
}
