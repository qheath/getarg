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


type opt_type = Long of string | Short of char

let to_string = function
  | Long s -> Printf.sprintf "--%s" s
  | Short c -> Printf.sprintf "-%c" c

let string_of_char c =
  String.make 1 c

type long_opt =
  | String of (string -> unit)
  | Int of (int -> unit)
  | Float of (float -> unit)
type opt_spec =
  | Mandatory of long_opt
  | Optional of (unit -> unit) * long_opt
  | Lone of (unit -> unit)

let set_bool x = Lone (fun () -> x := true)
let set_string x = Mandatory (String (fun s -> x := s))
let add_string x = Mandatory (String (fun s -> x := s :: !x))
let set_int x = Mandatory (Int (fun n -> x := n))

exception Incorrect_specification
exception Missing_argument of opt_type
exception Unknown_option of opt_type
exception Needless_argument of opt_type
exception Incorrect_argument of opt_type * string

let missing opt =
  raise (Missing_argument opt)

let unknown opt =
  raise (Unknown_option opt)

let needless opt =
  raise (Needless_argument opt)

let incorrect opt arg =
  raise (Incorrect_argument (opt,arg))

let help_buffer = Buffer.create 42

let print_help () =
  print_string (Buffer.contents help_buffer) ;
  exit 0

let build_help_buffer auto_help longopts usage_msg =
  let nsplit_string str =
    let rec aux l n =
      match try Some (String.index_from str n ' ') with Not_found -> None with
        | Some i -> aux ((String.sub str n (i - n))::l) (i+1)
        | None -> List.rev ((String.sub str n (String.length str - n))::l)
    in
    aux [] 0
  in
  let () = Buffer.clear help_buffer in
  if usage_msg<>"" then begin
    Buffer.add_string help_buffer usage_msg ;
    Buffer.add_char help_buffer '\n'
  end ;
  let longopts =
    let longopts = List.rev longopts in
    if (not auto_help)
    then longopts
    else if List.exists (fun ((_,l_opt,_),_) -> l_opt="help") longopts
    then longopts
    else begin
      let c_opt =
        if List.exists (fun ((c_opt,_,_),_) -> c_opt='h') longopts
        then '\000'
        else 'h'
      and l_opt = "help"
      and str = " display this help message"
      and callbacks = Lone print_help in
      ((c_opt,l_opt,str),callbacks)::longopts
    end
  in
  let strs =
    let aux ((c_opt,l_opt,str),callbacks) =
      let rev_strs = match c_opt,l_opt with
        | '\000',_ -> [l_opt;"     --"]
        | _,"" -> [string_of_char c_opt;" -"]
        | _,_ -> [l_opt;", --";string_of_char c_opt;" -"]
      in
      let arg,desc = match nsplit_string str with
        | arg::desc -> arg,desc
        | [] -> "",[]
      in
      let rev_strs =
        match match callbacks with
          | Lone _ -> None
          | Mandatory cb -> Some (cb,true)
          | Optional (_,cb) -> Some (cb,false)
        with
          | None -> rev_strs
          | Some (cb,mandatory) ->
              let rev_strs =
                if arg<>"" then ">"::arg::" <"::rev_strs
                else begin match cb with
                  | String s -> " <string>"::rev_strs
                  | Int i -> " <int>"::rev_strs
                  | Float f -> " <float>"::rev_strs
                end
              in
              if mandatory then rev_strs else "?"::rev_strs
      in
      let prefix = String.concat "" @@ List.rev rev_strs in
      String.length prefix,prefix,desc
    in
    List.rev_map aux longopts
  in
  let padding_length =
    List.fold_left (fun accum (length,_,_) -> max accum length) 0 strs
  in
  let f = Format.formatter_of_buffer help_buffer in
  Format.fprintf f "@[<v>" ;
  List.iter
    (fun (length,prefix,desc) ->
       Format.fprintf f "@[%s%s@["
         prefix (String.make (padding_length - length) ' ') ;
       List.iter (fun s -> Format.fprintf f "@;<1 1>%s" s) desc ;
       Format.fprintf f "@]@]@,")
    strs ;
  Format.fprintf f "@]@." ;
  Format.pp_print_flush f () ;
  longopts

let getopt_long longopts =
  let get_callbacks = function
    | Long s ->
        begin try Some (snd (List.find (fun ((_,s',_),_) -> s=s') longopts))
        with Not_found -> None end
    | Short c ->
        begin try Some (snd (List.find (fun ((c',_,_),_) -> c=c') longopts))
        with Not_found -> None end
  in
  let process_opt callback opt arg = match callback with
    | String c -> c arg
    | Int c ->
        let i =
          try int_of_string arg with Failure _ -> incorrect opt arg
        in
        c i
    | Float c ->
        let f =
          try float_of_string arg with Failure _ -> incorrect opt arg
        in
        c f
  in
  let apply_option opt arg_opt failure =
    match get_callbacks opt,arg_opt with
      | Some (Lone without_cb),Some remainder ->
          failure without_cb remainder
      | Some (Lone without_cb),None
      | Some (Optional (without_cb,_)),None -> (* no argument *)
          without_cb () ;
          None
      | Some (Optional (_,with_cb)),Some arg
      | Some (Mandatory with_cb),Some arg -> (* collapsed argument *)
          process_opt with_cb opt arg ;
          None
      | Some (Mandatory with_cb),None -> (* detached argument *)
          Some (with_cb,opt)
      | None,_ -> unknown opt
  in
  let get_collapsed_long arg =
    match try Some (String.index_from arg 2 '=') with Not_found -> None with
      | Some i ->
          Long (String.sub arg 2 (i - 2)),
          Some ((String.sub arg (i+1) (String.length arg - (i+1))))
      | None ->
          Long (String.sub arg 2 (String.length arg - 2)),
          None
  in
  let subfix str i =
    let s = String.sub str i (String.length str - i) in
    if String.length s = 0 then None else Some s
  in
  fun argc argv process ->
    let rec consume previous_callback optind =
      let arg = if optind < argc then argv.(optind) else "--" in
      let is_an_option = arg <> "" && arg.[0] = '-' && arg <> "-" in
      match previous_callback with
        | None -> (* argument not required *)
            if not is_an_option then begin
              (* plain argument *)
              process arg ;
              consume None (optind + 1)
            end else if arg.[1] <> '-' then begin
              (* short option *)
              let rec apply_short_options opt arg_opt =
                let failure without_cb remainder =
                  (* option cluster *)
                  without_cb () ;
                  apply_short_options (Short remainder.[0]) (subfix remainder 1)
                in
                apply_option opt arg_opt failure
              in
              let cb_opt =
                apply_short_options (Short arg.[1]) (subfix arg 2)
              in
              consume cb_opt (optind + 1)
            end else if arg = "--" then begin
              (* end of options *)
              for i = optind + 1 to argc - 1 do process argv.(i) done
            end else begin
              (* long option *)
              let cb_opt =
                let opt,arg_opt = get_collapsed_long arg in
                let failure without_cb remainder =
                  (* forbidden argument *)
                  needless opt
                in
                apply_option opt arg_opt failure
              in
              consume cb_opt (optind + 1)
            end
        | Some (cb,opt) -> (* argument required *)
            if is_an_option then missing opt else begin
              (* plain argument *)
              process_opt cb opt arg ;
              consume None (optind + 1)
            end
    in
    consume None 1

let parse
      ?(argc=Array.length Sys.argv) ?(argv=Sys.argv) ?(auto_help=true)
      longopts process msg =
  begin
    let short_options =
      longopts
        |> List.map (fun ((c,_,_),_) -> c)
        |> List.filter (fun c -> c<>'\000')
    in
    if List.(length short_options <> length @@ sort_uniq compare short_options)
    then raise Incorrect_specification
  end ;
  begin
    let long_options =
      longopts
        |> List.map (fun ((_,s,_),_) -> s)
        |> List.filter (fun s -> s<>"")
    in
    if List.(length long_options <> length @@ sort_uniq compare long_options)
    then raise Incorrect_specification
  end ;
  let longopts = build_help_buffer auto_help longopts msg in
  getopt_long longopts argc argv process
