# TODO items for MethUtil Ruby gem

* Adapt to keyword arguments introduced in Ruby 2
* Options for opts2attributes (use the attribute writer if there is
  one).  If there isn't:
  a. ignore it
  a. store it into the corresponding instance variable
     1. regardless of any existing value
     1. only if the variable doesn't exist, else do nothing
     1. raise an exception if the variable exists
  a. raise an exception

  
<!-- Local Variables: -->
<!-- mode: markdown -->
<!-- page-delimiter: "^[[:space:]]*<!-- \\(--\\|\\+\\+\\)" -->
<!-- eval: (if (intern-soft "fci-mode") (fci-mode 1)) -->
<!-- eval: (auto-fill-mode 1) -->
<!-- End: -->
