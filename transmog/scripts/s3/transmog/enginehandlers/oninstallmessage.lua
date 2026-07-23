local MogMessage = require('scripts.s3.transmog.ui.common').messageBoxSingleton

return {
  engineHandlers = {
    onInit = function(_initData)
      MogMessage("Welcome One", "Thank you for installing Glamour Menu!", 3)
      MogMessage("Welcome Two", "Please be aware that OpenMW does not\npresently allow mods to use default keybinds!", 3)
      MogMessage("Welcome Three", "We recommend the following defaults:\n"
                                 .. "Q and E for rotate right and left respectively\n"
                                 .. "Enter/Return for select\n"
                                 .. "And L to open the menu.\n"
                                 .. "Happy Glamming!", 3)
      -- Add a check for Kartoffel's empty gear mod
    end,
  }
}
