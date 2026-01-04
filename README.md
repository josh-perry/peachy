# Peachy
A parser/renderer for Aseprite animations in LÖVE.

# How to use
Draw some animations in Aseprite and export the file as a spritesheet:
![Aseprite export](docs/img/aseprite_export.png)

Make sure that you export JSON data with frame tags and that you have at least one tag defined. Even if there is a single animation in the file, you **still** need to set up frame tags.

```lua
-- Load an aseprite animation file called spinner.json, with the image
-- spinner.png & start with the animation tag "Spin"
spinner = peachy.new("spinner.json", love.graphics.newImage("spinner.png"), "Spin")

function love.draw()
  -- Draw at 50,50
  spinner:draw(50, 50)
end

function love.update(dt)
  spinner:update(dt)
end
```

If you don't specify an image to load in new by passing nil or false as the second argument, then peachy will attempt to load the image specified in the data file. This can cause problems: see [limitations below](#limitations).

# Examples
See main.lua for further examples:

![Peachy example](docs/img/peachy_example.gif)

# API Reference
## Constructor
### peachy.new(data: string|table, image?: Image, initialTag?: string) -> peachy
Creates a new animation object.

## Functions
### animation:play()
Resumes the animation.

### animation:pause()
Pauses the animation.

### animation:stop(onLast?: boolean)
Stops the animation and returns to first (or last) frame.

### animation:togglePlay()
Toggles between playing and paused.

### animation:setTag(tag: string)
Switches to a different animation tag.

### animation:setFrame(frame: integer)
Jumps to a specific frame index (1-based).

### animation:getTag() -> string?
Returns the current tag name.

### animation:getFrame() -> integer?
Returns the current frame index.

### animation:draw(x: number, y: number, rot?: number, sx?: number, sy?: number, ox?: number, oy?: number)
Draws the current frame.

### animation:update(dt: number)
Updates the animation timer.

### animation:getWidth() -> number
Returns the width of the current frame.

### animation:getHeight() -> number
Returns the height of the current frame.

### animation:getDimensions() -> number, number
Returns both width and height of the current frame.

### animation:onLoop(callback: function, ...)
Sets a callback function to be called when the animation loops.

## Properties

### animation.paused: boolean
Boolean indicating if the animation is paused.

### animation.frameIndex: integer
Current frame index.

### animation.tagName: string
Current animation tag name.

# Limitations
* By default Aseprite will export a **non-relative** path as the image file. This is problematic because LÖVE will refuse to load it and it's non-portable. There's a workaround listed [here](https://github.com/aseprite/aseprite/issues/1606). Either specify the image yourself in `peachy.new`, edit the JSON manually or use the CLI.
* Exported sprite sheets **must** be exported as an array, **not** as a hash table.

![Export as array](docs/img/export_type.png)
