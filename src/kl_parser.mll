{
open Lexing
open Kl_parsing
open Kl_errors

exception Eof
}

let esc = '`'
let white = [' ' '\t']+
let newline = ['\n' '\r']+
let separator = ['.' ';' ':' ',']
let digit = ['0'-'9']
let int = '-'? digit+
let alpha = ['a'-'z' 'A'-'Z']
let special = ['!'-'/' ':'-'@' '['-'`' '{'-'~']
let used = ['`' '.' ';' ':' ',']
let other = special # used
let word = (alpha | digit | other)+
let comment_start = "/*"
let comment_end = "*/"

rule block = parse
  | white         { block lexbuf }
  | newline       { next_line lexbuf; block lexbuf }
  | comment_start { comment [] lexbuf }
  | _             {
    let c = Lexing.lexeme lexbuf in
    raise (SyntaxError (lexbuf.lex_curr_p, "unexpected character '"^c^"', expected comment block"))
  }
  | eof           { raise Eof }

and comment l = parse
  | white       { comment l lexbuf }
  | newline     { next_line lexbuf; comment l lexbuf }
  | comment_end { defun (List.rev l) lexbuf }
  | esc         { escape l "" lexbuf }
  | separator   { let l = Sep::l in comment l lexbuf }
  | int         { let l = (Int (lexbuf.lex_curr_p, int_of_string (Lexing.lexeme lexbuf)))::l in comment l lexbuf }
  | word        { let l = (Word (lexbuf.lex_curr_p, Lexing.lexeme lexbuf))::l in comment l lexbuf }
  | _           {
    let c = Lexing.lexeme lexbuf in
    raise (SyntaxError (lexbuf.lex_curr_p, "invalid token '"^c^"' found while parsing a comment"))
  }
  | eof         { raise (SyntaxError (lexbuf.lex_curr_p, "unexpected end of file while parsing a comment")) }

and escape l s = parse
  | newline     { next_line lexbuf; comment l lexbuf }
  | esc         { let l = (Word (lexbuf.lex_curr_p, s))::l in comment l lexbuf }
  | _           { let c = Lexing.lexeme lexbuf in escape l (s ^ c) lexbuf }
  | eof         { raise (SyntaxError (lexbuf.lex_curr_p, "unexpected end of file while parsing a comment")) }

and defun l = parse
  | white         { defun l lexbuf }
  | newline       { next_line lexbuf; defun l lexbuf }
  | comment_start { comment [] lexbuf }
  | "function " (word as fname) (";")* { Spec (true, fname, l) } (* semicolons are optional *)
  | _             {
    let c = Lexing.lexeme lexbuf in
    raise (SyntaxError (lexbuf.lex_curr_p, "invalid token '"^c^"' found while parsing a function definition"))
  }
  | eof           { raise Eof }
