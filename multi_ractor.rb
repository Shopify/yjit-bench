# Create a single ractor to force Ruby to use the multi_ractor_p paths.
Warning[:experimental] = false
Ractor.new { :noop }
