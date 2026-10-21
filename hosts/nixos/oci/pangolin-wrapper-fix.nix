{ pkg }:
pkg.overrideAttrs (old: {
  preFixup = (old.preFixup or "") + ''
    substituteInPlace $out/bin/pangolin \
      --replace-fail 'cp -rd ' 'cp -rd --no-preserve=mode '
  '';
})
