{
  name,
  self,
}: final: prev: {
  nvim-plugin = final.pkgs.vimUtils.buildVimPlugin {
    inherit name;
    src = self;
  };
}
