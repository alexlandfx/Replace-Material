#-----------------------------------------------------------------------------------
# Material Replacement script for SketchUp
# Usage:
#   First, select a material BY USING THE NATIVE EYEDROPPER TOOL ON A PAINTED FACE IN YOUR MODEL. 
#   (Selecting a material by clicking on it in the "Colors in Model" list will NOT work.)
#   Then, run the "Replace Current Material" command from the Extensions dropdown.
#   In the dropdown box that pops up, select any replacement material from your library.
#-----------------------------------------------------------------------------------

module AlexZahn
  module ReplaceMaterial
    
    # Materials observer to store the currently-selected material 
    # (The @active_material variable updates when the user selects a material with the eyedropper)
    class MRMatObserver < Sketchup::MaterialsObserver
      def initialize
        @active_material = nil
      end
      
      def active_material
        return @active_material
      end        
        
      def clearActiveMaterial
        @active_material = nil 
      end
      
      def onMaterialSetCurrent(materials, material)
        puts "Setting active_material to #{material}"
        @active_material = material
      end
    end
    
    # Instantiate and attach our materials observer class
    @matObserver = MRMatObserver.new
    Sketchup.active_model.materials.add_observer(@matObserver)
    
    # Method for finding entities painted with a particular material, and repainting with the replacement material
    # Recurse into nested components/groups
    def self.repaintEntities(entities_to_scan, target_material, replacement_material)
      entities_to_scan.each do |entity|
        if entity.is_a?(Sketchup::Face) && entity.material == target_material
          entity.material = replacement_material
        elsif entity.is_a?(Sketchup::ComponentInstance)
          if entity.material == target_material
            entity.material = replacement_material
          end
          repaintEntities(entity.definition.entities, target_material, replacement_material)
        elsif entity.is_a?(Sketchup::Group)
          if entity.material == target_material
            entity.material = replacement_material
          end
          repaintEntities(entity.entities, target_material, replacement_material)
        end
      end
    end # repaintEntities
    
    # Replacement method called by command in Extensions menu
    def self.replaceCurrentMaterial()
      # Do not proceed if the active material is SketchUp default material (nil),
      # nor if the active material has been deleted (can happen after a user Undo's a material replacement)
      if !@matObserver.active_material || @matObserver.active_material.deleted?
        UI.messagebox("You must first select a material\nwith the eyedropper tool.")
        return
      end
    
      # Get the path to the user's Materials folder, and store the length of the path string
      materials_folder_path = Sketchup.find_support_file('Materials')
      materials_folder_path_numChars = materials_folder_path.length
      
      # Get an array of all SKM file paths in the Materials folder and subfolders
      all_materials = Dir.glob("#{materials_folder_path}/**/*.skm").reject{ |f| File.directory?(f) }
      
      # Remove the materials folder path, the subsequent '/', and the '.skm' extension from each string in the array
      # This gives us strings with format "Subfolder Name/Material Name"
      all_materials.map! { |material| material[(materials_folder_path_numChars+1)..-5] }
      
      # Concatenate all strings of the array into one pipe-separated string (UI.inputbox dropdown format)
      all_materials_string = all_materials.join('|')
      
      # Show UI input box with dropdown to select replacement material. Exit function if user clicks "Cancel".
      replacement_material_name = UI.inputbox(['Replacement:'], [all_materials.first], [all_materials_string], "Replace #{@matObserver.active_material.name}")
      if replacement_material_name
        replacement_material_name = replacement_material_name[0]
      else
        return
      end
      
      # START OPERATION (this makes the following actions a single undo-able operation)
      Sketchup.active_model.start_operation('Replace Material', true, false, false)
      
      # Load replacement material (into "Colors in Model")
      Sketchup.active_model.materials.load("#{materials_folder_path}/#{replacement_material_name}.skm")
      
      # Remove the subfolder name from replacement_material_name
      # This gives us a string with format "Material Name"
      replacement_material_name = replacement_material_name.slice(replacement_material_name.index('/')..-1)[1..-1]
      
      # Get the Material object in "Colors in Model" with replacement_material_name
      replacement_material = Sketchup.active_model.materials[replacement_material_name]
      
      # Replace current material with the selected replacement material on all relevant faces, groups, and components
      repaintEntities(Sketchup.active_model.entities, @matObserver.active_material, replacement_material)
      
      # Remove the old material from the model
      Sketchup.active_model.materials.remove(@matObserver.active_material)
      
      # COMMIT OPERATION
      Sketchup.active_model.commit_operation
      
    end # replaceCurrentMaterial
    
    unless file_loaded?(__FILE__)
      command = UI::Command.new("Replace Selected Material") {self.replaceCurrentMaterial}
      command.status_bar_text = "Choose a replacement from your Material Library for the selected material."
      UI.menu("Plugins").add_item(command)
      
      file_loaded(__FILE__)
    end
    
  end # module ReplaceMaterial 
end # module AlexZahn