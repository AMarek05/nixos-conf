{
  lib,
  buildNpmPackage,
  nodejs,
  fetchurl,
}:

let
  node = lib.getExe nodejs;
in
buildNpmPackage (finalAttrs: {
  pname = "mmx-cli";
  version = "1.0.27";

  src = fetchurl {
    url = "https://registry.npmjs.org/mmx-cli/-/mmx-cli-${finalAttrs.version}.tgz";
    hash = "sha256-g894RgorQ+D/1niD4j9KXoHC3doax4n65y6Ks4H4RQU=";
  };

  npmDepsFetcherVersion = 2;

  npmDepsHash = "sha256-ZUGV8GF2243SbmYkugRRUmcy/vpDW7BVg1SdbCbs9p8=";

  postPatch = ''
    ${node} -e "
      const fs = require('fs');
      const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
      const devOnly = ['@types/bun', 'typescript-eslint', 'typescript', 'eslint', '@eslint/js', 'bun-plugin-dts'];
      if (pkg.dependencies) {
        for (const d of devOnly) delete pkg.dependencies[d];
      }
      fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
    "

    cp ${./package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;

  meta = {
    description = "Official CLI for the MiniMax AI Platform";
    homepage = "https://github.com/MiniMax-AI/cli";
    license = lib.licenses.mit;
    mainProgram = "mmx";
    platforms = lib.platforms.unix;
  };
})
