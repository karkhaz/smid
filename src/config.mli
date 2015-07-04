(* Global configuration options
 * Copyright (C) 2015 Kareem Khazem
 *
 * This file is part of smid.
 *
 * smid is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *)

val debug : bool ref

val loops : bool ref

val run_length : int ref

val include_dir : string ref

val fsa_file : string option ref

type mode = CompileOnly
          | StateList
          | DOT
          | TransitionGraphs
          | Stats
          | JSON

val mode : mode option ref

val output_dir : string option ref
