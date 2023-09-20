require 'sketchup.rb'
require 'extensions.rb'

module AlexZahn
  module ReplaceMaterial
    unless file_loaded?(__FILE__)

      extension = SketchupExtension.new('Replace Material', 'az_replace_material/replace_material.rb')
      extension.description = 'Replace all instances of a selected material with any other material in your library.'
      extension.version     = '1.0.0'
      extension.creator     = 'Alex Zahn'
      extension.copyright   = '2023, Alex Zahn, Creative Commons.'

      Sketchup.register_extension(extension, true)

      file_loaded(__FILE__)

    end
  end # module ReplaceMaterial
end # module AlexZahn