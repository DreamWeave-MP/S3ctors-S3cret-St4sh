---
title: class
description: Define small plain-Lua classes with explicit single inheritance.
weight: 74
extra:
  kind: api
---

{{ api_signature(value="require 'scripts.s3.class' → ClassModule") }}

Use `class` when a small object model genuinely improves the code. It provides callable class tables, instance methods, one superclass, and type checks without introducing a framework.

```lua
local Class = require 'scripts.s3.class'

local Animal = Class.new()
function Animal:init(name) self.name = name end
function Animal:speak() return self.name .. ' makes a noise' end

local Dog = Class.new(Animal)
function Dog:speak() return self.name .. ' barks' end

local rex = Dog('Rex')
assert(Class.is(rex, Animal))
```

| Member | Behavior |
| --- | --- |
| `Class.new(base?)` | Create a class, optionally inheriting from another H3 class. |
| `Class.is(instance, class)` | Test the instance's class and its ancestors. Invalid class arguments raise. |
| `Class.class_of(instance)` | Return the direct class, or `nil` for an ordinary table. |
| `Class.super(class)` | Return the direct superclass, or `nil`. |
| `instance:is_a(class)` | Instance form of `Class.is`. |

Classes and instances are ordinary tables with metatables. Construction allocates a new instance table and calls the selected class's `init` method when present. A subclass that does not define `init` inherits its base initializer; if a subclass overrides `init`, call the parent initializer explicitly when you still want it. There are no mixins, private fields, automatic super calls, or constructor return overrides.
