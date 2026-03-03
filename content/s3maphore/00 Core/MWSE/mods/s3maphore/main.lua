-- mwse.memory.writeNoOperation{address = 0x4BB666, length = 18}
package.path = package.path .. ";.\\Data Files\\?.lua;"

require("s3maphore.meta")
require("s3maphore.mcm")

--- This path was changed in current builds, but also
--- The util module returns a local variable which should be bound to a variable in the scope in which it's require'd
--- There is no way this works like you're expecting it to
require("scripts.s3.music.util")
