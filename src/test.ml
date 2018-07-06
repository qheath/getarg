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

let longopts = [
  ('a',"alpha"," ALPHA"),
  GetArg.Lone (fun () -> Printf.printf "a/\n%!") ;

  ('b',""," BETA"),
  GetArg.(Mandatory (String (fun s -> Printf.printf "b%S\n%!" s))) ;

  ('c',"gamma"," GAMMA"),
  GetArg.(Optional ((fun () -> Printf.printf "c/\n%!"),
                    Int (fun i -> Printf.printf "c%d\n%!" i))) ;

  ('\000',"delta"," DELTA"),
  GetArg.(Mandatory (Float (fun f -> Printf.printf "d%1.1f\n%!" f))) ;

  ('h',"kelp"," this prevents the -h short option \
                to have the same meaning as the --help long option"),
  GetArg.(Lone print_help) ;
]

let process s =
  Printf.printf "[%s]@." s

let _ =
  GetArg.parse longopts process "tu peux pas test"
