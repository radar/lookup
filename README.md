# Lazy Man's ri (lookup)

## Example usage:

 * `lookup ActiveRecord::Base#new` (returns a single method, since the method name is right)
 * `lookup ActiveRecord::Base#destroy` (returns two methods, since there's two methods with that name)
 * `lookup ActiveRecord::Base#destro` (returns three methods, uses methods beginning with "destroy")
 * `lookup ActiveRecord::Base#d` (tells you to be more specific, because it can't open 35 tabs at once)
 * `lookup ActiveRecord::Base` (returns a single consant)
 * `lookup Acv::Base` (returns six constants, because it does a fuzzy match)
 
 

## How it finds them
1. Checks if there's constants/methods with that exact name.
2. Checks if there's constants/methods with names beginning with that name.
3. Does a "fuzzy match" splitting the name and getting anything containing those letters in that order.
4. Opens your browser if you're running a DECENT_OPERATING_SYSTEM (may add support for things other than Mac later on)
5. ???
6. Profit
