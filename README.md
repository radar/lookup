# Lazy Man's ri (lookup)

## Installation

Add gemcutter as a source:
   
    sudo gem install gemcutter
    gem tumble
    
Then you'll be able to:

    sudo gem install lookup

## Example usage:

This has changed since the pre-1.0 versions. From 1.0 onwards you **must** specify an API that you wish to search.

 * `lookup v2.3.8 ActiveRecord::Base#new` (returns a single method from the Rails 2.3.8 API, since the method name is right)
 * `lookup v3.0.0 ActiveRecord::Base#destroy` (returns two methods from the Rails 3.0.0 API, since there's two methods with that name)
 * `lookup v2.3.8 ActiveRecord::Base#destro` (returns three methods, uses methods beginning with "destroy")
 * `lookup v2.3.8 ActiveRecord::Base#d` (tells you to be more specific, because it can't open 35 tabs at once)
 * `lookup v2.3.8 ActiveRecord::Base` (returns a single consant)
 * `lookup v2.3.8 av::Base` ("av" maps to ActionView, so returns ActionView::Base constant)
 * `lookup 1.8 Array#join` (Returns a single method from the Ruby 1.8.7 API)  
 * `lookup 1.9 Array#join` (Returns a single method from the Ruby 1.9 API)  
 
## Options

It also takes options:

* `-c or --clear` will delete the database and update the api again. This can take a minute or two.
* `-t or --text` is useful for when you don't want lookup to spam tabs into your browser willy-nilly.

## How it finds them

1. Finds the specified API and uses it to scope future calls.
2. Checks if there's constants/methods with that exact name.
3. Checks if there's constants/methods with names beginning with that name.
4. Does a "fuzzy match" splitting the name and getting anything containing those letters in that order.
5. Opens your browser if you're running a DECENT_OPERATING_SYSTEM (may add support for things other than Mac later on)
6. ???
7. Profit
