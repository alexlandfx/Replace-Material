require 'sketchup.rb'
require 'extensions.rb'

module ExtensionNamespace
  extension = SketchupExtension.new('Material Replacer', 'az_material_replacer/material_replacer.rb')
  extension.description = 'Select material with eyedropper, then run command to repaint all faces using it'
  extension.version     = '1.0.0'
  extension.creator     = 'Alex Zahn'
  extension.copyright   = '2023, Alex Zahn, Creative Commons.'

  Sketchup.register_extension(extension, true)
end