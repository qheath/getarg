DEPRECATED
==========

features are uncluded in [cmdliner](https://github.com/dbuenzli/cmdliner)

Command-line option parser
==========================

This library offers an alternative to the standard OCaml Arg module
with a support for short and long options (à la getopt).

It is similar to Getopt and Getopts, with a few key differences:
  - long options (with an expanded form that can take a mandatory
    argument)
  - no expanded form for short options with optional arguments
  - clusters of short options (mixing with and without arguments)
