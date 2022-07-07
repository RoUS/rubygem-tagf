#  Exceptable - Framework for Application Exceptions

## Usage

```ruby

require('exceptable')
module Foo
  include Exceptable
  class MyError < ExceptionBase
    MessageFormat = [
                     'message when invoked with no arguments',
                     'message when 1 argument: %s',
                     'message when 2 or more arguments: %s/%s',
                    ]
  end
end

raise Foo::MyError
=> Foo::MyError: message when invoked with no arguments

raise Foo::MyError.new
=> Foo::MyError: message when invoked with no arguments

raise Foo::MyError.new('[this here is an argument]')
=> Foo::MyError: message when arguments: [this here is an argument]

raise Foo::MyError.new('[this here is an argument]')
=> Foo::MyError: message when arguments: [this here is an argument]

raise Foo::MyError.new('arg1', 'arg2')
=> Foo::MyError: message when arguments: arg1/arg2

raise Foo::MyError.new('arg1', 'arg2', 'arg3', 'arg4')
=> Foo::MyError: message when arguments: arg1/arg2
```

## Adding Your Own Exceptions

Description goes here.

## Contributing to exceptable

* Check out the latest master to make sure the feature hasn't been
  implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't
  requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it
  in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If
  you want to have your own version, or is otherwise necessary, that
  is fine, but please isolate to its own commit so I can cherry-pick
  around it.

## Copyright

`Exceptable` is copyright (c) 2022 by Ken Coar, and is made available
under the terms of the Apache Licence 2.0. See the
{file.LICENCE.html LICENCE file} for further details.


<!-- Local Variables: -->
<!-- mode: markdown -->
<!-- eval: (if (intern-soft "fci-mode") (fci-mode 1)) -->
<!-- End: -->
