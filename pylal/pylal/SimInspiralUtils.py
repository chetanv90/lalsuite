# $Id$
#
# Copyright (C) 2006  Duncan A. Brown
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

#
# =============================================================================
#
#                                   Preamble
#
# =============================================================================
#

from pylal.date import LIGOTimeGPS
from glue.ligolw import table
from glue.ligolw import lsctables
from glue.ligolw import utils
#
# =============================================================================
#
#                                   Input
#
# =============================================================================
#


def ReadSimInspiralFromFiles(fileList):
  """
  Read the simInspiral tables from a list of files
  @param fileList: list of input files
  """
  simInspiralTriggers = None
  for thisFile in fileList:
    doc = utils.load_filename(thisFile)
    # extract the sim inspiral table
    try: simInspiralTable = \
      table.get_table(doc, lsctables.SimInspiralTable.tableName)
    except: simInspiralTable = None
    if simInspiralTriggers and simInspiralTable: 
      simInspiralTriggers.extend(simInspiralTable)
    elif not simInspiralTriggers:
      simInspiralTriggers = simInspiralTable

  return simInspiralTriggers


