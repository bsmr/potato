#!/usr/bin/tclsh
# Attempt to merge a Potato translation template with an older translation file
set VERSION "1.3.1"

proc main {} {

  wm title . "Potato Translation File Merger, Version $::VERSION"

  pack [set frame [::ttk::frame .template]] -expand 1 -fill x -side top -pady 8
  pack [::ttk::label $frame.l -text "Template:" -justify left -width 14] -side left -padx 4
  pack [::ttk::entry $frame.e -textvariable files(template) -width 50] -expand 1 -fill x -side left -padx 4
  pack [::ttk::button $frame.b -command [list setFile template 1] -text "..." -width 4] -side left -padx 4

  pack [set frame [::ttk::frame .trans]] -expand 1 -fill x -side top -pady 8
  pack [::ttk::label $frame.l -text "Translation:" -justify left -width 14] -side left -padx 4
  pack [::ttk::entry $frame.e -textvariable files(translation) -width 50] -expand 1 -fill x -side left -padx 4
  pack [::ttk::button $frame.b -command [list setFile translation 1] -text "..." -width 4] -side left -padx 4

  pack [set frame [::ttk::frame .output]] -expand 1 -fill x -side top -pady 8
  pack [::ttk::label $frame.l -text "Ouput To:" -justify left -width 14] -side left -padx 4
  pack [::ttk::entry $frame.e -textvariable files(output) -width 50] -expand 1 -fill x -side left -padx 4
  pack [::ttk::button $frame.b -command [list setFile output 0] -text "..." -width 4] -side left -padx 4

  pack [set frame [::ttk::frame .btns]] -side top -pady 15 -fill x
  pack [::ttk::button $frame.go -text "Go!" -width 8 -command mergeFiles]

  if { [file exists ./potato-template.txt] } {
       set ::files(template) [file nativename [file normalize "./potato-template.txt"]]
     }
}

proc mergeFiles {} {
  global files;
  global fid;
  global templateStrings;
  global translationStrings;

  # Meh. ;)

  set fid(template) [open $files(template) r]
  set fid(translation) [open $files(translation) r]
  fconfigure $fid(translation) -encoding utf-8

  unset -nocomplain templateStrings;
  unset -nocomplain translationStrings;

  # OK, first we need to read in all of the template messages.
  # Then we need to read in all the translation file ones.
  # Then, we'll output:
  #  * Messages in the Template which aren't in our translation (do these first!)
  #  * Messages in the Translation that aren't in the template (obsolete and could be deleted?)
  #  * Correctly translated messages
  if { ![loadFile template] } {
       tk_messageBox -message "Template file $files(template) doesn't seem to be a valid translation file!"
       finishMergeFiles
       return;
     }
  if { ![loadFile translation] } {
       tk_messageBox -message "Translation file $files(translation) doesn't seem to be a valid translation file!"
       finishMergeFiles
       return;
     }

  set done [list]
  set fid(output) [open $files(output) w]
  fconfigure $fid(output) -encoding utf-8 -translation lf

  puts $fid(output) "\n# Untranslated strings:"
  set untranslated 0
  foreach x [lsort -dictionary [array names templateStrings]] {
    if { ![info exists translationStrings($x)] || $translationStrings($x) eq "-" } {
         puts $fid(output) "\n$x"
         puts $fid(output) $templateStrings($x)
         lappend done $x
         incr untranslated
       }
  }

  puts $fid(output) "\n# Obsolete strings:"
  set obsolete 0
  foreach x [lsort -dictionary [array names translationStrings]] {
    if { ![info exists templateStrings($x)] && $translationStrings($x) ne "-" } {
         puts $fid(output) "\n$x"
         puts $fid(output) $translationStrings($x)
         lappend done $x
         incr obsolete
       }
  }

  puts $fid(output) "\n# Existing translations:"
  set repeats 0
  foreach x [lsort -dictionary [array names translationStrings]] {
    if { $x ni $done && $translationStrings($x) ne "-" } {
         puts $fid(output) "\n$x"
         puts $fid(output) $translationStrings($x)
         incr repeats
       }
  }

  # Done!
  finishMergeFiles
  tk_messageBox -message "Done! There were $untranslated untranslated strings, $obsolete obsolete strings, and $repeats strings already translated."
  return;

};# mergeFiles

proc loadFile {type} {
  global fid;
  global ${type}Strings;

  if { ![getLine $fid($type) line] } {
       return 0;
     }

  set count 0;
  set i 0
  set beyond 500000
  while { $beyond } {
    incr beyond -1
    if { [string trim $line] eq "" || [string index $line 0] eq "#" } {
         if { [getLine $fid($type) line] } {
              continue;
            } else {
              break;
            }
       }
    if { $i == 0 } {
         set msg $line
         set i 1
       } else {
         set [set type]Strings($msg) $line
         set i 0
         incr count
       }
    if { ![getLine $fid($type) line] } {
         break;
       }
  }
  return $count;

};# loadFile

proc getLine {fid var} {

  upvar 1 $var _var
  if { [catch {gets $fid _var} count] || $count < 0 } {
       return 0;
     }

  return 1;

};# getLine

proc finishMergeFiles {} {
  global fid;

  foreach x [array names fid] {
    close $fid($x)
    unset fid($x)
  }

};# finishMergeFiles

proc setFile {type existing} {
  global files

  if { $type eq "template" } {
       set initial [list -initialdir .]
     } else {
       set initial [list -initialdir ../lib/i18n]
     }
  if { [info exists files($type)] && $files($type) ne "" } {
       set initial [list -initialfile $files($type)]
     }

  if { $existing } {
       set file [tk_getOpenFile {*}$initial -title "Choose $type file"]
     } else {
       set file [tk_getSaveFile {*}$initial -title "Choose $type file" -defaultextension .ptf]
     }
  if { $file eq "" } {
       return;
     }
  set files($type) [file nativename [file normalize $file]]
};# setFile
package require Tk
main
bind . <F2> {console show}

cd [file dirname [info script]]
