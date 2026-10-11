# Complete package set, composed from the module bundles in brew/ so that
# `brew bundle --file=Brewfile` keeps working. Package membership lives only in
# brew/*.Brewfile.
Dir.glob(File.join(__dir__, "brew", "**", "*.Brewfile")).sort.each do |bundle|
  instance_eval(File.read(bundle), bundle)
end
