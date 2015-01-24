# Sidematch

This compares two files side by side printing every line with no added gaps.

# Why

Because neither diff nor comm can do this for some reason.

# Usage

sidematch file1 [file2]

# Todo

* Add tests for other params like:
    * line numbers
    * delimeters(line and column)
* Tests for stderr output
* Better default colour behaviour (maybe based on where we are outputting) 
