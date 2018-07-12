(****************************************************************************)
(* GetArg command-line option parser                                        *)
(* Copyright (C) 2012-2018 Quentin Heath                                    *)
(*                                                                          *)
(* This program is free software: you can redistribute it and/or modify     *)
(* it under the terms of the GNU General Public License as published by     *)
(* the Free Software Foundation, either version 3 of the License, or        *)
(* (at your option) any later version.                                      *)
(*                                                                          *)
(* This program is distributed in the hope that it will be useful,          *)
(* but WITHOUT ANY WARRANTY; without even the implied warranty of           *)
(* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            *)
(* GNU General Public License for more details.                             *)
(*                                                                          *)
(* You should have received a copy of the GNU General Public License        *)
(* along with this program.  If not, see <http://www.gnu.org/licenses/>.    *)
(****************************************************************************)

(** Command line parser inspired by GNU getopt.
  *
  * It is similar to Getopt and Getopts, :
  *   - long options (with an expanded form that can take a mandatory
  *     argument)
  *   - no expanded form for short options with optional arguments
  *   - clusters of short optionsmixing with and without arguments)

  *
  * This module offers an alternative to the standard Ocaml [Arg] module
  * with a support for short and long options (cf. [man 3 getopt] for an
  * example of C API).
  *
  * It is loosely inspired by the [Getopt] and [Getopts] modules, with a
  * few key differences:
  * - getopt-style long options, with good support for mandatory
  *   arguments (if the argument of [--foo] is mandatory, the expanded
  *   form [--foo bar] is an alternative to the compact form
  *   [--foo=bar])
  * - more consistent support for short options with optional arguments
  *   ([-y 42] is equivalent to [--y-option 42], ie. an argument-less
  *   option and a plain argument, instead of being equivalent to [-y42]
  *   and thus to [--y-option=42], ie. an argument supplied to an option)
  * - more flexible support for clusters of short options (if [-a],
  *   [-b] and [-c] take no argument, [-abcde 42] is legal and
  *   equivalent to [-a -b -c -de 42], even if [-d] can take an
  *   argument *)

(** {6 Options specification} *)

(** The options are specified by a list of
  * [((short,long,description),opt_spec)]:
  * - [short] is the short form of the option (['\000'] for no short form)
  * - [long] is the long form of the option ([""] for no long form)
  * - [description] is the one-line description of the option.
  *   Like in [Arg], the first space splits the description into the displayed
  *   form of the argument (if needed) and the actual description
  *   ("n This option does…" becomes "--option <n>      This option does…").
  *   Unlike in [Arg], the descriptions are wrapped, and aligned by default
  * - [opt_spec] contains an optional [withoutarg] (a [unit -> unit]
  *   callback called when the option is used with no argument) and an
  *   optional [witharg] (a more flexible callback called when the
  *   option is called with an argument)
  *
  * There is always one of [withoutarg] and [witharg] that is available
  * in [opt_spec].  When both are available, the latter is called when
  * an argument is provided to the option in collapsed form ([-xy42] or
  * [--y-option=42] for [-y]/[--y-option]); in other cases, the former
  * callback is used. *)

type opt_type = Long of string | Short of char

(** Callback function binding an option to its argument. *)
type long_opt =
  | String of (string -> unit)
    (** function called on the argument *)
  | Int of (int -> unit)
    (** function called on the converted argument *)
  | Float of (float -> unit)
    (** function called on the converted argument *)

(** Pair of callback functions. *)
type opt_spec =
  | Mandatory of long_opt
  | Optional of (unit -> unit) * long_opt
  | Lone of (unit -> unit)

val set_bool : bool ref -> opt_spec
val set_string : string ref -> opt_spec
val add_string : string list ref -> opt_spec
val set_int : int ref -> opt_spec

exception Incorrect_specification
exception Missing_argument of opt_type
exception Unknown_option of opt_type
exception Needless_argument of opt_type
exception Incorrect_argument of opt_type * string

(** {6 Options specification} *)

(** Display the usage message passed to {!parse}, then the list
  * of options. *)
val print_help : unit -> unit
(** For each option, the available forms are displayed, then an argument
  * if available, then a question mark if the argument is optional.
  * Last, the description (except for all that comes before the first space)
  * is displayed.
  * As a consequence, if an option takes no argument and the description
  * doesn't start with a space in the specification, its first word won't be
  * displayed. *)

(** [parse longopts process usage_msg] builds a help message to be displayed
  * with {!print_help}, then processes the command-line options. *)
val parse :
  ?argc:int -> ?argv:string array -> ?auto_help:bool ->
  ((char * string * string) * opt_spec) list ->
  (string -> unit) -> string -> unit
(** The callback functions provided in [longopts] and by [process] are called
  * in the order of the options/arguments on the command line.
  * This is in contrast with the default behaviour of GNU getopt, where all
  * the plain arguments are first shifted to the end, and then the [process]
  * calls are made.  This is easy to emulate by using [process] to just fill a
  * list that will be processed after; the current behaviour is that of
  * GNU getopt when a ['-'] is appended to [optstring].
  * @param argc defaults to [Array.length Sys.argv]
  * @param argv defaults to [Sys.argc]
  * @param auto_help whether a -h/--help option must be generated if missing *)
