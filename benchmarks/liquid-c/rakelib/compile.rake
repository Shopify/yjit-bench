# frozen_string_literal: true

ext_task = Rake::ExtensionTask.new("liquid_c")

# For MacOS, generate debug information that ruby can read
dsymutil = RbConfig::CONFIG["dsymutil"]
unless dsymutil.to_s.empty?
  ext_lib_path = "lib/#{ext_task.binary}"
  dsym_path = "#{ext_lib_path}.dSYM"

  file dsym_path => [ext_lib_path] do
    sh dsymutil, ext_lib_path
  end
  Rake::Task["compile"].enhance([dsym_path])
end
