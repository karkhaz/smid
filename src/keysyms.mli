(* Functions to determine valid keystrokes
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


(** Whether a keystroke is valid or not *)
type validity = Valid               (** Keystroke is valid *)

              | Corrected of string (** Keystroke is invalid, but we
                                      * were able to correct it to a
                                      * valid keystroke
                                      *)

              | Invalid             (* Keystroke is invalid *)

(** Whether a keystroke is valid or not *)
val valid : string -> validity
